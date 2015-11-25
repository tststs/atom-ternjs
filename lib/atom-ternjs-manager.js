"use babel";

let Server;
let Client;
let Helper;
let Config;

export default class Manager {

  constructor(provider) {

    this.provider = provider;

    this.disposables = [];
    this.grammars = ['JavaScript'];
    this.clients = [];
    this.client = undefined;
    this.servers = [];
    this.server = undefined;
    this.rename = undefined;
    this.useSnippets = false;
    this.useSnippetsAndFunction = false;
    this.doNotAddParantheses = false;
    this.type = undefined;
    this.useLint = undefined;
    this.reference = undefined;
    this.initialised = false;
    this.inlineFnCompletion = false;

    this.init();
  }

  init() {

    this.registerHelperCommands();

    Helper = require('./atom-ternjs-helper');
    Config = require('./atom-ternjs-config');

    this.helper = new Helper(this);
    this.config = new Config(this);
    this.provider.init(this);
    this.initServers();

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

  destroy() {

    for (let server of this.servers) {

      server.destroy();
      server = null;
    }
    this.servers = [];

    for (let client of this.clients) {

      client.unregisterEvents();
      client = undefined;
    }
    this.clients = [];

    this.server = null;
    this.client = null;
    this.unregisterEventsAndCommands();
    this.provider = null;

    if (this.config) {

      this.config.destroy();
    }
    this.config = null;

    if (this.reference) {

      this.reference.destroy();
    }
    this.reference = null;

    if (this.rename) {

      this.rename.destroy();
    }
    this.rename = null;

    if (this.type) {

      this.type.destroy();
    }
    this.type = null;

    if (this.helper) {

      this.helper.destroy();
    }
    this.helper = null;

    this.initialised = false;
  }

  unregisterEventsAndCommands() {

    for (let disposable of this.disposables) {

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

    this.servers.push(new Server(dir, client, this)) - 1;

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

        this.server = null;
        this.client = null;

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

      this.server = null;
      this.config.clear();
      this.client = null;
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

      if (paths.indexOf(this.servers[i].projectDir)  === -1) {

        serverIdx = i;
        break;
      }
    }

    if (serverIdx === undefined) {

      return;
    }

    let server = this.servers[serverIdx];
    let client = this.getClientForProject(server.projectDir);

    if (client) {

      client.unregisterEvents();
    }
    client = null;

    server.destroy();
    server = null;

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

    if (this.inlineFnCompletion) {

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

    this.disposables.push(atom.commands.add('atom-text-editor', 'tern:references', (e) => {

      if (!this.reference) {

        Reference = require('./atom-ternjs-reference');
        this.reference = new Reference(this);
      }

      this.reference.findReference();
    }));

    this.disposables.push(atom.workspace.observeTextEditors((editor) => {

      if (!this.isValidEditor(editor)) {

        return;
      }

      if (!this.initCalled) {

        this.init();
      }

      let editorView = atom.views.getView(editor);

      this.disposables.push(editorView.addEventListener('click', (e) => {

        if (!e[this.helper.accessKey]) {

          return;
        }

        if (this.client) {

          this.client.definition();
        }
      }));

      this.disposables.push(editor.onDidChangeCursorPosition(this.helper._.debounce(this.onDidChangeCursorPosition.bind(this, editor), 300)));

      this.disposables.push(editor.getBuffer().onDidSave((e) => {

        if (this.client) {

          this.client.update(editor.getURI(), editor.getText());
        }
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

    this.disposables.push(atom.config.observe('atom-ternjs.inlineFnCompletion', (value) => {

      this.inlineFnCompletion = value;

      if (this.type) {

        this.type.destroyOverlay();
      }
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.lint', (value) => {

      this.useLint = value;
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.useSnippets', (value) => {

      this.useSnippets = value;

      if (!value) {

        return;
      }

      atom.config.set('atom-ternjs.doNotAddParantheses', false);
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.useSnippetsAndFunction', (value) => {

      this.useSnippetsAndFunction = value;

      if (!value) {

        return;
      }

      atom.config.set('atom-ternjs.doNotAddParantheses', false);
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.doNotAddParantheses', (value) => {

      this.doNotAddParantheses = value;

      if (!value) {

        return;
      }

      atom.config.set('atom-ternjs.useSnippets', false);
      atom.config.set('atom-ternjs.useSnippetsAndFunction', false);
    }));
  }

  registerHelperCommands() {

    this.disposables.push(atom.commands.add('atom-workspace', 'tern:openConfig', (e) => {

      if (!this.config) {

        if (!Config) {

          Config = require('./atom-ternjs-config');
        }

        this.config = new Config(this);
      }

      this.config.show();
    }));
  }

  registerCommands() {

    this.disposables.push(atom.commands.add('atom-text-editor', 'tern:rename', (e) => {

        if (!this.rename) {

          Rename = require('./atom-ternjs-rename');
          this.rename = new Rename(this);
        }

        this.rename.show();
      }
    ));

    this.disposables.push(atom.commands.add('atom-text-editor', 'tern:markerCheckpointBack', (e) => {

      if (this.helper) {

        this.helper.markerCheckpointBack();
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'tern:startCompletion', (e) => {

      if (this.provider) {

        this.provider.forceCompletion();
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'tern:definition', (e) => {

      if (this.client) {

        this.client.definition();
      }
    }));

    this.disposables.push(atom.commands.add('atom-workspace', 'tern:restart', (e) => {

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
