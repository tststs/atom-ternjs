"use babel";

let fs = require('fs');
let path = require('path');
let glob = require('glob');
let minimatch = require('minimatch');
let uuid = require('node-uuid');

export default class Server {

  constructor(projectRoot, client, manager) {

    this.manager = manager;
    this.client = client;

    this.resolves = {};

    this.projectDir = projectRoot;
    this.distDir = path.resolve(__dirname, '../node_modules/tern');

    this.defaultConfig = {

      libs: [],
      loadEagerly: false,
      plugins: {},
      ecmaScript: true,
      ecmaVersion: 6,
      dependencyBudget: 20000
    };

    this.projectFileName = '.tern-project';
    this.disableLoadingLocal = false;

    this.getHomeDir();
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

    this.worker = new Worker(path.resolve(__dirname, './atom-ternjs-server-worker.js'));
    this.worker.onmessage = this.onWorkerMessage.bind(this);

    this.worker.postMessage({

      type: 'init',
      dir: this.projectDir,
      config: this.config,
      defs: defs,
      plugins: plugins,
      files: files
    });
  }

  request(type, data) {

    let requestID = uuid.v1();

    return new Promise((resolve, reject) => {

      this.resolves[requestID] = resolve;

      this.worker.postMessage({

        type: type,
        id: requestID,
        data: data
      });
    });
  }

  flush() {

    this.request('flush', {}).then(() => {

      atom.notifications.addInfo('All files fetched an analyzed.');
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

    if (!e.data.type) {

      this.resolves[e.data.id](e.data.data);
      delete(this.resolves[e.data.id]);

      return;
    }

    if (e.data.type === 'getFile') {

      let result;

      if (this.dontLoad(e.data.name)) {

        this.worker.postMessage({

          type: 'pending',
          id: e.data.id,
          data: [null, '']
        });

      } else {

        fs.readFile(path.resolve(this.projectDir, e.data.name), 'utf8', (err, data) => {

          this.worker.postMessage({

            type: 'pending',
            id: e.data.id,
            data: [String(err), data]
          });
        });
      }
    }
  }

  destroy() {

    this.worker.terminate();
    this.worker = undefined;
  }

  getHomeDir() {

    let homeDir = process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE;

    if (homeDir && fs.existsSync(path.resolve(homeDir, '.tern-config'))) {

      this.defaultConfig = this.readProjectFile(path.resolve(homeDir, '.tern-config'));
    }
  }

  readJSON(fileName) {

    if (this.manager.helper.fileExists(fileName) !== undefined) {

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

  readProjectFile(fileName) {

    let data = this.readJSON(fileName);

    if (!data) {

      return false;
    }

    for (var option in this.defaultConfig) if (!data.hasOwnProperty(option))
      data[option] = this.defaultConfig[option];
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

    if (config.ecmaScript) {

      if (src.indexOf('ecma6') == -1 && config.ecmaVersion >= 6) {

        src.unshift('ecma6');
      }

      if (src.indexOf('ecma5') == -1) {

        src.unshift('ecma5');
      }
    }

    for (var i = 0; i < src.length; ++i) {

      let file = src[i];

      if (!/\.json$/.test(file)) {

        file = `${file}.json`;
      }

      let found = this.findFile(file, projectDir, path.resolve(this.distDir, 'defs'));

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

  defaultPlugins(config) {

    let result = ['doc_comment'];
    return result;
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

      let found = this.findFile(`${plugin}.js`, projectDir, path.resolve(this.distDir, 'plugin'));

      if (!found) {

        try {

          found = require.resolve(`tern-${plugin}`);

        } catch(e) {}
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

    this.defaultPlugins(config).forEach((name) => {

      if (!plugins.hasOwnProperty(name)) {

        options[name] = true;
      }
    });

    return options;
  }
}
