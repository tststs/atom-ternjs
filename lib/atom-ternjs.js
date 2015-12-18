"use babel";

let Manager = require('./atom-ternjs-manager');
let Provider = require('./atom-ternjs-provider');
let LinterTern;

class AtomTernjs {

  constructor() {

    this.manager = undefined;
    this.provider = undefined;
    this.useLint = undefined;
    this.providerLinter = undefined;

    this.config = require('./config.json');
  }

  activate() {

    this.provider = new Provider();
    this.manager = new Manager(this.provider);
    this.useLint = atom.config.get('atom-ternjs.lint');

    if (!this.useLint) {

      return;
    }

    LinterTern = require('./linter');
    this.providerLinter = new LinterTern(this.manager);
  }

  deactivate() {

    this.manager.destroy();
    this.manager = undefined;
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
