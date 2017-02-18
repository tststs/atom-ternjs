'use babel';

import url from 'url';

import ConfigModel from './models/config';
import {createView} from './views/config';

import {
  disposeAll
} from './atom-ternjs-helper';

import manager from './atom-ternjs-manager';

class Config {

  constructor() {

    this.disposables = [];
  }

  init() {

    this.disposables.push(

      atom.views.addViewProvider(ConfigModel, createView),
      atom.workspace.addOpener(this.opener.bind(this)),
      atom.commands.add('atom-workspace', 'atom-ternjs:openConfig', this.requestPane.bind(this))
    );
  }

  opener(uri) {

    const projectDir = manager.server && manager.server.projectDir;
    const {protocol, host} = url.parse(uri);

    if (
      protocol !== 'atom-ternjs:' ||
      host !== 'config'
    ) {

      return undefined;
    }

    const model = new ConfigModel();

    model.setProjectDir(projectDir);
    model.setURI(uri);

    return model;
  }

  requestPane() {

    const projectDir = manager.server && manager.server.projectDir;

    if (!projectDir) {

      atom.notifications.addError('There is no active server');

      return;
    }

    const uri = 'atom-ternjs:' + '//config/' + projectDir;
    const previousPane = atom.workspace.paneForURI(uri);

    if (previousPane) {

      previousPane.activate();

      return;
    }

    atom.workspace.open('atom-ternjs:' + '//config/' + projectDir, {

      searchAllPanes: true,
      split: 'right'

    }).then((model) => {

      // console.log(model);
    });
  }

  destroy() {

    disposeAll(this.disposables);
    this.disposables = [];
  }
}

export default new Config();
