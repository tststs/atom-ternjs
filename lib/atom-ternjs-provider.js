"use babel";

let Function = require('loophole').Function;
let _ = require('underscore-plus');

export default class Provider {

  constructor(manager) {

    this.manager = undefined;
    this.force = false;
    // automcomplete-plus
    this.selector = '.source.js';
    this.disableForSelector = '.source.js .comment';
    this.inclusionPriority = 1;
    this.excludeLowerPriority = false;
  }

  init(manager) {

    this.manager = manager;
    this.excludeLowerPriority = this.manager.packageConfig.options.excludeLowerPriorityProviders;

    if (this.manager.packageConfig.options.displayAboveSnippets) {

      this.suggestionPriority = 2;
    }
  }

  isValidPrefix(prefix) {

    if (prefix[prefix.length - 1] === undefined) {

      return false;
    }

    if (prefix[prefix.length - 1].match('\.')) {

      return true;
    }

    if (prefix[prefix.length - 1].match(/;|\s/)) {

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

    let regexp = /(([\$\w]+[\w-]*)|([.:;'"[{( ]+))$/g;
    let line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]);
    let result;

    if (result = line.match(regexp)) {

      return result[0];
    }
  }

  getSuggestions({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) {

    if (!this.manager.client) {

      return [];
    }

    let tempPrefix = this.getPrefix(editor, bufferPosition) || prefix;

    if (!this.isValidPrefix(tempPrefix) && !this.force && !activatedManually) {

      return [];
    }

    prefix = this.checkPrefix(tempPrefix);

    return new Promise((resolve) => {

      this.manager.client.update(editor.getURI(), editor.getText()).then(() => {

        this.manager.client.completions(editor.getURI(), {

          line: bufferPosition.row,
          ch: bufferPosition.column

        }).then((data) => {

          if (!data.completions.length) {

            resolve([]);
            return;
          }

          let suggestionsArr = [];

          for (let obj of data.completions) {

            obj = this.manager.helper.formatTypeCompletion(obj);
            let description = obj.doc || null;
            let url = obj.url || null;

            suggestion = {

              text: obj.name,
              replacementPrefix: prefix,
              className: null,
              type: obj._typeSelf,
              leftLabel: obj.leftLabel,
              snippet: obj._snippet,
              description: description,
              descriptionMoreURL: url
            };

            if (this.manager.packageConfig.options.useSnippetsAndFunction && obj._hasParams) {

              suggestionClone = _.clone(suggestion);
              suggestionClone.type = 'snippet';

              if (obj._hasParams) {

                suggestion.snippet = `${obj.name}($\{0:\})`;

              } else {

                suggestion.snippet = `${obj.name}()`;
              }

              suggestionsArr.push(suggestion);
              suggestionsArr.push(suggestionClone);

            } else {

              suggestionsArr.push(suggestion);
            }
          }

          resolve(suggestionsArr);
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
