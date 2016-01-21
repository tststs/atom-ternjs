var tern = require('tern');
var path = require('path');
var minimatch = require('minimatch');
var fs = require('fs');

module.exports = TernServer = function () {

  this.config = {};
};

TernServer.prototype.startServer = function (data) {

  this.config = data.config;

  this.ternServer = new tern.Server({

    getFile: function(name, c) {

      if (this.config.dontLoad && this.config.dontLoad.some(function(pat) {

        return minimatch(name, pat);
      })) {

        c(null, "");

      } else {

        fs.readFile(path.resolve(data.dir, name), 'utf8', c);
      }
    }.bind(this),
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

    for (var i = 0; i < data.files.length; i++) {

      this.ternServer.addFile(data.files[i]);
    }
  }
};

TernServer.prototype.request = function (data) {

  function done(err, reqData) {

    process.send({

      id: data.id,
      err: String(err),
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
      err: String(err)
    });
  }

  this.ternServer.flush(done);
};

var server = new TernServer();

process.on('uncaughtException', function (err) {

  process.send({

    error: err
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
