"use strict";

importScripts(
  '../node_modules/tern/node_modules/acorn/dist/acorn.js',
  '../node_modules/tern/node_modules/acorn/dist/acorn_loose.js',
  '../node_modules/tern/node_modules/acorn/dist/walk.js',
  '../node_modules/tern/lib/signal.js',
  '../node_modules/tern/lib/tern.js',
  '../node_modules/tern/lib/def.js',
  '../node_modules/tern/lib/infer.js',
  '../node_modules/tern/lib/comment.js',
  '../node_modules/tern/plugin/commonjs.js',
  '../node_modules/tern/plugin/node_resolve.js',
  '../node_modules/tern/plugin/modules.js'
);

class Server {

  constructor() {

    this.pendingID = 0;
    this.pending = [];
  }

  request(data) {

    function done(err, reqData) {

      postMessage({

        id: data.id,
        err: String(err),
        data: reqData
      });
    }

    this.ternServer.request(data.data, done);
  }

  importPlugins(plugins) {

    importScripts.apply((void 0), plugins);
  }

  flush(data) {

    if (!this.ternServer) {

      return;
    }

    function done(err) {

      postMessage({

        id: data.id,
        err: String(err)
      });
    }

    this.ternServer.flush(done);
  }
  
  startServer(data) {

    this.importPlugins(data.config.pluginImports);

    this.ternServer = new tern.Server({

      getFile: (name, c) => {

        this.pending.push(c);

        postMessage({

          id: this.pendingID,
          type: 'getFile',
          name: name
        });

        this.pendingID++;
      },
      async: true,
      defs: data.defs,
      plugins: data.plugins,
      debug: false,
      projectDir: data.dir,
      ecmaVersion: data.config.ecmaVersion,
      dependencyBudget: data.config.dependencyBudget,
      stripCRs: false
    });

    if (data.files) {

      for (let i = 0; i < data.files.length; i++) {

        this.ternServer.addFile(data.files[i]);
      }
    }
  }
}

let server = new Server();

onmessage = function(e) {

  if (e.data.type === 'query') {

    server.request(e.data);
    return;
  }

  if (e.data.type === 'pending') {

    server.pending[e.data.id](e.data.data[0], e.data.data[1]);
    return;
  }

  if (e.data.type === 'flush') {

    server.flush(e.data);
    return;
  }

  if (e.data.type === 'init') {

    server.startServer(e.data);
    return;
  }
};
