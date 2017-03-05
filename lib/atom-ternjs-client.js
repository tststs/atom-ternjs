'use babel';

import path from 'path';
import manager from './atom-ternjs-manager';
import packageConfig from './atom-ternjs-package-config';
import {
  openFileAndGoTo
} from './atom-ternjs-helper';
import navigation from './services/navigation';
import {messages} from './services/debug';

export default class Client {

  constructor(projectDir) {

    this.projectDir = projectDir;
    // collection files the server currently holds in its set of analyzed files
    this.analyzedFiles = [];
  }

  completions(file, end) {

    return this.post('query', {

      query: {

        type: 'completions',
        file: path.normalize(file),
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
        file: path.normalize(file),
        end: end
      }
    });
  }

  refs(file, end) {

    return this.post('query', {

      query: {

        type: 'refs',
        file: path.normalize(file),
        end: end
      }
    });
  }

  updateFull(editor) {

    return this.post('query', { files: [{

      type: 'full',
      name: path.normalize(atom.project.relativizePath(editor.getURI())[1]),
      text: editor.getText()
    }]});
  }

  updatePart(editor, start, text) {

    return this.post('query', [{

      type: 'full',
      name: path.normalize(atom.project.relativizePath(editor.getURI())[1]),
      offset: {

        line: start,
        ch: 0
      },
      text: editor.getText()
    }]);
  }

  update(editor) {

    const buffer = editor.getBuffer();

    if (!buffer.isModified()) {
      
      return Promise.resolve({});
    }

    const uRI = editor.getURI();

    if (!uRI) {

      return Promise.reject({type: 'info', message: messages.noURI});
    }

    const file = path.normalize(atom.project.relativizePath(uRI)[1]);

    // check if this file is excluded via dontLoad
    if (
      manager.server &&
      manager.server.dontLoad(file)
    ) {

      return Promise.resolve({});
    }

    // do not request files if we already know it is registered
    if (this.analyzedFiles.includes(file)) {

      return this.updateFull(editor);
    }

    // check if the file is registered, else return
    return this.files().then((data) => {

      const files = data.files;

      if (files) {

        files.forEach(file => file = path.normalize(file));
        this.analyzedFiles = files;
      }

      const registered = files && files.includes(file);

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
        //   promise = this.updatePart(editor, start, text)
        // else
        return this.updateFull(editor);

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
        file: path.normalize(file),
        end: end,
        newName: newName
      }
    });
  }

  type(editor, position) {

    const file = path.normalize(atom.project.relativizePath(editor.getURI())[1]);
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
    const [project, file] = atom.project.relativizePath(editor.getURI());
    const end = {

      line: position.row,
      ch: position.column
    };

    return this.post('query', {

      query: {

        type: 'definition',
        file: path.normalize(file),
        end: end
      }

    }).then((data) => {

      if (data && data.start) {

        if (navigation.set(data)) {

          const path_to_go = path.isAbsolute(data.file) ? data.file : `${project}/${data.file}`;
          openFileAndGoTo(data.start, path_to_go);
        }
      }
    }).catch((err) => {

      console.error(err);
    });
  }

  getDefinition(file, range) {
    return this.post('query', {
      query: {
        type: 'definition',
        file: path.normalize(file),
        start: {
          line: range.start.row,
          ch: range.start.column
        },
        end: {
          line: range.end.row,
          ch: range.end.column
        }
      }
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
