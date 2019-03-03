'use babel';

import defaulConfig from './config';
import provider from './atom-ternjs-provider';
import manager from './atom-ternjs-manager';
import hyperclick from './atom-ternjs-hyperclick-provider';
import { CompositeDisposable } from 'atom';

class AtomTernjs {

  constructor() {

    this.config = defaulConfig;
  }

  activate() {

    this.subscriptions = new CompositeDisposable();

    this.subscriptions.add(
      atom.packages.onDidActivateInitialPackages(function() {

        if (!atom.inSpecMode()) {

          require('atom-package-deps').install('atom-ternjs', true);
        }
      })
    );

    manager.activate();
  }

  deactivate() {

    manager.destroy();
    this.subscriptions.dispose();
  }

  provide() {

    return provider;
  }

  provideHyperclick() {

    return hyperclick;
  }
}

export default new AtomTernjs();
