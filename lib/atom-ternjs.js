'use babel';

import manager from './atom-ternjs-manager';

let Provider = require('./atom-ternjs-provider');

class AtomTernjs {

  constructor() {

    this.provider = undefined;
    this.config = require('./config.json');
  }

  activate() {

    this.provider = new Provider();
    manager.init(this.provider);
  }

  deactivate() {

    manager.destroy();
    this.provider = undefined;
  }

  provide() {

    return this.provider;
  }
}

export default new AtomTernjs();
