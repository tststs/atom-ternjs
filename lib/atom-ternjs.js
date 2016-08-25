'use babel';

import defaulConfig from './config';
import provider from './atom-ternjs-provider';
import manager from './atom-ternjs-manager';

class AtomTernjs {

  constructor() {

    this.config = defaulConfig;
  }

  activate() {

    manager.init();
  }

  deactivate() {

    manager.destroy();
  }

  provide() {

    return provider;
  }
}

export default new AtomTernjs();
