var infer = require('tern/lib/infer');
var tern = require('tern/lib/tern');
var path = require('path');
var minimatch = require('minimatch');
var fs = require('fs');

var TERN_ROOT = path.resolve(__dirname, '../node_modules/tern');
var TernServer;

module.exports = TernServer = function () {

  process.__tern = tern;
  process.__infer = infer;
};

TernServer.prototype.importPlugins = function (plugins) {

  for (var i = 0; i < plugins.length; i++) {

    var mod = require(plugins[i]);
    if (mod.hasOwnProperty('initialize')) {

      mod.initialize(TERN_ROOT);
    }
  }
};

TernServer.prototype.startServer = function (data) {

  this.importPlugins(data.config.pluginImports);

  this.ternServer = new tern.Server({

    getFile: function(name, c) {

      if (data.config.dontLoad && data.config.dontLoad.some(function(pat) {

        return minimatch(name, pat);
      })) {

        if (data.config.async) {

          c(null, '');

          return;
        }

        return '';

      } else {

        if (data.config.async) {

          fs.readFile(path.resolve(data.dir, name), 'utf8', c);

          return;
        }

        return fs.readFileSync(path.resolve(data.dir, name), 'utf8');
      }
    },
    async: data.config.async,
    defs: data.defs,
    plugins: data.plugins,
    debug: false,
    projectDir: data.dir,
    ecmaVersion: data.config.ecmaVersion,
    dependencyBudget: data.config.dependencyBudget,
    stripCRs: false
  });

  if (data.files) {

    for (var i = 0; i < data.files.length; i++) {

      this.ternServer.addFile(data.files[i]);
    }
  }
};

TernServer.prototype.request = function (data) {

  function done(err, reqData) {

    process.send({

      id: data.id,
      error: String(err),
      data: reqData
    });
  }

  this.ternServer.request(data.data, done);
};

TernServer.prototype.flush = function (data) {

  if (!this.ternServer) {

    return;
  }

  function done(err) {

    process.send({

      id: data.id,
      error: String(err)
    });
  }

  this.ternServer.flush(done);
};

var server = new TernServer();

process.on('uncaughtException', function (err) {

  process.send({

    error: {

      isUncaughtException: true,
      message: String(err)
    }
  });
});

process.on('disconnect', function () {

  process.kill();
});

process.on('message', function (e) {

  if (e.type === 'query') {

    server.request(e);
    return;
  }

  if (e.type === 'flush') {

    server.flush(e);
    return;
  }

  if (e.type === 'init') {

    server.startServer(e);
    return;
  }
});
