'use babel';

import defaulConfig from './config';
import provider from './atom-ternjs-provider';
import emitter from './atom-ternjs-events';
import {disposeAll} from './atom-ternjs-helper';

class PackageConfig {

  constructor() {

    this.disposables = [];
    this.defaultConfig = defaulConfig;
    this.options = this.getInitalOptions();
  }

  init() {

    this.options = this.getInitalOptions();
    this.registerListeners();
  }

  getInitalOptions() {

    return {

      excludeLowerPriority: this.get('excludeLowerPriorityProviders'),
      inlineFnCompletion: this.get('inlineFnCompletion'),
      inlineFnCompletionDocumentation: this.get('inlineFnCompletionDocumentation'),
      useSnippets: this.get('useSnippets'),
      snippetsFirst: this.get('snippetsFirst'),
      useSnippetsAndFunction: this.get('useSnippetsAndFunction'),
      sort: this.get('sort'),
      guess: this.get('guess'),
      urls: this.get('urls'),
      origins: this.get('origins'),
      caseInsensitive: this.get('caseInsensitive'),
      documentation: this.get('documentation'),
      ternServerGetFileAsync: this.get('ternServerGetFileAsync'),
      ternServerDependencyBudget: this.get('ternServerDependencyBudget')
    };
  }

  get(option) {

    const value = atom.config.get(`atom-ternjs.${option}`);

    if (value === undefined) {

      return this.defaultConfig[option].default;
    }

    return value;
  }

  registerListeners() {

    this.disposables.push(atom.config.observe('atom-ternjs.excludeLowerPriorityProviders', (value) => {

      this.options.excludeLowerPriority = value;

      if (provider) {

        provider.excludeLowerPriority = value;
      }
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.snippetsFirst', (value) => {

      if (provider) {

        provider.suggestionPriority = value ? null : 2;
      }

      this.options.snippetsFirst = value;
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.inlineFnCompletion', (value) => {

      this.options.inlineFnCompletion = value;
      emitter.emit('type-destroy-overlay');
    }));

    this.disposables.push(atom.config.observe('atom-ternjs.ternServerGetFileAsync', value => this.options.ternServerGetFileAsync = value));
    this.disposables.push(atom.config.observe('atom-ternjs.ternServerDependencyBudget', value => this.options.ternServerDependencyBudget = value));
    this.disposables.push(atom.config.observe('atom-ternjs.inlineFnCompletionDocumentation', value => this.options.inlineFnCompletionDocumentation = value));
    this.disposables.push(atom.config.observe('atom-ternjs.useSnippets', value => this.options.useSnippets = value));
    this.disposables.push(atom.config.observe('atom-ternjs.useSnippetsAndFunction', value => this.options.useSnippetsAndFunction = value));
    this.disposables.push(atom.config.observe('atom-ternjs.sort', value => this.options.sort = value));
    this.disposables.push(atom.config.observe('atom-ternjs.guess', value => this.options.guess = value));
    this.disposables.push(atom.config.observe('atom-ternjs.urls', value => this.options.urls = value));
    this.disposables.push(atom.config.observe('atom-ternjs.origins', value => this.options.origins = value));
    this.disposables.push(atom.config.observe('atom-ternjs.caseInsensitive', value => this.options.caseInsensitive = value));
    this.disposables.push(atom.config.observe('atom-ternjs.documentation', value => this.options.documentation = value));
  }

  destroy() {

    disposeAll(this.disposables);
    this.disposables = [];
  }
}

export default new PackageConfig();
