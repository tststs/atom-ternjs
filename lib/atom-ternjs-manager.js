"use babel";

let Server;
let Client;
let Documentation;
let Helper;
let PackageConfig;
let Config;
let Type;
let Reference;
let Rename;
let _ = require('underscore-plus');

export default class Manager {

  constructor(provider) {

    this.provider = provider;

    this.disposables = [];

    this.grammars = ['JavaScript'];

    this.clients = [];
    this.client = undefined;
    this.servers = [];
    this.server = undefined;

    this.editors = [];

    this.rename = undefined;
    this.type = undefined;
    this.reference = undefined;
    this.documentation = undefined;

    this.initialised = false;

    window.setTimeout(this.init.bind(this), 0);
  }

  init() {

    Helper = require('./atom-ternjs-helper.coffee');
    PackageConfig = require('./atom-ternjs-package-config');
    Config = require('./atom-ternjs-config');

    this.helper = new Helper(this);
    this.packageConfig = new PackageConfig(this);
    this.config = new Config(this);
    this.provider.init(this);
    this.initServers();

    this.registerHelperCommands();

    this.disposables.push(atom.project.onDidChangePaths((paths) => {

      this.destroyServer(paths);
      this.checkPaths(paths);
      this.setActiveServerAndClient();
    }));
  }

  activate() {

    this.initialised = true;
    this.registerEvents();
    this.registerCommands();
  }

  destroyObject(object) {

    if (object) {

      object.destroy();
    }
    object = undefined;
  }

  destroy() {

    for (let server of this.servers) {

      server.destroy();
      server = undefined;
    }
    this.servers = [];

    for (let client of this.clients) {

      client = undefined;
    }
    this.clients = [];

    this.server = undefined;
    this.client = undefined;
    this.unregisterEventsAndCommands();
    this.provider = undefined;

    this.destroyObject(this.config);
    this.destroyObject(this.packageConfig);
    this.destroyObject(this.reference);
    this.destroyObject(this.rename);
    this.destroyObject(this.type);
    this.destroyObject(this.helper);

    this.initialised = false;
  }

  unregisterEventsAndCommands() {

    for (let disposable of this.disposables) {

      if (!disposable) {

        continue;
      }

      disposable.dispose();
    }

    this.disposables = [];
  }

  initServers() {

    let dirs = atom.project.getDirectories();

    if (dirs.length === 0) {

      return;
    }

    for (let dir of dirs) {

      dir = atom.project.relativizePath(dir.path)[0];

      if (this.helper.isDirectory(dir)) {

        this.startServer(dir);
      }
    }
  }

  startServer(dir) {

    if (!Server) {

      Server = require('./atom-ternjs-server');
    }

    if (this.getServerForProject(dir)) {

      return;
    }

    let client = this.getClientForProject(dir);

    if (!client) {

      if (!Client) {

        Client = require('./atom-ternjs-client');
      }

      let clientIdx = this.clients.push(new Client(this, dir)) - 1;
      client = this.clients[clientIdx];
    }

    this.servers.push(new Server(dir, client, this));

    if (this.servers.length === this.clients.length) {

      if (!this.initialised) {

        this.activate();
      }

      this.setActiveServerAndClient(dir);
    }
  }

  setActiveServerAndClient(URI) {

    if (!URI) {

      let activePane = atom.workspace.getActivePaneItem();

      if (activePane && activePane.getURI) {

        URI = activePane.getURI();

      } else {

        this.server = undefined;
        this.client = undefined;

        return;
      }
    }

    let dir = atom.project.relativizePath(URI)[0];
    let server = this.getServerForProject(dir);
    let client = this.getClientForProject(dir);

    if (server && client) {

      this.server = server;
      this.config.gatherData();
      this.client = client;

    } else {

      this.server = undefined;
      this.config.clear();
      this.client = undefined;
    }
  }

  checkPaths(paths) {

    for (let path of paths) {

      let dir = atom.project.relativizePath(path)[0];

      if (this.helper.isDirectory(dir)) {

        this.startServer(dir);
      }
    }
  }

  destroyServer(paths) {

    if (this.servers.length === 0) {

      return;
    }

    let serverIdx;

    for (let i = 0; i < this.servers.length; i++) {

      if (paths.indexOf(this.servers[i].projectDir) === -1) {

        serverIdx = i;
        break;
      }
    }

    if (serverIdx === undefined) {

      return;
    }

    let server = this.servers[serverIdx];
    let client = this.getClientForProject(server.projectDir);
    client = undefined;

    server.destroy();
    server = undefined;

    this.servers.splice(serverIdx, 1);
  }

  getServerForProject(projectDir) {

    for (let server of this.servers) {

      if (server.projectDir === projectDir) {

        return server;
      }
    }

    return false;
  }

  getClientForProject(projectDir) {

    for (let client of this.clients) {

      if (client.projectDir === projectDir) {

        return client;
      }
    }

    return false;
  }

  getEditor(editor) {

    for (let _editor of this.editors) {

      if (_editor.id === editor.id) {

        return _editor;
      }
    }
  }

