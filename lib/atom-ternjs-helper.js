'use babel';

import manager from './atom-ternjs-manager';
import packageConfig from './atom-ternjs-package-config';
import path from 'path';
import fs from 'fs';

let checkpointsDefinition = [];

const tags = {

  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;'
};

export const accessKey = 'altKey';

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

export function formatType(data) {

  if (!data.type) {

    return '';
  }

  data.type = data.type.replace(/->/g, ':').replace('<top>', 'window');

  if (!data.exprName) {

    return data.type;
  }

  data.type = data.type.replace(/^fn/, data.exprName);

  return data.type;
}

export function prepareType(data) {

  if (!data.type) {

    return;
  }

  return data.type.replace(/->/g, ':').replace('<top>', 'window');
}

export function prepareInlineDocs(data) {

  return data
    .replace(/@param/, '<span class="doc-param-first">@param</span>')
    .replace(/@param/g, '<span class="storage type doc-param">@param</span>')
    .replace(/@return/, '<span class="storage type doc-return">@return</span>')
    ;
}

export function buildDisplayText(params, name) {

  if (params.length === 0) {

    return `${name}()`;
  }

  let suggestionParams = params.map((param) => {

    param = param.replace('}', '\\}');
    param = param.replace(/'"/g, '');

    return param;
  });

  return `${name}(${suggestionParams.join(',')})`;
}

export function buildSnippet(params, name) {

  if (params.length === 0) {

    return `${name}()`;
  }

  let suggestionParams = params.map((param, i) => {

    param = param.replace('}', '\\}');

    return `\${${i + 1}:${param}}`;
  });

  return `${name}(${suggestionParams.join(',')})`;
}

export function extractParams(type) {

  if (!type) {

    return [];
  }

  let start = type.indexOf('(') + 1;
  let params = [];
  let inside = 0;

  for (let i = start; i < type.length; i++) {

    if (type[i] === ':' && inside === -1) {

      params.push(type.substring(start, i - 2));

      break;
    }

    if (i === type.length - 1) {

      const param = type.substring(start, i);

      if (param.length) {

        params.push(param);
      }

      break;
    }

    if (type[i] === ',' && inside === 0) {

      params.push(type.substring(start, i));
      start = i + 1;

      continue;
    }

    if (type[i].match(/[{\[\(]/)) {

      inside++;

      continue;
    }

    if (type[i].match(/[}\]\)]/)) {

      inside--;
    }
  }

  return params;
}

export function formatTypeCompletion(obj, isProperty, isObjectKey, isInFunDef) {

  if (obj.isKeyword) {

    obj._typeSelf = 'keyword';
  }

  if (obj.type === 'string') {

    obj.name = obj.name ? obj.name.replace(/(^"|"$)/g, '') : null;

  } else {

    obj.name = obj.name ? obj.name.replace(/["']/g, '') : null;
    obj.name = obj.name ? obj.name.replace(/^..\//, '') : null;
  }

  if (!obj.type) {

    obj._displayText = obj.name;
    obj._snippet = obj.name;

    return obj;
  }

  if (!obj.type.startsWith('fn')) {

    if (isProperty) {

      obj._typeSelf = 'property';

    } else {

      obj._typeSelf = 'variable';
    }
  }

  obj.type = obj.rightLabel = prepareType(obj);

  if (obj.type.replace(/fn\(.+\)/, '').length === 0) {

    obj.leftLabel = '';

  } else {

    if (obj.type.indexOf('fn') === -1) {

      obj.leftLabel = obj.type;

    } else {

      obj.leftLabel = obj.type.replace(/fn\(.{0,}\)/, '').replace(' : ', '');
    }
  }

  if (obj.rightLabel.startsWith('fn')) {

    let params = extractParams(obj.rightLabel);

    if (
      packageConfig.options.useSnippets ||
      packageConfig.options.useSnippetsAndFunction
    ) {

      if (!isInFunDef) {

        obj._snippet = buildSnippet(params, obj.name);
      }

      obj._hasParams = params.length ? true : false;

    } else {

      if (!isInFunDef) {

        obj._snippet = params.length ? `${obj.name}(\${${0}:\${}})` : `${obj.name}()`;
      }

      obj._displayText = buildDisplayText(params, obj.name);
    }

    obj._typeSelf = 'function';
  }

  if (obj.name) {

    if (obj.leftLabel === obj.name) {

      obj.leftLabel = null;
      obj.rightLabel = null;
    }
  }

  if (obj.leftLabel === obj.rightLabel) {

    obj.rightLabel = null;
  }

  return obj;
}

export function disposeAll(disposables) {

  for (const disposable of disposables) {

    if (!disposable) {

      continue;
    }

    disposable.dispose();
  }
}

export function openFileAndGoToPosition(position, file) {

  atom.workspace.open(file).then((textEditor) => {

    const cursor = textEditor.getLastCursor();

    if (!cursor) {

      return;
    }

    cursor.setBufferPosition(position);
  });
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

export function updateTernFile(content, restartServer) {

  const projectRoot = manager.server && manager.server.projectDir;

  if (!projectRoot) {

    return;
  }

  writeFile(path.resolve(__dirname, projectRoot + '/.tern-project'), content, restartServer);
}

export function writeFile(filePath, content, restartServer) {

  fs.writeFile(filePath, content, (error) => {

    atom.workspace.open(filePath);

    if (!error && restartServer) {

      manager.restartServer();
    }

    if (!error) {

      return;
    }

    const message = 'Could not create/update .tern-project file. Use the README to manually create a .tern-project file.';

    atom.notifications.addInfo(message, {

      dismissable: true
    });
  });
}

export function isDirectory(dir) {

  try {

    return fs.statSync(dir).isDirectory();

  } catch (error) {

    return false;
  }
}

export function fileExists(path) {

  try {

    fs.accessSync(path, fs.F_OK, (error) => {

      console.error(error);
    });

  } catch (error) {

    return false;
  }
}

export function getFileContent(filePath, root) {

  const _filePath = root + filePath;
  const resolvedPath = path.resolve(__dirname, _filePath);

  if (fileExists(resolvedPath) !== undefined) {

    return false;
  }

  return readFile(resolvedPath);
}

export function readFile(path) {

  return fs.readFileSync(path, 'utf8');
}

export function setMarkerCheckpoint() {

  const editor = atom.workspace.getActiveTextEditor();
  const buffer = editor.getBuffer();
  const cursor = editor.getLastCursor();

  if (!cursor) {

    return;
  }

  const marker = buffer.markPosition(cursor.getBufferPosition(), {});

  checkpointsDefinition.push({

    marker: marker,
    editor: editor
  });
}

export function markerCheckpointBack() {

  if (!checkpointsDefinition.length) {

    return;
  }

  const checkpoint = checkpointsDefinition.pop();

  openFileAndGoToPosition(checkpoint.marker.getRange().start, checkpoint.editor.getURI());
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
