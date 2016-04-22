"use babel";

let DocumentationView = require('./atom-ternjs-documentation-view');

export default class Documentation {

  constructor(manager) {

    this.manager = manager;
    this.view = new DocumentationView();
    this.view.initialize(this);

    atom.views.getView(atom.workspace).appendChild(this.view);
  }

  request() {

    let editor = atom.workspace.getActiveTextEditor();

    if (!editor) {

      return;
    }

    let cursor = editor.getLastCursor();
    let position = cursor.getBufferPosition();

    this.manager.client.update(editor).then((data) => {

      this.manager.client.documentation(atom.project.relativizePath(editor.getURI())[1], {

        line: position.row,
        ch: position.column

      }).then((data) => {

        if (!data) {

          return;
        }

        this.view.setData({

          doc: this.manager.helper.replaceTags(data.doc),
          origin: data.origin,
          type: this.manager.helper.formatType(data),
          url: data.url || ''
        });

        this.show();
      });
    });
  }

  show() {

    if (!this.marker) {

      let editor = atom.workspace.getActiveTextEditor();
      let cursor = editor.getLastCursor();

      if (!editor || !cursor) {

        return;
      }

      this.marker = cursor.getMarker();

      if (!this.marker) {

        return;
      }

      this.overlayDecoration = editor.decorateMarker(this.marker, {

        type: 'overlay',
        item: this.view,
        class: 'atom-ternjs-documentation',
        position: 'tale',
        invalidate: 'touch'
      });

    } else {

      this.marker.setProperties({

        type: 'overlay',
        item: this.view,
        class: 'atom-ternjs-documentation',
        position: 'tale',
        invalidate: 'touch'
      });
    }
  }

  destroyOverlay() {

    if (this.overlayDecoration) {

      this.overlayDecoration.destroy();
    }

    this.overlayDecoration = null;
    this.marker = null;
  }

  destroy() {

    this.destroyOverlay();
    this.view.destroy();
    this.view = undefined;
  }
}
