'use babel';

export default class PluginManager {

  constructor(manager) {

    this.manager = manager;
    this.availablePlugins = require('../config/tern-plugins.json');
  }
}
