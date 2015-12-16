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
    this.portFileName = '.tern-port';
    this.maxIdleTime = 6e4 * 5; // Shut down after five minutes of inactivity

    this.persistent = true;
    this.stripCRs = false;
    this.disableLoadingLocal = false;
    this.verbose = false;
    this.debug = false;
    this.noPortFile = true;
    this.host = '127.0.0.1';
    this.port = 0;
    this.httpServer = null;

    this.getHomeDir();
    this.init();
  }

  init() {

    if (!this.projectDir) {

      return;
    }

    let config = this.readProjectFile(path.resolve(this.projectDir, this.projectFileName));

    if (!config) {

      config = this.defaultConfig;
    }

    this.httpServer = require('http').createServer((req, resp) => {

      clearTimeout(this.shutdown);
      this.shutdown = setTimeout(this.doShutdown.bind(this), this.maxIdleTime);

      var target = url.parse(req.url, true);

      if (target.pathname == '/ping') {

        return this.respondSimple(resp, 200, 'pong');
      }

      if (target.pathname != '/') {

        return this.respondSimple(resp, 404, `No service at ${target.pathname}`);
      }

      if (req.method === 'POST') {

        var body = '';

        req.on('data', function (data) {

          body += data;
        });

        req.on('end', () => {

          this.respond(resp, body);
        });

      } else if (req.method === 'GET') {

        if (target.query.doc) {

          this.respond(resp, target.query.doc);

        } else {

          this.respondSimple(resp, 400, 'Missing query document');
        }
      }
    });

    this.server = this.startServer(this.projectDir, config, this.httpServer);
    this.shutdown = setTimeout(this.doShutdown.bind(this), this.maxIdleTime);

    this.httpServer.listen(this.port, this.host, () => {

      this.port = this.httpServer.address().port;
      this.client.port = this.port;

      if (!this.noPortFile) {

        this.portFile = path.resolve(this.projectDir, this.portFileName);
        fs.writeFileSync(this.portFile, String(this.port), 'utf8');
      }

      console.log(`Listening on port ${this.port}`);
    });
  }

  flush() {

    this.server.flush(() => {

      atom.notifications.addInfo('All files fetched an analyzed.');
    });
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

  startServer(dir, config, httpServer) {

    let defs = this.findDefs(dir, config);
    let plugins = this.loadPlugins(dir, config);
    let server = new tern.Server({

      getFile: function(name, c) {

        if (config.dontLoad && config.dontLoad.some(function (pat) {

          return minimatch(name, pat);

        })) {

          c(null, '');

        } else {

          fs.readFile(path.resolve(dir, name), 'utf8', c);
        }
      },
      normalizeFilename: function(name) {

        let pt = path.resolve(dir, name);

        try {

          pt = fs.realpathSync(path.resolve(dir, name));

        } catch(e) {

          console.error(e.message);
        }

        return path.relative(dir, pt);
      },
      async: true,
      defs: defs,
      plugins: plugins,
      debug: this.debug,
      projectDir: dir,
      ecmaVersion: config.ecmaVersion,
      dependencyBudget: config.dependencyBudget,
      stripCRs: this.stripCRs,
      parent: {httpServer: this.httpServer}
    });

    if (config.loadEagerly) {

      config.loadEagerly.forEach(function(pat) {

        glob.sync(pat, { cwd: dir }).forEach(function(file) {

          server.addFile(file);
        });
      });
    }

    return server;
  }

  doShutdown() {

    if (this.persistent) {

      return;
    }

    console.log(`Was idle for ${Math.floor(this.maxIdleTime / 6e4)} minutes. Shutting down.`);
    this.destroy();
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

  destroy() {

    if (this.httpServer) {

      this.httpServer.close();
    }

    try {

      var cur = Number(fs.readFileSync(this.portFile, 'utf8'));

      if (cur === this.port) {

        fs.unlinkSync(this.portFile);
      }

    } catch(e) {}
  }
}
