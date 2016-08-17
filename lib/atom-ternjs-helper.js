'use babel';

const tags = {

  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;'
};

export function focusEditor() {

  const editor = atom.workspace.getActiveTextEditor();

  if (!editor) {

    return;
  }

  const view = atom.views.getView(editor);

  view && view.focus && view.focus();
}

export function replaceTag(tag) {

  return tags[tag];
}

export function replaceTags(str) {

  if (!str) {

    return '';
  }

  return str.replace(/[&<>]/g, replaceTag);
}

export function disposeAll(disposables) {

  for (const disposable of disposables) {

    if (!disposable) {

      continue;
    }

    disposable.dispose();
  }
}

export function openFileAndGoTo(start, file) {

  atom.workspace.open(file).then((textEditor) => {

    const buffer = textEditor.getBuffer();
    const cursor = textEditor.getLastCursor();

    if (
      !buffer ||
      !cursor
    ) {

      return;
    }

    cursor.setBufferPosition(buffer.positionForCharacterIndex(start));
    markDefinitionBufferRange(cursor, textEditor);
  });
}

export function markDefinitionBufferRange(cursor, editor) {

  const range = cursor.getCurrentWordBufferRange();
  const marker = editor.markBufferRange(range, {invalidate: 'touch'});

  const decoration = editor.decorateMarker(marker, {

    type: 'highlight',
    class: 'atom-ternjs-definition-marker',
    invalidate: 'touch'
  });

  if (!decoration) {

    return;
  }

  setTimeout(() => {

    decoration.setProperties({

      type: 'highlight',
      class: 'atom-ternjs-definition-marker active',
      invalidate: 'touch'
    });

  }, 1);

  setTimeout(() => {

    decoration.setProperties({

      type: 'highlight',
      class: 'atom-ternjs-definition-marker',
      invalidate: 'touch'
    });

  }, 1501);

  setTimeout(() => {

    marker.destroy();

  }, 2500);
}
