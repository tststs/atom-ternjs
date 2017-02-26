'use babel';

const TypeView = require('./atom-ternjs-type-view');
const TOLERANCE = 20;

import manager from './atom-ternjs-manager';
import packageConfig from './atom-ternjs-package-config';
import emitter from './atom-ternjs-events';
import {Range} from 'atom';
import {
  prepareType,
  prepareInlineDocs,
  extractParams,
  formatType
} from './atom-ternjs-helper';

import {deepClone} from 'underscore-plus';

class Type {

  constructor() {

    this.view = null;
    this.overlayDecoration = null;

    this.currentRange = null;
    this.currentViewData = null;

    this.destroyOverlayListener = this.destroyOverlay.bind(this);
  }

  init() {

    this.view = new TypeView();
    this.view.initialize(this);

    atom.views.getView(atom.workspace).appendChild(this.view);

    emitter.on('type-destroy-overlay', this.destroyOverlayListener);
  }

  setPosition() {

    if (this.overlayDecoration) {

      return;
    }

    const editor = atom.workspace.getActiveTextEditor();

    if (!editor) {

      return;
    }

    const marker = editor.getLastCursor().getMarker();

    if (!marker) {

      return;
    }

    this.overlayDecoration = editor.decorateMarker(marker, {

      type: 'overlay',
      item: this.view,
      class: 'atom-ternjs-type',
      position: 'tale',
      invalidate: 'touch'
    });
  }

  queryType(editor, e) {

    let rowStart = 0;
    let rangeBefore = false;
    let tmp = false;
    let may = 0;
    let may2 = 0;
    let skipCounter = 0;
    let skipCounter2 = 0;
    let paramPosition = 0;
    const position = e.newBufferPosition;
    const buffer = editor.getBuffer();

    if (position.row - TOLERANCE < 0) {

      rowStart = 0;

    } else {

      rowStart = position.row - TOLERANCE;
    }

    buffer.backwardsScanInRange(/\]|\[|\(|\)|\,|\{|\}/g, new Range([rowStart, 0], [position.row, position.column]), (obj) => {

      if (obj.matchText === '}') {

        may++;
        return;
      }

      if (obj.matchText === ']') {

        if (!tmp) {

          skipCounter2++;
        }

        may2++;
        return;
      }

      if (obj.matchText === '{') {

        if (!may) {

          rangeBefore = false;
          obj.stop();

          return;
        }

        may--;
        return;
      }

      if (obj.matchText === '[') {

        if (skipCounter2) {

          skipCounter2--;
        }

        if (!may2) {

          rangeBefore = false;
          obj.stop();
          return;
        }

        may2--;
        return;
      }

      if (obj.matchText === ')' && !tmp) {

        skipCounter++;
        return;
      }

      if (obj.matchText === ',' && !skipCounter && !skipCounter2 && !may && !may2) {

        paramPosition++;
        return;
      }

      if (obj.matchText === ',') {

        return;
      }

      if (obj.matchText === '(' && skipCounter) {

        skipCounter--;
        return;
      }

      if (skipCounter || skipCounter2) {

        return;
      }

      if (obj.matchText === '(' && !tmp) {

        rangeBefore = obj.range;
        obj.stop();

        return;
      }

      tmp = obj.matchText;
    });

    if (!rangeBefore) {

      this.currentViewData = null;
      this.currentRange = null;
      this.destroyOverlay();

      return;
    }

    if (rangeBefore.isEqual(this.currentRange)) {

      this.currentViewData && this.setViewData(this.currentViewData, paramPosition);

      return;
    }

    this.currentRange = rangeBefore;
    this.currentViewData = null;
    this.destroyOverlay();

    manager.client.update(editor).then(() => {

      manager.client.type(editor, rangeBefore.start).then((data) => {

        if (
          !data ||
          !data.type.startsWith('fn') ||
          !data.exprName
        ) {

          return;
        }

        this.currentViewData = data;

        this.setViewData(data, paramPosition);
      })
      .catch((error) => {

        // most likely the type wasn't found. ignore it.
      });
    });
  }

  setViewData(data, paramPosition) {

    const viewData = deepClone(data);
    const type = prepareType(viewData);
    const params = extractParams(type);
    formatType(viewData);

    if (params && params[paramPosition]) {

      viewData.type = viewData.type.replace(params[paramPosition], `<span class="text-info">${params[paramPosition]}</span>`);
    }

    if (
      viewData.doc &&
      packageConfig.options.inlineFnCompletionDocumentation
    ) {

      viewData.doc = viewData.doc && viewData.doc.replace(/(?:\r\n|\r|\n)/g, '<br />');
      viewData.doc = prepareInlineDocs(viewData.doc);

      this.view.setData(viewData.type, viewData.doc);

    } else {

      this.view.setData(viewData.type);
    }

    this.setPosition();
  }

  destroyOverlay() {

    if (this.overlayDecoration) {

      this.overlayDecoration.destroy();
    }

    this.overlayDecoration = null;
  }

  destroy() {

    emitter.off('destroy-type-overlay', this.destroyOverlayListener);

    this.destroyOverlay();

    if (this.view) {

      this.view.destroy();
      this.view = null;
    }
  }
}

export default new Type();
