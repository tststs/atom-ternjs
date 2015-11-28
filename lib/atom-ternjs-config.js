"use babel";

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

    let error = false;
    let content = this.manager.helper.getFileContent(filePath, projectRoot);

    if (!content) {

      return;
    }

    try {

      content = JSON.parse(content);

    } catch(e) {

      atom.notifications.addInfo('Error parsing .tern-project. Please check if it is a valid JSON file.', {

        dismissable: true
      });
      return;
    }

    return content;
  }

  prepareLibs(localConfig, configStub) {

    let libs = {};

    if (!localConfig.libs) {

      localConfig.libs = {};

    } else {

      let libsAsObject = {};
      for (let lib of localConfig.libs) {

        libsAsObject[lib] = true;
      }

      localConfig.libs = libsAsObject;
    }

    for (let lib of Object.keys(configStub.libs)) {

      if (!localConfig.libs[lib]) {

        libs[lib] = false;

      } else {

        libs[lib] = true;
      }
    }

    for (let lib of Object.keys(localConfig.libs)) {

      if (lib === 'ecma5' || lib === 'ecma6') {

        atom.notifications.addInfo('You are using a outdated .tern-project file. Please remove libs ecma5, ecma6 manually and restart the Server via Packages -> Atom Ternjs -> Restart server. Then configure the project via Packages -> Atom Ternjs -> Configure project.', {

          dismissable: true
        });
      }

      if (!libs[lib]) {

        libs[lib] = true;
      }
    }

    localConfig.libs = libs;

    return localConfig;
  }

  prepareEcma(localConfig, configStub) {

    let ecmaVersions = {};

    for (let lib of Object.keys(configStub.ecmaVersions)) {

      ecmaVersions[lib] = configStub.ecmaVersions[lib];
    }

    localConfig.ecmaVersions = ecmaVersions;

    if (localConfig.ecmaVersion) {

      for (let lib of Object.keys(localConfig.ecmaVersions)) {

        if (lib === 'ecmaVersion' + localConfig.ecmaVersion) {

          localConfig.ecmaVersions[lib] = true;

        } else {

          localConfig.ecmaVersions[lib] = false;
        }
      }
    }

    return localConfig;
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

    let configStub = this.getContent('../tern-config.json', false);

    if (!configStub) {

      return;
    }

    this.projectConfig = this.getContent('/.tern-project', true);

    this.config = {};
    this.config = this.mergeConfigObjects(this.projectConfig, this.config);

    if (this.projectConfig) {

      this.config = this.prepareEcma(this.config, configStub);
      this.config = this.prepareLibs(this.config, configStub);

      for (let plugin in this.config.plugins) {

        if (this.config.plugins[plugin]) {

          this.config.plugins[plugin].active = true;
        }
      }

      this.config = this.mergeConfigObjects(configStub, this.config);

    } else {

      this.config = configStub;
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
