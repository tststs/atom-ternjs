'use babel';

import manager from './atom-ternjs-manager';
import packageConfig from './atom-ternjs-package-config';
import {
  setMarkerCheckpoint,
  openFileAndGoTo
} from './atom-ternjs-helper';

export default class Client {

  constructor(projectDir) {

    this.projectDir = projectDir;
  }

  completions(file, end) {

    return this.post('query', {

      query: {

        type: 'completions',
        file: file,
        end: end,
        types: true,
        includeKeywords: true,
        sort: packageConfig.options.sort,
        guess: packageConfig.options.guess,
        docs: packageConfig.options.documentation,
        urls: packageConfig.options.urls,
        origins: packageConfig.options.origins,
        lineCharPositions: true,
        caseInsensitive: packageConfig.options.caseInsensitive
      }
    });
  }

  documentation(file, end) {

    return this.post('query', {

      query: {

        type: 'documentation',
        file: file,
        end: end
      }
    });
  }

  refs(file, end) {

    return this.post('query', {

      query: {

        type: 'refs',
        file: file,
        end: end
      }
    });
  }

  updateFull(editor, editorMeta) {

    if (editorMeta) {

      editorMeta.diffs = [];
    }

    return this.post('query', { files: [{

      type: 'full',
      name: atom.project.relativizePath(editor.getURI())[1],
      text: editor.getText()
    }]});
  }

  updatePart(editor, editorMeta, start, text) {

    if (editorMeta) {

      editorMeta.diffs = [];
    }

    return this.post('query', [{

      type: 'full',
      name: atom.project.relativizePath(editor.getURI())[1],
      offset: {

        line: start,
        ch: 0
      },
      text: editor.getText()
    }]);
  }

  update(editor) {

    const editorMeta = manager.getEditor(editor);
    const file = atom.project.relativizePath(editor.getURI())[1].replace(/\\/g, '/');

    // check if this file is excluded via dontLoad
    if (
      manager.server &&
      manager.server.dontLoad(file)
    ) {

      return Promise.resolve({});
    }

    // check if the file is registered, else return
    return this.files().then((data) => {

      if (data.files) {

        for (let i = 0; i < data.files.length; i++) {

          data.files[i] = data.files[i].replace(/\\/g, '/');
        }
      }

      const registered = data.files && data.files.indexOf(file) > -1;

      if (
        editorMeta &&
        editorMeta.diffs.length === 0 &&
        registered
      ) {

        return Promise.resolve({});
      }

      if (registered) {

        // const buffer = editor.getBuffer();
        // if buffer.getMaxCharacterIndex() > 5000
        //   start = 0
        //   end = 0
        //   text = ''
        //   for diff in editorMeta.diffs
        //     start = Math.max(0, diff.oldRange.start.row - 50)
        //     end = Math.min(buffer.getLineCount(), diff.oldRange.end.row + 5)
        //     text = buffer.getTextInRange([[start, 0], [end, buffer.lineLengthForRow(end)]])
        //   promise = this.updatePart(editor, editorMeta, start, text)
        // else
        return this.updateFull(editor, editorMeta);

      } else {

        return Promise.resolve({});
      }
    }).catch((err) => {

      console.error(err);
    });
  }

  rename(file, end, newName) {

    return this.post('query', {

      query: {

        type: 'rename',
        file: file,
        end: end,
        newName: newName
      }
    });
  }

  type(editor, position) {

    const file = atom.project.relativizePath(editor.getURI())[1];
    const end = {

      line: position.row,
      ch: position.column
    };

    return this.post('query', {

      query: {

        type: 'type',
        file: file,
        end: end,
        preferFunction: true
      }
    });
  }

  definition() {

    const editor = atom.workspace.getActiveTextEditor();
    const cursor = editor.getLastCursor();
    const position = cursor.getBufferPosition();
    const file = atom.project.relativizePath(editor.getURI())[1];
    const end = {

      line: position.row,
      ch: position.column
    };

    return this.post('query', {

      query: {

        type: 'definition',
        file: file,
        end: end
      }

    }).then((data) => {

      if (data && data.start) {

        setMarkerCheckpoint();
        openFileAndGoTo(data.start, data.file);
      }
    }).catch((err) => {

      console.error(err);
    });
  }

  files() {

    return this.post('query', {

      query: {

        type: 'files'
      }

    }).then((data) => {

      return data;
    });
  }

  post(type, data) {

    const promise = manager.server.request(type, data);

    return promise;
  }
}
