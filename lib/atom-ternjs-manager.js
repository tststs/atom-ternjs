'use babel';

import Server from './atom-ternjs-server';
import Client from './atom-ternjs-client';
import {debounce} from 'underscore-plus';
import emitter from './atom-ternjs-events';
import documentation from './atom-ternjs-documentation';
import reference from './atom-ternjs-reference';
import packageConfig from './atom-ternjs-package-config';
import type from './atom-ternjs-type';
import config from './atom-ternjs-config';
import {
  isDirectory,
  isValidEditor,
  disposeAll
} from './atom-ternjs-helper';
import provider from './atom-ternjs-provider';
import rename from './atom-ternjs-rename';
import navigation from './services/navigation';

class Manager {

  constructor() {

    this.disposables = [];
    /**
     * collection of all active clients
     * @type {Array}
     */
    this.clients = [];
    /**
     * reference to the client for the active project
     * @type {Client}
     */
    this.client = null;
    /**
     * collection of all active servers
     * @type {Array}
     */
    this.servers = [];
    /**
     * reference to the server for the active project
     * @type {Server}
     */
    this.server = null;
    this.editors = [];
  }

  activate() {

    this.registerListeners();
    this.registerCommands();

    config.init();
    documentation.init();
    packageConfig.init();
    provider.init();
    reference.init();
    rename.init();
    type.init();

    this.initServers();

    this.disposables.push(atom.project.onDidChangePaths((paths) => {

      this.destroyServer(paths);
      this.checkPaths(paths);
      this.setActiveServerAndClient();
    }));
  }

  destroy() {

    disposeAll(this.disposables);
    this.disposables = [];
    this.editors.forEach(editor => disposeAll(editor.disposables));
    this.editors = [];

    for (const server of this.servers) {

      server.destroy();
    }

    this.servers = [];
    this.clients = [];

    this.server = null;
    this.client = null;

    documentation && documentation.destroy();
    reference && reference.destroy();
    type && type.destroy();
    packageConfig && packageConfig.destroy();
    rename && rename.destroy();
    config && config.destroy();
    provider && provider.destroy();
    navigation.reset();
  }

  initServers() {

    const projectDirectories = atom.project.getDirectories();

    projectDirectories.forEach((projectDirectory) => {

      const directory = atom.project.relativizePath(projectDirectory.path)[0];

      if (isDirectory(directory)) {

        this.startServer(directory);
      }
    });
  }

  startServer(dir) {

    if (this.getServerForProject(dir)) {

      return;
    }

    let client = this.getClientForProject(dir);

    if (!client) {

      let clientIdx = this.clients.push(new Client(dir)) - 1;
      client = this.clients[clientIdx];
    }

    this.servers.push(new Server(dir, client));

    if (this.servers.length === this.clients.length) {

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
      this.client = client;

    } else {

      this.server = null;
      this.client = null;
    }
  }

  checkPaths(paths) {

    for (let path of paths) {

      let dir = atom.project.relativizePath(path)[0];

      if (isDirectory(dir)) {

        this.startServer(dir);
      }
    }
  }

  destroyClient(path) {

    const clients = this.clients.slice();

    clients.forEach((client, i) => {

      if (client.projectDir === path) {

        this.clients.splice(i, 1);
      }
    });
  }

  destroyServer(paths) {

    if (this.servers.length === 0) {

      return;
    }

    const servers = this.servers.slice();

    servers.forEach((server, i) => {

      if (!paths.includes(server.projectDir)) {

        this.destroyClient(server.projectDir);
        server.destroy();
        this.servers.splice(i, 1);
      }
    });
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

  getEditor(id) {

    return this.editors.filter(editor => editor.id === id).pop();
  }

  onDidChangeCursorPosition(editor, e) {

    if (packageConfig.options.inlineFnCompletion) {

      type.queryType(editor, e.cursor);
    }
  }

  destroyEditor(id) {

    const editors = this.editors.slice();

    editors.forEach((editor, i) => {

      if (editor.id === id) {

        disposeAll(editor.disposables);
        this.editors.splice(i, 1);
      }
    });
  }

  registerListeners() {

    this.disposables.push(atom.workspace.observeTextEditors((editor) => {

      if (!isValidEditor(editor)) {

        return;
      }

      const id = editor.id;
      const disposables = [];

      disposables.push(editor.onDidDestroy(this.destroyEditor.bind(this, id)));

      disposables.push(editor.onDidChangeCursorPosition((e) => {

        emitter.emit('type-destroy-overlay');
        emitter.emit('documentation-destroy-overlay');
      }));

      disposables.push(editor.onDidChangeCursorPosition(debounce(this.onDidChangeCursorPosition.bind(this, editor), 300)));

      disposables.push(editor.getBuffer().onDidSave((e) => {

        this.client && this.client.update(editor);
      }));

      disposables.push(editor.getBuffer().onDidChange((e) => {

        const editor = this.getEditor(id);

        editor.isDirty = true;
      }));

      // Register valid editor
      this.editors.push({

        id,
        disposables,
        isDirty: false
      });
    }));

    this.disposables.push(atom.workspace.onDidChangeActivePaneItem((item) => {

      emitter.emit('config-clear');
      emitter.emit('type-destroy-overlay');
      emitter.emit('documentation-destroy-overlay');
      emitter.emit('rename-hide');

      if (!isValidEditor(item)) {

        emitter.emit('reference-hide');

      } else {

        this.setActiveServerAndClient(item.getURI());
      }
    }));
  }

  registerCommands() {

    this.disposables.push(atom.commands.add('atom-text-editor', 'core:cancel', (e) => {

      emitter.emit('config-clear');
      emitter.emit('type-destroy-overlay');
      emitter.emit('documentation-destroy-overlay');
      emitter.emit('reference-hide');
      emitter.emit('rename-hide');
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:listFiles', (e) => {

      if (this.client) {

        this.client.files().then((data) => {

          console.dir(data);
        });
      }
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:flush', (e) => {

      this.server && this.server.flush();
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:navigateBack', (e) => {

      navigation.goTo(-1);
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:navigateForward', (e) => {

      navigation.goTo(1);
    }));

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:definition', (e) => {

      this.client && this.client.definition();
    }));

    this.disposables.push(atom.commands.add('atom-workspace', 'atom-ternjs:restart', (e) => {

      this.server && this.server.restart();
    }));
  }

  removeActiveServer() {

    if (!this.server) {

      atom.notifications.addInfo('There is no server to remove.');

      return;
    }

    const projectDir = this.server.projectDir;
    const servers = this.servers.slice();

    servers.forEach((server, i) => {

      if (server.projectDir === projectDir) {

        this.servers.splice(i, 1);
      }
    });

    this.server = null;
  }
}

export default new Manager();
