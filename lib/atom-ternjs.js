'use babel';

import defaulConfig from './config';
import provider from './atom-ternjs-provider';
import manager from './atom-ternjs-manager';
import hyperclick from './atom-ternjs-hyperclick-provider';

class AtomTernjs {

  constructor() {

    this.config = defaulConfig;
  }

  activate() {

    manager.activate();
  }

  deactivate() {

    manager.destroy();
  }

  provide() {

    return provider;
  }

  provideHyperclick() {
    
    return hyperclick;
  }
}

export default new AtomTernjs();
