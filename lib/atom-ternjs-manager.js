'use babel';

import Server from './atom-ternjs-server';
import Client from './atom-ternjs-client';
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
import path from 'path';

class Manager {

  constructor() {

    this.disposables = [];
    /**
     * collection of all active clients
     * @type {Array}
     */
    this.clients = [];
    /**
     * reference to the client for the active text-editor
     * @type {Client}
     */
    this.client = null;
    /**
     * collection of all active servers
     * @type {Array}
     */
    this.servers = [];
    /**
     * reference to the server for the active text-editor
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

  startServer(projectDir) {

    if (!isDirectory(projectDir)) {

      return false;
    }

    if (this.getServerForProject(projectDir)) {

      return true;
    }

    const client = new Client(projectDir);
    this.clients.push(client);

    this.servers.push(new Server(projectDir, client));

    this.setActiveServerAndClient(projectDir);

    return true;
  }

  setActiveServerAndClient(uRI) {

    this.server = this.getServerForProject(uRI);
    this.client = this.getClientForProject(uRI);
  }

  destroyClient(projectDir) {

    const clients = this.clients.slice();

    clients.forEach((client, i) => {

      if (client.projectDir === projectDir) {

        this.clients.splice(i, 1);
      }
    });
  }

  destroyServer(projectDir) {

    const servers = this.servers.slice();

    servers.forEach((server, i) => {

      if (server.projectDir === projectDir) {

        server.destroy();
        this.servers.splice(i, 1);
        this.destroyClient(projectDir);
      }
    });
  }

  destroyUnusedServers() {

    const projectDirs = this.editors.map(editor => editor.projectDir);
    const servers = this.servers.slice();

    servers.forEach(server => {

      if (!projectDirs.includes(server.projectDir)) {

        this.destroyServer(server.projectDir);
      }
    });
  }

  getServerForProject(projectDir) {

    return this.servers.filter(server => server.projectDir === projectDir).pop();
  }

  getClientForProject(projectDir) {

    return this.clients.filter(client => client.projectDir === projectDir).pop();
  }

  getEditor(id) {

    return this.editors.filter(editor => editor.id === id).pop();
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

  getProjectDir(uRI) {

    const [project, file] = atom.project.relativizePath(uRI);

    if (project) {

      return project;
    }

    if (file) {

      const absolutePath = path.resolve(__dirname, file);

      return path.dirname(absolutePath);
    }

    return undefined;
  }

  registerListeners() {

    this.disposables.push(atom.workspace.observeTextEditors((editor) => {

      if (!isValidEditor(editor)) {

        return;
      }

      const uRI = editor.getURI();
      const projectDir = this.getProjectDir(uRI);
      const serverCreatedOrPresent = this.startServer(projectDir);

      if (!serverCreatedOrPresent) {

        return;
      }

      const id = editor.id;
      const disposables = [];

      // Register valid editor
      this.editors.push({

        id,
        projectDir,
        disposables
      });

      disposables.push(editor.onDidDestroy(() => {

        this.destroyEditor(id);
        this.destroyUnusedServers();
      }));

      disposables.push(editor.onDidChangeCursorPosition((e) => {

        if (packageConfig.options.inlineFnCompletion) {

          this.client && type.queryType(editor, e);
        }
      }));

      disposables.push(editor.getBuffer().onDidSave((e) => {

        this.client && this.client.update(editor);
      }));
    }));

    this.disposables.push(atom.workspace.onDidChangeActivePaneItem((item) => {

      emitter.emit('type-destroy-overlay');
      emitter.emit('documentation-destroy-overlay');
      emitter.emit('rename-hide');

      if (!isValidEditor(item)) {

        emitter.emit('reference-hide');

      } else {

        const uRI = item.getURI();
        const projectDir = this.getProjectDir(uRI);

        this.setActiveServerAndClient(projectDir);
      }
    }));
  }

  registerCommands() {

    this.disposables.push(atom.commands.add('atom-text-editor', 'core:cancel', (e) => {

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
}

export default new Manager();
