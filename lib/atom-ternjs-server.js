'use babel';

import manager from './atom-ternjs-manager';
import {fileExists} from './atom-ternjs-helper';
import fs from 'fs';
import path from 'path';
import glob from 'glob';
import cp from 'child_process';
import minimatch from 'minimatch';
import uuid from 'node-uuid';
import resolveFrom from 'resolve-from';
import packageConfig from './atom-ternjs-package-config';

export default class Server {

  constructor(projectRoot, client) {

    this.client = client;

    this.child = null;

    this.resolves = {};
    this.rejects = {};

    this.projectDir = projectRoot;
    this.distDir = path.resolve(__dirname, '../node_modules/tern');

    this.defaultConfig = {

      libs: [],
      loadEagerly: false,
      plugins: {

        doc_comment: true
      },
      ecmaScript: true,
      ecmaVersion: 6,
      dependencyBudget: 20000
    };

    const homeDir = process.env.HOME || process.env.USERPROFILE;

    if (homeDir && fs.existsSync(path.resolve(homeDir, '.tern-config'))) {

      this.defaultConfig = this.readProjectFile(path.resolve(homeDir, '.tern-config'));
    }

    this.projectFileName = '.tern-project';
    this.disableLoadingLocal = false;

    this.init();
  }

  init() {

    if (!this.projectDir) {

      return;
    }

    this.config = this.readProjectFile(path.resolve(this.projectDir, this.projectFileName));

    if (!this.config) {

      this.config = this.defaultConfig;
    }

    this.config.async = packageConfig.options.ternServerGetFileAsync;
    this.config.dependencyBudget = packageConfig.options.ternServerDependencyBudget;

    if (!this.config.plugins['doc_comment']) {

      this.config.plugins['doc_comment'] = true;
    }

    let defs = this.findDefs(this.projectDir, this.config);
    let plugins = this.loadPlugins(this.projectDir, this.config);
    let files = [];

    if (this.config.loadEagerly) {

      this.config.loadEagerly.forEach((pat) => {

        glob.sync(pat, { cwd: this.projectDir }).forEach(function(file) {

          files.push(file);
        });
      });
    }

    this.child = cp.fork(path.resolve(__dirname, './atom-ternjs-server-worker.js'));
    this.child.on('message', this.onWorkerMessage.bind(this));
    this.child.on('error', this.onError);
    this.child.on('disconnect', this.onDisconnect);
    this.child.send({

      type: 'init',
      dir: this.projectDir,
      config: this.config,
      defs: defs,
      plugins: plugins,
      files: files
    });
  }

  onError(e) {

    atom.notifications.addError(`Child process error: ${e}`, {

      dismissable: true
    });
  }

  onDisconnect(e) {

    console.warn(e);
  }

  request(type, data) {

    let requestID = uuid.v1();

    return new Promise((resolve, reject) => {

      this.resolves[requestID] = resolve;
      this.rejects[requestID] = reject;

      this.child.send({

        type: type,
        id: requestID,
        data: data
      });
    });
  }

  flush() {

    this.request('flush', {}).then(() => {

      atom.notifications.addInfo('All files fetched and analyzed.');
    });
  }

  dontLoad(file) {

    if (!this.config.dontLoad) {

      return;
    }

    return this.config.dontLoad.some((pat) => {

      return minimatch(file, pat);
    });
  }

  onWorkerMessage(e) {

    if (e.error && e.error.isUncaughtException) {

      atom.notifications.addError(`UncaughtException: ${e.error.message}. Restarting Server...`, {

        dismissable: false
      });

      for (const key in this.rejects) {

        this.rejects[key]({});
      }

      this.resolves = {};
      this.rejects = {};

      manager.restartServer();

      return;
    }

    const isError = e.error !== 'null' && e.error !== 'undefined';

    if (isError) {

      console.error(e);
    }

    if (!e.type && this.resolves[e.id]) {

      if (isError) {

        this.rejects[e.id](e.error);

      } else {

        this.resolves[e.id](e.data);
      }

      delete this.resolves[e.id];
      delete this.rejects[e.id];
    }
  }

  destroy() {

    if (!this.child) {

      return;
    }

    this.child.disconnect();
    this.child = undefined;
  }

  readJSON(fileName) {

    if (fileExists(fileName) !== undefined) {

      return false;
    }

    let file = fs.readFileSync(fileName, 'utf8');

    try {

      return JSON.parse(file);

    } catch (e) {

      atom.notifications.addError(`Bad JSON in ${fileName}: ${e.message}`, {

        dismissable: true
      });
      this.destroy();
    }
  }

  mergeObjects(base, value) {

    if (!base) {

      return value;
    }

    if (!value) {

      return base;
    }

    let result = {};

    for (const prop in base) {

      result[prop] = base[prop];
    }

    for (const prop in value) {

      result[prop] = value[prop];
    }

    return result;
  }

  readProjectFile(fileName) {

    let data = this.readJSON(fileName);

    if (!data) {

      return false;
    }

    for (var option in this.defaultConfig) {

      if (!data.hasOwnProperty(option)) {

        data[option] = this.defaultConfig[option];

      } else if (option === 'plugins') {

        data[option] = this.mergeObjects(this.defaultConfig[option], data[option]);
      }
    }

    return data;
  }

  findFile(file, projectDir, fallbackDir) {

    let local = path.resolve(projectDir, file);

    if (!this.disableLoadingLocal && fs.existsSync(local)) {

      return local;
    }

    let shared = path.resolve(fallbackDir, file);

    if (fs.existsSync(shared)) {

      return shared;
    }
  }

  findDefs(projectDir, config) {

    let defs = [];
    let src = config.libs.slice();

    if (config.ecmaScript && src.indexOf('ecmascript') === -1) {

      src.unshift('ecmascript');
    }

    for (var i = 0; i < src.length; ++i) {

      let file = src[i];

      if (!/\.json$/.test(file)) {

        file = `${file}.json`;
      }

      let found =
        this.findFile(file, projectDir, path.resolve(this.distDir, 'defs')) ||
        resolveFrom(projectDir, `tern-${src[i]}`)
        ;

      if (!found) {

        try {

          found = require.resolve(`tern-${src[i]}`);

        } catch (e) {

          atom.notifications.addError(`Failed to find library ${src[i]}\n`, {

            dismissable: true
          });
          continue;
        }
      }

      if (found) {

        defs.push(this.readJSON(found));
      }
    }

    return defs;
  }

  loadPlugins(projectDir, config) {

    let plugins = config.plugins;
    let options = {};
    this.config.pluginImports = [];

    for (let plugin in plugins) {

      let val = plugins[plugin];

      if (!val) {

        continue;
      }

      let found =
        this.findFile(`${plugin}.js`, projectDir, path.resolve(this.distDir, 'plugin')) ||
        resolveFrom(projectDir, `tern-${plugin}`)
        ;

      if (!found) {

        try {

          found = require.resolve(`tern-${plugin}`);

        } catch (e) {

          console.warn(e);
        }
      }

      if (!found) {

        try {

          found = require.resolve(`${this.projectDir}/node_modules/tern-${plugin}`);

        } catch (e) {

          atom.notifications.addError(`Failed to find plugin ${plugin}\n`, {

            dismissable: true
          });
          continue;
        }
      }

      this.config.pluginImports.push(found);
      options[path.basename(plugin)] = val;
    }

    return options;
  }
}
