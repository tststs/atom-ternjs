"use babel";

let tern = require('tern');
let infer = require('../node_modules/tern/lib/infer');
let fs = require('fs');
let path = require('path');
let url = require('url');
let glob = require('glob');
let minimatch = require('minimatch');

export default class Server {

  constructor(projectRoot, client, manager) {

    process.__tern = tern;
    process.__infer = infer;

    this.manager = manager;
    this.client = client;

    this.requestID = 0;

    this.resolves = [];

    this.projectDir = projectRoot;
    this.distDir = path.resolve(__dirname, '../node_modules/tern');

    this.defaultConfig = {

      libs: [],
      loadEagerly: false,
      plugins: {},
      ecmaScript: true,
      ecmaVersion: 6,
      dependencyBudget: tern.defaultOptions.dependencyBudget
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

    let promise = new Promise((resolve, reject) => {

      this.resolves.push(resolve);

      this.worker.postMessage({

        type: type,
        id: this.requestID,
        data: data
      });
    });

    this.requestID++;

    return promise;
  }

  flush() {

    this.request('flush', {}).then(() => {

      atom.notifications.addInfo('All files fetched an analyzed.');
    });
  }

  onWorkerMessage(e) {

    if (!e.data.type) {

      this.resolves[e.data.id](e.data.data);
      return;
    }

    if (e.data.type === 'getFile') {

      let result;

      if (this.config.dontLoad && this.config.dontLoad.some(function (pat) {

        return minimatch(e.data.name, pat);

      })) {

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
            data: [err, data]
          });
        });
      }
    }
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

    for (var plugin in plugins) {

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

      let mod = require(found);

      if (mod.hasOwnProperty('initialize')) {

        mod.initialize(this.distDir);
      }

      options[path.basename(plugin)] = val;
    }

    this.defaultPlugins(config).forEach((name) => {

      if (!plugins.hasOwnProperty(name)) {

        options[name] = true;
      }
    });

    return options;
  }

  respondSimple(resp, status, text) {

    resp.writeHead(status, {

      'content-type': 'text/plain; charset=utf-8'
    });

    resp.end(text);

    if (this.verbose) {

      console.log(`Response: ${status} ${text}`);
    }
  }

  respond(resp, doc) {

    try {

      doc = JSON.parse(doc);

    } catch(e) {

      return this.respondSimple(resp, 400, `JSON parse error: ${e.message}`);
    }

    if (this.verbose) {

      console.log('Request: ' + JSON.stringify(doc, null, 2));
    }

    this.server.request(doc, (err, data) => {

      if (err) {

        return this.respondSimple(resp, 400, String(err));
      }

      resp.writeHead(200, {

        'content-type': 'application/json; charset=utf-8'
      });

      if (this.verbose) {

        console.log(`Response: ${JSON.stringify(data, null, 2)} \n`);
      }

      resp.end(JSON.stringify(data));
    });
  }
}
