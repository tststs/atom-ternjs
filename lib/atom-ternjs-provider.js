"use babel";

let Function = require('loophole').Function;
let _ = require('underscore-plus');

const REGEXP_LINE = /(([\$\w]+[\w-]*)|([.:;'"[{( ]+))$/g;

export default class Provider {

  constructor(manager) {

    this.manager = undefined;
    this.force = false;

    // automcomplete-plus
    this.selector = '.source.js';
    this.disableForSelector = '.source.js .comment';
    this.inclusionPriority = 1;
    this.excludeLowerPriority = false;

    this.line = undefined;
    this.lineMatchResult = undefined;
    this.tempPrefix = undefined;
    this.suggestionsArr = undefined;
    this.suggestion = undefined;
    this.suggestionClone = undefined;
  }

  init(manager) {

    this.manager = manager;
    this.excludeLowerPriority = this.manager.packageConfig.options.excludeLowerPriorityProviders;

    if (this.manager.packageConfig.options.displayAboveSnippets) {

      this.suggestionPriority = 2;
    }
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

    if (prefix.match(/(\s|;|\.|\"|\')$/) || prefix.replace(/\s/g, '').length === 0) {

      return '';
    }

    return prefix;
  }

  getPrefix(editor, bufferPosition) {

    this.line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]);
    this.lineMatchResult = this.line.match(REGEXP_LINE);

    if (this.lineMatchResult) {

      return this.lineMatchResult[0];
    }
  }

  getSuggestions({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) {

    return new Promise((resolve) => {

      if (!this.manager.client) {

        return resolve([]);
      }

      this.tempPrefix = this.getPrefix(editor, bufferPosition) || prefix;

      if (!this.isValidPrefix(this.tempPrefix, this.tempPrefix[this.tempPrefix.length - 1]) && !this.force && !activatedManually) {

        return resolve([]);
      }

      prefix = this.checkPrefix(this.tempPrefix);

      this.manager.client.update(editor).then((data) => {

        if (!data) {

          return resolve([]);
        }

        this.manager.client.completions(atom.project.relativizePath(editor.getURI())[1], {

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

            obj = this.manager.helper.formatTypeCompletion(obj, isInFunDef);

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

            if (this.manager.packageConfig.options.useSnippetsAndFunction && obj._hasParams) {

              this.suggestionClone = _.clone(this.suggestion);
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
        });
      });
    });
  }

  forceCompletion() {

    this.force = true;
    atom.commands.dispatch(atom.views.getView(atom.workspace.getActiveTextEditor()), 'autocomplete-plus:activate');
    this.force = false;
  }
}
