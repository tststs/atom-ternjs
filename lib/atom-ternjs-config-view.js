'use babel';

import ternConfigDocs from '../config/tern-config-docs';
import pluginDefinitions from '../config/tern-plugins-defintions.js';
import manager from './atom-ternjs-manager';
import TernView from './atom-ternjs-view';

const templateContainer = `

  <div>
    <div class="container">
      <h1 class="title"></h1>
      <div class="content"></div>
      <button class="btn atom-ternjs-config-close">Save &amp; Restart Server</button>
      <button class="btn atom-ternjs-config-close">Cancel</button>
    </div>
  </div>
`;

class ConfigView extends TernView {

  createdCallback() {

    this.getModel();

    this.classList.add('atom-ternjs-config');
    this.innerHTML = templateContainer;

    this.containerElement = this.querySelector('.container');
    this.contentElement = this.querySelector('.content');
    this.titleElement = this.querySelector('.title');
    this.buttonClose = this.querySelector('.atom-ternjs-config-close:first-of-type');
    this.buttonCancel = this.querySelector('.atom-ternjs-config-close:last-of-type');
  }

  buildOptionsMarkup() {

    let projectDir = '';
    const projectConfig = this.getModel().config;

    if (manager.client) {

      projectDir = manager.client.projectDir;
    }

    this.titleElement.innerHTML = projectDir;

    this.contentElement.appendChild(this.buildRadio('ecmaVersion'));
    this.contentElement.appendChild(this.buildlibs('libs', projectConfig.libs));
    this.contentElement.appendChild(this.buildStringArray(projectConfig.loadEagerly, 'loadEagerly'));
    this.contentElement.appendChild(this.buildStringArray(projectConfig.dontLoad, 'dontLoad'));
    this.contentElement.appendChild(this.buildPlugins('plugins', projectConfig.plugins));
  }

  buildSection(sectionTitle) {

    let section = document.createElement('section');
    section.classList.add(sectionTitle);

    let header = document.createElement('h2');
    header.innerHTML = sectionTitle;

    section.appendChild(header);

    const docs = ternConfigDocs[sectionTitle].doc;

    if (docs) {

      let doc = document.createElement('p');
      doc.innerHTML = docs;

      section.appendChild(doc);
    }

    return section;
  }

  buildRadio(sectionTitle) {

    let section = this.buildSection(sectionTitle);

    for (const key of Object.keys(this.getModel().config.ecmaVersions)) {

      let inputWrapper = document.createElement('div');
      inputWrapper.classList.add('input-wrapper');

      let label = document.createElement('span');
      label.innerHTML = key;

      let radio = document.createElement('input');
      radio.type = 'radio';
      radio.name = 'ecmaVersions';
      radio.checked = this.getModel().config.ecmaVersions[key];
      radio.__ternjs_key = key;

      radio.addEventListener('change', (e) => {

        for (const key of Object.keys(this.getModel().config.ecmaVersions)) {

          this.getModel().config.ecmaVersions[key] = false;
        }

        this.getModel().config.ecmaVersions[e.target.__ternjs_key] = e.target.checked;
      }, false);

      inputWrapper.appendChild(label);
      inputWrapper.appendChild(radio);
      section.appendChild(inputWrapper);
    }

    return section;
  }

  buildStringArray(obj, sectionTitle) {

    let section = this.buildSection(sectionTitle);

    for (const path of obj) {

      section.appendChild(this.createInputWrapper(path, sectionTitle));
    }

    if (obj.length === 0) {

      section.appendChild(this.createInputWrapper(null, sectionTitle));
    }

    return section;
  }

  buildPlugins(sectionTitle, availablePlugins) {

    let section = this.buildSection(sectionTitle);

    for (const key of Object.keys(availablePlugins)) {

      let wrapper = document.createElement('p');
      wrapper.appendChild(this.buildBoolean(key, availablePlugins));
      let doc = document.createElement('span');
      doc.innerHTML = pluginDefinitions[key] && pluginDefinitions[key].doc;
      wrapper.appendChild(doc);
      section.appendChild(wrapper);
    }

    return section;
  }

  buildlibs(sectionTitle, availableLibs) {

    let section = this.buildSection(sectionTitle);

    for (const key of Object.keys(availableLibs)) {

      section.appendChild(this.buildBoolean(key, availableLibs));
    }

    return section;
  }

  buildBoolean(option, options) {

    let inputWrapper = document.createElement('div');
    let label = document.createElement('span');
    let checkbox = document.createElement('input');

    inputWrapper.classList.add('input-wrapper');
    label.innerHTML = option;
    checkbox.type = 'checkbox';
    checkbox.checked = options[option]._active;
    checkbox.__ternjs_key = option;
    checkbox.addEventListener('change', (e) => {

      options[e.target.__ternjs_key]._active = e.target.checked;

    }, false);

    inputWrapper.appendChild(label);
    inputWrapper.appendChild(checkbox);

    return inputWrapper;
  }

  createInputWrapper(path, sectionTitle) {

    let inputWrapper = document.createElement('div');
    let editor = this.createTextEditor(path);

    inputWrapper.classList.add('input-wrapper');
    editor.__ternjs_section = sectionTitle;
    inputWrapper.appendChild(editor);
    inputWrapper.appendChild(this.createAdd(sectionTitle));
    inputWrapper.appendChild(this.createSub(editor));

    return inputWrapper;
  }

  createSub(editor) {

    let sub = document.createElement('span');
    sub.classList.add('sub');
    sub.classList.add('inline-block');
    sub.classList.add('status-removed');
    sub.classList.add('icon');
    sub.classList.add('icon-diff-removed');

    sub.addEventListener('click', (e) => {

      this.getModel().removeEditor(editor);
      const inputWrapper = e.target.closest('.input-wrapper');
      inputWrapper.parentNode.removeChild(inputWrapper);

    }, false);

    return sub;
  }

  createAdd(sectionTitle) {

    let add = document.createElement('span');
    add.classList.add('add');
    add.classList.add('inline-block');
    add.classList.add('status-added');
    add.classList.add('icon');
    add.classList.add('icon-diff-added');
    add.addEventListener('click', (e) => {

      e.target.closest('section').appendChild(this.createInputWrapper(null, sectionTitle));

    }, false);

    return add;
  }

  createTextEditor(path) {

    let item = document.createElement('atom-text-editor');
    item.setAttribute('mini', true);

    if (path) {

      item.getModel().getBuffer().setText(path);
    }

    this.getModel().editors.push(item);

    return item;
  }

  removeContent() {

    this.contentElement.innerHTML = '';
  }

  getClose() {

    return this.buttonClose;
  }

  getCancel() {

    return this.buttonCancel;
  }
}

module.exports = document.registerElement('atom-ternjs-config', {

  prototype: ConfigView.prototype
});
