'use babel';

import provider from './atom-ternjs-provider';
import emitter from './atom-ternjs-events';
import {disposeAll} from './atom-ternjs-helper';

class PackageConfig {

  constructor() {

    this.disposables = [];
    this.options = {

      excludeLowerPriority: atom.config.get('atom-ternjs.excludeLowerPriorityProviders'),
      inlineFnCompletion: atom.config.get('atom-ternjs.inlineFnCompletion'),
      useSnippets: atom.config.get('atom-ternjs.useSnippets'),
      snippetsFirst: atom.config.get('atom-ternjs.snippetsFirst'),
      useSnippetsAndFunction: atom.config.get('atom-ternjs.useSnippetsAndFunction'),
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

    this.disposables.push(atom.config.observe('atom-ternjs.excludeLowerPriorityProviders', (value) => {

      this.options.excludeLowerPriority = value;

      if (provider) {

        provider.excludeLowerPriority = value;
      }
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.inlineFnCompletion', (value) => {

      this.options.inlineFnCompletion = value;
      emitter.emit('type-destroy-overlay');
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.useSnippets', (value) => {

      this.options.useSnippets = value;

      if (!value) {

        return;
      }
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.useSnippetsAndFunction', (value) => {

      this.options.useSnippetsAndFunction = value;

      if (!value) {

        return;
      }
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

  destroy() {

    disposeAll(this.disposables);
  }
}

export default new PackageConfig();
