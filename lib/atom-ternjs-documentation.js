'use babel';

const DocumentationView = require('./atom-ternjs-documentation-view');

import manager from './atom-ternjs-manager';
import emitter from './atom-ternjs-events';
import {disposeAll} from './atom-ternjs-helper';
import {
  replaceTags,
  formatType
} from '././atom-ternjs-helper';
import debug from './services/debug';

class Documentation {

  constructor() {

    this.disposables = [];

    this.view = new DocumentationView();
    this.view.initialize(this);

    atom.views.getView(atom.workspace).appendChild(this.view);

    this.destroyDocumenationHandler = this.destroyOverlay.bind(this);
    emitter.on('documentation-destroy-overlay', this.destroyDocumenationHandler);

    this.registerCommands();
  }

  registerCommands() {

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:documentation', this.request.bind(this)));
  }

  request() {

    let editor = atom.workspace.getActiveTextEditor();

    if (
      !editor ||
      !manager.client
    ) {

      return;
    }

    let cursor = editor.getLastCursor();
    let position = cursor.getBufferPosition();

    manager.client.update(editor).then((data) => {

      manager.client.documentation(atom.project.relativizePath(editor.getURI())[1], {

        line: position.row,
        ch: position.column

      }).then((data) => {

        if (!data) {

          return;
        }

        this.view.setData({

          doc: replaceTags(data.doc),
          origin: data.origin,
          type: formatType(data),
          url: data.url || ''
        });

        this.show();
      });
    })
    .catch((err) => {

      err && debug.handleReject(err.type, err.message);
    });
  }

  show() {

    const editor = atom.workspace.getActiveTextEditor();

    if (!editor) {

      return;
    }

    const marker = editor.getLastCursor && editor.getLastCursor().getMarker();

    if (!marker) {

      return;
    }

    this.overlayDecoration = editor.decorateMarker(marker, {

      type: 'overlay',
      item: this.view,
      class: 'atom-ternjs-documentation',
      position: 'tale',
      invalidate: 'touch'
    });
  }

  destroyOverlay() {

    if (this.overlayDecoration) {

      this.overlayDecoration.destroy();
    }

    this.overlayDecoration = null;
  }

  destroy() {

    disposeAll(this.disposables);

    this.destroyOverlay();

    if (this.view) {

      this.view.destroy();
      this.view = undefined;
    }
  }
}

export default new Documentation();
