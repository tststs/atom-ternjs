'use babel';

import manager from '../atom-ternjs-manager';

import {
  getFileContent,
  getPackagePath,
  updateTernFile
} from '../atom-ternjs-helper';

import {
  deepExtend,
  clone,
  isEmpty
} from 'underscore-plus';

const title = 'atom-ternjs project config';

export default class ConfigModel {

  constructor() {

    this.config = undefined;
    this.projectConfig = undefined;
    this.editors = [];
  }

  getURI() {

    return this.uRI;
  }

  getProjectDir() {

    return this.projectDir;
  }

  setProjectDir(dir) {

    this.projectDir = dir;
  }

  setURI(uRI) {

    this.uRI = uRI;
  }

  getTitle() {

    return title;
  }

  getContent(filePath, projectRoot) {

    const root = projectRoot ? manager.server && manager.server.projectDir : '';
    let content = getFileContent(filePath, root);

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

  prepareLibs(configDefault) {

    let libs = {};

    for (const index in configDefault.libs) {

      if (this.projectConfig.libs && this.projectConfig.libs.indexOf(configDefault.libs[index]) > -1) {

        libs[configDefault.libs[index]] = {

          _active: true
        };

      } else {

        libs[configDefault.libs[index]] = {

          _active: false
        };
      }
    }

    this.config.libs = libs;
  }

  prepareEcma(configDefault) {

    let ecmaVersions = {};

    for (let lib of Object.keys(configDefault.ecmaVersions)) {

      ecmaVersions[lib] = configDefault.ecmaVersions[lib];
    }

    this.config.ecmaVersions = ecmaVersions;

    if (this.config.ecmaVersion) {

      for (let lib of Object.keys(this.config.ecmaVersions)) {

        if (lib === 'ecmaVersion' + this.config.ecmaVersion) {

          this.config.ecmaVersions[lib] = true;

        } else {

          this.config.ecmaVersions[lib] = false;
        }
      }
    }
  }

  preparePlugins(availablePlugins) {

    if (!this.config.plugins) {

      this.config.plugins = {};
    }

    // check if there are unknown plugins in .tern-config
    for (const plugin of Object.keys(this.config.plugins)) {

      if (!availablePlugins[plugin]) {

        availablePlugins[plugin] = plugin;
      }
    }

    for (const plugin of Object.keys(availablePlugins)) {

      if (this.config.plugins[plugin]) {

        this.config.plugins[plugin] = this.mergeConfigObjects(availablePlugins[plugin], this.config.plugins[plugin]);
        this.config.plugins[plugin]._active = true;

      } else {

        this.config.plugins[plugin] = availablePlugins[plugin];
        this.config.plugins[plugin]._active = false;
      }
    }
  }

  mergeConfigObjects(obj1, obj2) {

    return deepExtend({}, obj1, obj2);
  }

  gatherData() {

    const packagePath = getPackagePath();
    const configDefault = this.getContent(`${packagePath}/config/tern-config.json`, false);
    const pluginsTern = this.getContent(`${packagePath}/config/tern-plugins.json`, false);

    if (!configDefault) {

      console.error('Could not load: tern-config.json');
      return;
    }

    this.projectConfig = this.getContent('/.tern-project', true);
    this.config = this.projectConfig || {};

    if (!this.projectConfig) {

      this.projectConfig = {};
      this.config = clone(configDefault);
    }

    this.prepareEcma(configDefault);
    this.prepareLibs(configDefault);
    this.preparePlugins(pluginsTern);

    if (!this.config.loadEagerly) {

      this.config.loadEagerly = [];
    }

    if (!this.config.dontLoad) {

      this.config.dontLoad = [];
    }

    return true;
  }

  removeEditor(editor) {

    if (!editor) {

      return;
    }

    const editors = this.editors.slice();

    editors.forEach((_editor, i) => {

      if (_editor === editor) {

        const buffer = editor.getModel().getBuffer();
        buffer.destroy();

        this.editors.splice(i, 1);
      }
    });
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

    let newConfig = this.buildNewConfig();
    let newConfigJSON = JSON.stringify(newConfig, null, 2);

    updateTernFile(newConfigJSON);
  }

  buildNewConfig() {

    let newConfig = {};

    for (let key of Object.keys(this.config.ecmaVersions)) {

      if (this.config.ecmaVersions[key]) {

        newConfig.ecmaVersion = Number(key[key.length - 1]);
        break;
      }
    }

    if (!isEmpty(this.config.libs)) {

      newConfig.libs = [];

      for (let key of Object.keys(this.config.libs)) {

        if (this.config.libs[key]._active) {

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

    if (!isEmpty(this.config.plugins)) {

      newConfig.plugins = {};

      for (const key of Object.keys(this.config.plugins)) {

        if (this.config.plugins[key]._active) {

          delete this.config.plugins[key]._active;
          newConfig.plugins[key] = this.config.plugins[key];
        }
      }
    }

    return newConfig;
  }

  destroy() {

    for (const editor of this.editors) {

      const buffer = editor.getModel().getBuffer();
      buffer.destroy();
    }

    this.editors = null;
  }
}
