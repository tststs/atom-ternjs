"use babel";

export default class PackageConfig {

  constructor(manager) {

    this.manager = manager;

    this.disposables = [];
    this.options = {

      inlineFnCompletion: atom.config.get('atom-ternjs.inlineFnCompletion'),
      useLint: atom.config.get('atom-ternjs.lint'),
      useSnippets: atom.config.get('atom-ternjs.useSnippets'),
      useSnippetsAndFunction: atom.config.get('atom-ternjs.useSnippetsAndFunction'),
      doNotAddParantheses: atom.config.get('atom-ternjs.doNotAddParantheses'),
      sort: atom.config.get('atom-ternjs.sort'),
      guess: atom.config.get('atom-ternjs.guess'),
      urls: atom.config.get('atom-ternjs.urls'),
      origins: atom.config.get('atom-ternjs.origins'),
      caseInsensitive: atom.config.get('atom-ternjs.caseInsensitive'),
      documentation: atom.config.get('atom-ternjs.documentation')
    };

    this.registerEvents();
  }

  registerEvents() {

    this.disposables.push(atom.config.observe('atom-ternjs.inlineFnCompletion', (value) => {

      this.options.inlineFnCompletion = value;

      if (this.type) {

        this.type.destroyOverlay();
      }
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.lint', (value) => {

      this.options.useLint = value;
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.useSnippets', (value) => {

      this.options.useSnippets = value;

      if (!value) {

        return;
      }

      atom.config.set('atom-ternjs.doNotAddParantheses', false);
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.useSnippetsAndFunction', (value) => {

      this.useSnippetsAndFunction = value;

      if (!value) {

        return;
      }

      atom.config.set('atom-ternjs.doNotAddParantheses', false);
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.doNotAddParantheses', (value) => {

      this.options.doNotAddParantheses = value;

      if (!value) {

        return;
      }

      atom.config.set('atom-ternjs.useSnippets', false);
      atom.config.set('atom-ternjs.useSnippetsAndFunction', false);
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.sort', (value) => {

      this.options.sort = value;
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.guess', (value) => {

      this.options.guess = value;
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.urls', (value) => {

      this.options.urls = value;
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.origins', (value) => {

      this.options.origins = value;
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.caseInsensitive', (value) => {

      this.options.caseInsensitive = value;
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.documentation', (value) => {

      this.options.documentation = value;
    }));
  }

  unregisterEvents() {

    for (let disposable of this.disposables) {

      disposable.dispose();
    }

    this.disposables = [];
  }

  destroy() {

    this.unregisterEvents();
  }
}
