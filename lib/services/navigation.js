'use babel';

import {
  openFileAndGoToPosition
} from '../atom-ternjs-helper';

let index = 0;
let checkpoints = [];

function set(data) {

  checkpoints.length = 0;

  const editor = atom.workspace.getActiveTextEditor();
  const buffer = editor.getBuffer();
  const cursor = editor.getLastCursor();

  if (!cursor) {

    return false;
  }

  const marker = buffer.markPosition(cursor.getBufferPosition(), {});

  add(editor, marker);

  return true;
}

function append(editor, buffer, position) {

  const marker = buffer.markPosition(position, {});

  add(editor, marker);
}

function add(editor, marker) {

  index = checkpoints.push({

    marker: marker,
    editor: editor

  }) - 1;
}

function goTo(value) {

  const checkpoint = checkpoints[index + value];

  if (!checkpoint) {

    return;
  }

  index += value;

  openFileAndGoToPosition(checkpoint.marker.getRange().start, checkpoint.editor.getURI());
}

function reset() {

  index = 0;
  checkpoints = [];
}

export default {

  set,
  append,
  goTo,
  reset
};
