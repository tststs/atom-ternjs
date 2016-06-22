'use babel';

let ConfigView;
let _ = require('underscore-plus');

export default class Config {

  constructor(manager) {

    this.manager = manager;

    this.config = undefined;
    this.projectConfig = undefined;
    this.editors = [];
  }

  getContent(filePath, projectRoot) {

    let content = this.manager.helper.getFileContent(filePath, projectRoot);

    if (!content) {

      return;
    }

    try {

      content = JSON.parse(content);

    } catch (e) {

      atom.notifications.addInfo('Error parsing .tern-project. Please check if it is a valid JSON file.', {

        dismissable: true
      });
      return;
    }

    return content;
  }

  prepareLibs(projectConfig, configStub) {

    let libs = {};

    if (!projectConfig.libs) {

      projectConfig.libs = {};

    } else {

      let libsAsObject = {};
      for (let lib of projectConfig.libs) {

        libsAsObject[lib] = true;
      }

      projectConfig.libs = libsAsObject;
    }

    for (let lib of Object.keys(configStub.libs)) {

      if (!projectConfig.libs[lib]) {

        libs[lib] = false;

      } else {

        libs[lib] = true;
      }
    }

    for (let lib of Object.keys(projectConfig.libs)) {

      if (lib === 'ecma5' || lib === 'ecma6') {

        atom.notifications.addInfo('You are using a outdated .tern-project file. Please remove libs ecma5, ecma6 manually and restart the Server via Packages -> Atom Ternjs -> Restart server. Then configure the project via Packages -> Atom Ternjs -> Configure project.', {

          dismissable: true
        });
      }

      if (!libs[lib]) {

        libs[lib] = true;
      }
    }

    projectConfig.libs = libs;

    return projectConfig;
  }

  prepareEcma(projectConfig, configStub) {

    let ecmaVersions = {};

    for (let lib of Object.keys(configStub.ecmaVersions)) {

      ecmaVersions[lib] = configStub.ecmaVersions[lib];
    }

    projectConfig.ecmaVersions = ecmaVersions;

    if (projectConfig.ecmaVersion) {

      for (let lib of Object.keys(projectConfig.ecmaVersions)) {

        if (lib === 'ecmaVersion' + projectConfig.ecmaVersion) {

          projectConfig.ecmaVersions[lib] = true;

        } else {

          projectConfig.ecmaVersions[lib] = false;
        }
      }
    }

    return projectConfig;
  }

  preparePlugins(projectConfig, configStub) {

    projectConfig.plugins = projectConfig.plugins || {};

    return projectConfig;
  }

  registerEvents() {

    let close = this.configView.getClose();
    let cancel = this.configView.getCancel();

    close.addEventListener('click', (e) => {

      this.updateConfig();
      this.hide();
      this.manager.helper.focusEditor();
    });

    cancel.addEventListener('click', (e) => {

      this.destroyEditors();
      this.hide();
      this.manager.helper.focusEditor();
    });
  }

  mergeConfigObjects(obj1, obj2) {

    return _.deepExtend({}, obj1, obj2);
  }

  hide() {

    if (!this.configPanel) {

      return;
    }

    this.configPanel.hide();
  }

  clear() {

    this.hide();
    this.destroyEditors();
    this.config = undefined;
    this.projectConfig = undefined;

    if (!this.configView) {

      return;
    }

    this.configView.removeContent();
  }

  gatherData() {

    const configDefault = this.getContent('../config/tern-config.json', false);
    const pluginsTern = this.getContent('../config/tern-plugins.json', false);

    if (!configDefault) {

      return;
    }

    this.projectConfig = this.getContent('/.tern-project', true);
    this.config = this.projectConfig || {};

    if (this.projectConfig) {

      this.config = this.prepareEcma(this.config, configDefault);
      this.config = this.prepareLibs(this.config, configDefault);
      this.config = this.preparePlugins(this.config, pluginsTern);

      this.config = this.mergeConfigObjects(configDefault, this.config);

    } else {

      this.config = configDefault;
    }

    return true;
  }

  removeEditor(editor) {

    if (!editor) {

      return;
    }

    let idx = this.editors.indexOf(editor);

    if (idx === -1) {

      return;
    }

    this.editors.splice(idx, 1);
  }


  destroyEditors() {

    for (let editor of this.editors) {

      let buffer = editor.getModel().getBuffer();
      buffer.destroy();
    }

    this.editors = [];
  }

  updateConfig() {

    this.config.loadEagerly = [];
    this.config.dontLoad = [];

    for (let editor of this.editors) {

      let buffer = editor.getModel().getBuffer();
      let text = buffer.getText().trim();

      if (text === '') {

        continue;
      }

      this.config[editor.__ternjs_section].push(text);
    }

    this.destroyEditors();

    let newConfig = this.buildNewConfig();
    let newConfigJSON = JSON.stringify(newConfig, null, 2);

    this.manager.helper.updateTernFile(newConfigJSON, true);
  }

  buildNewConfig() {

    let newConfig = {};

    for (let key of Object.keys(this.config.ecmaVersions)) {

      if (this.config.ecmaVersions[key]) {

        newConfig.ecmaVersion = Number(key[key.length - 1]);
        break;
      }
    }

    if (!_.isEmpty(this.config.libs)) {

      newConfig.libs = [];

      for (let key of Object.keys(this.config.libs)) {

        if (this.config.libs[key]) {

          newConfig.libs.push(key);
        }
      }
    }

    if (this.config.loadEagerly.length !== 0) {

      newConfig.loadEagerly = this.config.loadEagerly;
    }

    if (this.config.dontLoad.length !== 0) {

      newConfig.dontLoad = this.config.dontLoad;
    }

    if (this.projectConfig && !_.isEmpty(this.projectConfig.plugins)) {

      newConfig.plugins = this.projectConfig.plugins;
    }

    return newConfig;
  }

  initConfigView() {

    if (!ConfigView) {

      ConfigView = require('./atom-ternjs-config-view');
    }


    this.configView = new ConfigView();
    this.configView.initialize(this);

    this.configPanel = atom.workspace.addRightPanel({

      item: this.configView,
      priority: 0
    });
    this.configPanel.hide();

    this.registerEvents();
  }

  show() {

    if (!this.configView) {

      this.initConfigView();
    }

    this.clear();

    atom.views.getView(this.configPanel).classList.add('atom-ternjs-config-panel');

    if (!this.gatherData()) {

      atom.notifications.addInfo('There is no active project. Please re-open or focus at least one JavaScript file of the project to configure.', {

        dismissable: true
      });
      return;
    }

    this.configView.buildOptionsMarkup(this.manager);
    this.configPanel.show();
  }

  destroy() {

    if (this.configView) {

      this.configView.destroy();
    }
    this.configView = undefined;

    if (this.configPanel) {

      this.configPanel.destroy();
    }
    this.configPanel = undefined;
  }
}