  isValidEditor(editor) {

    if (!editor || !editor.getGrammar || editor.mini) {

      return;
    }

    if (!editor.getGrammar()) {

      return;
    }

    if (this.grammars.indexOf(editor.getGrammar().name) === -1) {

      return false;
    }

    return true;
  }

  onDidChangeCursorPosition(editor, e) {

    if (this.packageConfig.options.inlineFnCompletion) {

      if (!this.type) {

        Type = require('./atom-ternjs-type');
        this.type = new Type(this);
      }

      this.type.queryType(editor, e.cursor);
    }

    if (this.rename) {

      this.rename.hide();
    }
  }

  registerEvents() {

    this.disposables.push(atom.workspace.observeTextEditors((editor) => {

      if (!this.isValidEditor(editor)) {

        return;
      }

      // Register valid editor
      this.editors.push({

        id: editor.id,
        diffs: []
      });

      if (!this.initCalled) {

        this.init();
      }

      let editorView = atom.views.getView(editor);

      if (editorView) {

        this.disposables.push(editorView.addEventListener('click', (e) => {

          if (!e[this.helper.accessKey]) {

            return;
          }

          if (this.client) {

            this.client.definition();
          }
        }));
      }

      let scrollView;

      if (!editorView.shadowRoot) {

        scrollView = editorView.querySelector('.scroll-view');

      } else {

        scrollView = editorView.shadowRoot.querySelector('.scroll-view');
      }

      if (scrollView) {

        this.disposables.push(scrollView.addEventListener('mousemove', (e) => {

          if (!e[this.helper.accessKey]) {

            return;
          }

          if (e.target.classList.contains('line')) {

            return;
          }

          e.target.classList.add('atom-ternjs-hover');
        }));

        this.disposables.push(scrollView.addEventListener('mouseout', (e) => {

          e.target.classList.remove('atom-ternjs-hover');
        }));
      }

      this.disposables.push(editor.onDidChangeCursorPosition((e) => {

        if (this.type) {

          this.type.destroyOverlay();
        }

        if (this.documentation) {

          this.documentation.destroyOverlay();
        }
      }));

      this.disposables.push(editor.onDidChangeCursorPosition(_.debounce(this.onDidChangeCursorPosition.bind(this, editor), 300)));

      this.disposables.push(editor.getBuffer().onDidSave((e) => {

        if (this.client) {

          this.client.update(editor);
        }
      }));

      this.disposables.push(editor.getBuffer().onDidChange((e) => {

        this.getEditor(editor).diffs.push(e);
      }));
    }));

    this.disposables.push(atom.workspace.onDidChangeActivePaneItem((item) => {

      if (this.config) {

        this.config.clear();
      }

      if (this.type) {

        this.type.destroyOverlay();
      }

      if (this.rename) {

        this.rename.hide();
      }

      if (!this.isValidEditor(item)) {

        if (this.reference) {

          this.reference.hide();
        }

      } else {

        this.setActiveServerAndClient(item.getURI());
      }
    }));
  }

  registerHelperCommands() {

    this.disposables.push(atom.commands.add('atom-workspace', 'atom-ternjs:openConfig', (e) => {

      if (!this.config) {

        this.config = new Config(this);
      }

      this.config.show();
    }));
  }

  registerCommands() {

    this.disposables.push(atom.commands.add('atom-text-editor', 'core:cancel', (e) => {

      if (this.config) {

        this.config.hide();
      }

      if (this.type) {

        this.type.destroyOverlay();
      }

      if (this.rename) {

        this.rename.hide();
      }

      if (this.reference) {

        this.reference.hide();
      }

      if (this.documentation) {

        this.documentation.destroyOverlay();
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:listFiles', (e) => {

      if (this.client) {

        this.client.files().then((data) => {

          console.dir(data);
        });
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:flush', (e) => {

      if (this.server) {

        this.server.flush();
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:documentation', (e) => {

      if (!this.documentation) {

        Documentation = require('./atom-ternjs-documentation');
        this.documentation = new Documentation(this);
      }

      if (this.client) {

        this.documentation.request();
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:references', (e) => {

      if (!this.reference) {

        Reference = require('./atom-ternjs-reference');
        this.reference = new Reference(this);
      }

      this.reference.findReference();
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:rename', (e) => {

        if (!this.rename) {

          Rename = require('./atom-ternjs-rename');
          this.rename = new Rename(this);
        }

        this.rename.show();
      }
    ));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:markerCheckpointBack', (e) => {

      if (this.helper) {

        this.helper.markerCheckpointBack();
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:startCompletion', (e) => {

      if (this.provider) {

        this.provider.forceCompletion();
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:definition', (e) => {

      if (this.client) {

        this.client.definition();
      }
    }));

    this.disposables.push(atom.commands.add('atom-workspace', 'atom-ternjs:restart', (e) => {

      this.restartServer();
    }));
  }

  restartServer() {

    if (!this.server) {

      return;
    }

    let dir = this.server.projectDir;

    for (let i = 0; i < this.servers.length; i++) {

      if (dir === this.servers[i].projectDir) {

        serverIdx = i;
        break;
      }
    }

    if (this.server) {

      this.server.destroy();
    }

    this.server = undefined;
    this.servers.splice(serverIdx, 1);
    this.startServer(dir);
  }
}
