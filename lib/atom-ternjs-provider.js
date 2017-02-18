'use babel';

const Function = require('loophole').Function;
const REGEXP_LINE = /(([\$\w]+[\w-]*)|([.:;'"[{( ]+))$/g;

import manager from './atom-ternjs-manager';
import packageConfig from './atom-ternjs-package-config';
import {
  disposeAll,
  formatTypeCompletion
} from './atom-ternjs-helper';
import {
  clone
} from 'underscore-plus';

class Provider {

  constructor() {

    this.disposables = [];

    this.force = false;

    // automcomplete-plus
    this.selector = '.source.js';
    this.disableForSelector = '.source.js .comment';
    this.inclusionPriority = 1;
    this.suggestionPriority = packageConfig.options.snippetsFirst ? null : 2;
    this.excludeLowerPriority = packageConfig.options.excludeLowerPriorityProviders;

    this.suggestionsArr = null;
    this.suggestion = null;
    this.suggestionClone = null;
  }

  init() {

    this.registerCommands();
  }

  registerCommands() {

    this.disposables.push(atom.commands.add('atom-text-editor', 'atom-ternjs:startCompletion', this.forceCompletion.bind(this)));
  }

  isValidPrefix(prefix, prefixLast) {

    if (prefixLast === undefined) {

      return false;
    }

    if (prefixLast === '\.') {

      return true;
    }

    if (prefixLast.match(/;|\s/)) {

      return false;
    }

    if (prefix.length > 1) {

      prefix = `_${prefix}`;
    }

    try {

      (new Function(`var ${prefix}`))();

    } catch (e) {

      return false;
    }

    return true;
  }

  checkPrefix(prefix) {

    if (
      /(\(|\s|;|\.|\"|\')$/.test(prefix) ||
      prefix.replace(/\s/g, '').length === 0
    ) {

      return '';
    }

    return prefix;
  }

  getPrefix(editor, bufferPosition) {

    const line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]);
    const matches = line.match(REGEXP_LINE);

    return matches && matches[0];
  }

  getSuggestions({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) {

    if (!manager.client) {

      return [];
    }

    const tempPrefix = this.getPrefix(editor, bufferPosition) || prefix;

    if (!this.isValidPrefix(tempPrefix, tempPrefix[tempPrefix.length - 1]) && !this.force && !activatedManually) {

      return [];
    }

    return new Promise((resolve) => {

      prefix = this.checkPrefix(tempPrefix);

      manager.client.update(editor).then((data) => {

        if (!data) {

          return resolve([]);
        }

        manager.client.completions(atom.project.relativizePath(editor.getURI())[1], {

          line: bufferPosition.row,
          ch: bufferPosition.column

        }).then((data) => {

          if (!data) {

            return resolve([]);
          }

          if (!data.completions.length) {

            return resolve([]);
          }

          this.suggestionsArr = [];

          let scopesPath = scopeDescriptor.getScopesArray();
          let isInFunDef = scopesPath.indexOf('meta.function.js') > -1;

          for (let obj of data.completions) {

            obj = formatTypeCompletion(obj, data.isProperty, data.isObjectKey, isInFunDef);

            this.suggestion = {

              text: obj.name,
              replacementPrefix: prefix,
              className: null,
              type: obj._typeSelf,
              leftLabel: obj.leftLabel,
              snippet: obj._snippet,
              displayText: obj._displayText,
              description: obj.doc || null,
              descriptionMoreURL: obj.url || null
            };

            if (packageConfig.options.useSnippetsAndFunction && obj._hasParams) {

              this.suggestionClone = clone(this.suggestion);
              this.suggestionClone.type = 'snippet';

              if (obj._hasParams) {

                this.suggestion.snippet = `${obj.name}($\{0:\})`;

              } else {

                this.suggestion.snippet = `${obj.name}()`;
              }

              this.suggestionsArr.push(this.suggestion);
              this.suggestionsArr.push(this.suggestionClone);

            } else {

              this.suggestionsArr.push(this.suggestion);
            }
          }

          resolve(this.suggestionsArr);

        }).catch((err) => {

          console.error(err);
          resolve([]);
        });
      })
      .catch(() => {

        resolve([]);
      });
    });
  }

  forceCompletion() {

    this.force = true;
    atom.commands.dispatch(atom.views.getView(atom.workspace.getActiveTextEditor()), 'autocomplete-plus:activate');
    this.force = false;
  }

  destroy() {

    disposeAll(this.disposables);
    this.disposables = [];
  }
}

export default new Provider();
