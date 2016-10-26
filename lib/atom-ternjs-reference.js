'use babel';

const ReferenceView = require('./atom-ternjs-reference-view');

import manager from './atom-ternjs-manager';
import emitter from './atom-ternjs-events';
import fs from 'fs';
import {uniq} from 'underscore-plus';
import path from 'path';
import {TextBuffer} from 'atom';
import {
  openFileAndGoTo,
  focusEditor
} from './atom-ternjs-helper';

class Reference {

  constructor() {

    this.disposables = [];
    this.references = [];

    this.referenceView = new ReferenceView();
    this.referenceView.initialize(this);

    this.referencePanel = atom.workspace.addBottomPanel({

      item: this.referenceView,
      priority: 0
    });

    this.referencePanel.hide();

    atom.views.getView(this.referencePanel).classList.add('atom-ternjs-reference-panel', 'panel-bottom');

    this.hideHandler = this.hide.bind(this);
    emitter.on('reference-hide', this.hideHandler);

    this.registerCommands();
  }

  registerCommands() {

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:references', this.findReference.bind(this)));
  }

  goToReference(idx) {

    const ref = this.references.refs[idx];

    openFileAndGoTo(ref.start, ref.file);
  }

  findReference() {

    const editor = atom.workspace.getActiveTextEditor();
    const cursor = editor.getLastCursor();

    if (
      !manager.client ||
      !editor ||
      !cursor
    ) {

      return;
    }

    const position = cursor.getBufferPosition();

    manager.client.update(editor).then((data) => {
      manager.client.refs(atom.project.relativizePath(editor.getURI())[1], {line: position.row, ch: position.column}).then((data) => {

        if (!data) {

          atom.notifications.addInfo('No references found.', { dismissable: false });

          return;
        }

        this.references = data;

        for (let reference of data.refs) {

          reference.file = reference.file.replace(/^.\//, '');
          reference.file = path.resolve(atom.project.relativizePath(manager.server.projectDir)[0], reference.file);
        }

        data.refs = uniq(data.refs, (item) => {

          return JSON.stringify(item);
        });

        data = this.gatherMeta(data);
        this.referenceView.buildItems(data);
        this.referencePanel.show();
      });
    });
  }

  gatherMeta(data) {

    for (let item of data.refs) {

      const content = fs.readFileSync(item.file, 'utf8');
      const buffer = new TextBuffer({ text: content });

      item.position = buffer.positionForCharacterIndex(item.start);
      item.lineText = buffer.lineForRow(item.position.row);

      buffer.destroy();
    }

    return data;
  }

  hide() {

    if (
      !this.referencePanel ||
      !this.referencePanel.visible
    ) {

      return;
    }

    this.referencePanel.hide();

    focusEditor();
  }

  show() {

    this.referencePanel.show();
  }

  destroy() {

    this.referenceView && this.referenceView.destroy();
    this.referenceView = null;

    this.referencePanel && this.referencePanel.destroy();
    this.referencePanel = null;
  }
}

export default new Reference();
