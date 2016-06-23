'use babel';

import manager from './atom-ternjs-manager';

let Provider = require('./atom-ternjs-provider');
let LinterTern;

class AtomTernjs {

  constructor() {

    this.provider = undefined;
    this.useLint = undefined;
    this.providerLinter = undefined;

    this.config = require('./config.json');
  }

  activate() {

    this.provider = new Provider();
    manager.init(this.provider);
    this.useLint = atom.config.get('atom-ternjs.lint');

    if (!this.useLint) {

      return;
    }

    LinterTern = require('./linter');
    this.providerLinter = new LinterTern(manager);
  }

  deactivate() {

    manager.destroy();
    this.provider = undefined;
    this.useLint = undefined;
    this.providerLinter = undefined;
  }

  provide() {

    return this.provider;
  }

  provideLinter() {

    if (!this.useLint) {

      return;
    }

    return this.providerLinter;
  }
}

export default new AtomTernjs();
