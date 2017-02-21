'use babel';

import manager from '../atom-ternjs-manager';

import {
  updateTernFile,
  readFile
} from '../atom-ternjs-helper';

import {
  deepClone
} from 'underscore-plus';

import {
  defaultProjectConfig,
  availablePlugins
} from '../../config/tern-config';

const title = 'atom-ternjs project config';

export default class ConfigModel {

  constructor() {

    /**
     * project configuration (.tern-project)
     * @type {Object}
     */
    this.projectConfig = {};
    /**
     * temporary project configuration
     * @type {Object}
     */
    this.config = {};
    /**
     * collection of all editors in config view
     * @type {Array}
     */
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

  addLib(lib) {

    if (!this.config.libs.includes(lib)) {

      this.config.libs.push(lib);
    }
  }

  removeLib(lib) {

    const libs = this.config.libs.slice();

    libs.forEach((_lib, i) => {

      if (_lib === lib) {

        this.config.libs.splice(i, 1);
      }
    });
  }

  getEcmaVersion() {

    return this.config.ecmaVersions;
  }

  setEcmaVersion(value) {

    this.config.ecmaVersion = value;
  }

  addPlugin(key) {

    if (!this.config.plugins[key]) {

      // if there was a previous config for this pluging
      if (this.projectConfig.plugins && this.projectConfig.plugins[key]) {

        this.config.plugins[key] = this.projectConfig.plugins[key];

        return;
      }

      this.config.plugins[key] = availablePlugins[key];
    }
  }

  removePlugin(key) {

    this.config.plugins[key] && delete this.config.plugins[key];
  }

  gatherData() {

    const projectDir = manager.server && manager.server.projectDir;

    if (!projectDir) {

      atom.notifications.addError('No Project found.');

      return false;
    }

    const projectConfig = readFile(`${projectDir}/.tern-project`);

    if (!projectConfig) {

      this.config = deepClone(defaultProjectConfig);

      return true;
    }

    try {

      this.projectConfig = JSON.parse(projectConfig);

    } catch (error) {

      atom.notifications.addError(error);

      return false;
    }

    this.config = deepClone(this.projectConfig);

    if (!this.config.libs) {

      this.config.libs = [];
    }

    if (!this.config.plugins) {

      this.config.plugins = {};
    }

    return true;
  }

  removeEditor(editor) {

    if (!editor) {

      return;
    }

    const editors = this.editors.slice();

    editors.forEach((_editor, i) => {

      if (_editor.ref === editor) {

        const buffer = _editor.ref.getModel().getBuffer();
        buffer.destroy();

        this.editors.splice(i, 1);
      }
    });
  }

  updateConfig() {

    this.config.loadEagerly = [];
    this.config.dontLoad = [];

    this.editors.forEach((editor) => {

      const buffer = editor.ref.getModel().getBuffer();
      const text = buffer.getText().trim();

      if (text !== '') {

        this.config[editor.identifier].push(text);
      }
    });

    const json = JSON.stringify(this.config, null, 2);
    const activePane = atom.workspace.getActivePane();

    updateTernFile(json);

    activePane && activePane.destroy();
  }

  destroy() {

    this.editors.forEach((editor) => {

      const buffer = editor.ref.getModel().getBuffer();
      buffer.destroy();
    });

    this.editors = [];
  }
}
