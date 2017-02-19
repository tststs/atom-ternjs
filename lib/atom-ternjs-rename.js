'use babel';

const RenameView = require('./atom-ternjs-rename-view');

import emitter from './atom-ternjs-events';
import manager from './atom-ternjs-manager';
import {
  Point,
  Range
} from 'atom';
import {uniq} from 'underscore-plus';
import path from 'path';
import {
  disposeAll,
  focusEditor,
  isValidEditor
} from './atom-ternjs-helper';
import debug from './services/debug';

class Rename {

  constructor() {

    this.disposables = [];

    this.renameView = null;
    this.renamePanel = null;

    this.hideListener = this.hide.bind(this);
  }

  init() {

    this.renameView = new RenameView();
    this.renameView.initialize(this);

    this.renamePanel = atom.workspace.addModalPanel({

      item: this.renameView,
      priority: 0,
      visible: false
    });

    atom.views.getView(this.renamePanel).classList.add('atom-ternjs-rename-panel', 'panel-bottom');

    emitter.on('rename-hide', this.hideListener);

    this.registerCommands();
  }

  registerCommands() {

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:rename', this.show.bind(this)));
  }

  hide() {

    this.renamePanel && this.renamePanel.hide();

    focusEditor();
  }

  show() {

    const codeEditor = atom.workspace.getActiveTextEditor();
    const currentNameRange = codeEditor.getLastCursor().getCurrentWordBufferRange({includeNonWordCharacters: false});
    const currentName = codeEditor.getTextInBufferRange(currentNameRange);

    this.renameView.nameEditor.getModel().setText(currentName);
    this.renameView.nameEditor.getModel().selectAll();

    this.renamePanel.show();
    this.renameView.nameEditor.focus();
  }

  updateAllAndRename(newName) {

    if (!manager.client) {

      this.hide();

      return;
    }

    let idx = 0;
    const editors = atom.workspace.getTextEditors();

    for (const editor of editors) {

      if (
        !isValidEditor(editor) ||
        atom.project.relativizePath(editor.getURI())[0] !== manager.client.projectDir
      ) {

        idx++;

        continue;
      }

      manager.client.update(editor)
        .then((data) => {

          if (++idx === editors.length) {

            const activeEditor = atom.workspace.getActiveTextEditor();
            const cursor = activeEditor.getLastCursor();

            if (!cursor) {

              return;
            }

            const position = cursor.getBufferPosition();

            manager.client.rename(atom.project.relativizePath(activeEditor.getURI())[1], {line: position.row, ch: position.column}, newName).then((data) => {

              if (!data) {

                return;
              }

              this.rename(data);
            })
            .catch(debug.handleCatchWithNotification)
            .then(this.hideListener);
          }
        })
        .catch(debug.handleCatch)
        .then(this.hideListener);
    }
  }

  rename(data) {

    const dir = manager.server.projectDir;

    if (!dir) {

      return;
    }

    const translateColumnBy = data.changes[0].text.length - data.name.length;

    for (let change of data.changes) {

      change.file = change.file.replace(/^.\//, '');
      change.file = path.resolve(atom.project.relativizePath(dir)[0], change.file);
    }

    let changes = uniq(data.changes, (item) => {

      return JSON.stringify(item);
    });

    let currentFile = false;
    let arr = [];
    let idx = 0;

    for (const change of changes) {

      if (currentFile !== change.file) {

        currentFile = change.file;
        idx = arr.push([]) - 1;
      }

      arr[idx].push(change);
    }

    for (const arrObj of arr) {

      this.openFilesAndRename(arrObj, translateColumnBy);
    }

    this.hide();
  }

  openFilesAndRename(obj, translateColumnBy) {

    atom.workspace.open(obj[0].file).then((textEditor) => {

      let currentColumnOffset = 0;
      let idx = 0;
      const buffer = textEditor.getBuffer();
      const checkpoint = buffer.createCheckpoint();

      for (const change of obj) {

        this.setTextInRange(buffer, change, currentColumnOffset, idx === obj.length - 1, textEditor);
        currentColumnOffset += translateColumnBy;

        idx++;
      }

      buffer.groupChangesSinceCheckpoint(checkpoint);
    });
  }

  setTextInRange(buffer, change, offset, moveCursor, textEditor) {

    change.start += offset;
    change.end += offset;
    const position = buffer.positionForCharacterIndex(change.start);
    length = change.end - change.start;
    const end = position.translate(new Point(0, length));
    const range = new Range(position, end);
    buffer.setTextInRange(range, change.text);

    if (!moveCursor) {

      return;
    }

    const cursor = textEditor.getLastCursor();

    cursor && cursor.setBufferPosition(position);
  }

  destroy() {

    disposeAll(this.disposables);
    this.disposables = [];

    emitter.off('rename-hide', this.hideListener);

    this.renameView && this.renameView.destroy();
    this.renameView = null;

    this.renamePanel && this.renamePanel.destroy();
    this.renamePanel = null;
  }
}

export default new Rename();
