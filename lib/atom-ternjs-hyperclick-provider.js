'use babel';

import manager from './atom-ternjs-manager';
import { openFileAndGoTo } from './atom-ternjs-helper';

class Hyperclick {
  constructor() {
    this.providerName = 'atom-ternjs-hyperclick';
    this.wordRegExp = new RegExp('(`(\\\\.|[^`\\\\])*`)|(\'(\\\\.|[^\'\\\\])*\')|("(\\\\.|[^"\\\\])*")|([a-zA-Z0-9_$]+)', 'g');
  }

  getSuggestionForWord(editor, string, range) {
    return new Promise((resolve) => {
      if (!string.trim()) {
        return resolve(null);
      }

      if (!manager.client) {
        return resolve(null);
      }

      manager.client.update(editor).then((data) => {
        if (!data) {
          return resolve(null);
        }

		const [project, file] = atom.project.relativizePath(editor.getURI());
        manager.client.getDefinition(file , range).then((data) => {
          if (!data) {
            return resolve(null);
          }

          if (data && data.file) {
            resolve({
              range: range,
              callback() {
                openFileAndGoTo(data.start, `${project}/${data.file}`);
              }
            });
          }

          resolve(null);
        }).catch(() => resolve(null));
      });
    });
  }
}

export default new Hyperclick();
