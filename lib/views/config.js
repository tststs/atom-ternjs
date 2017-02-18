'use babel';

import ternConfigDocs from '../../config/tern-config-docs';
import pluginDefinitions from '../../config/tern-plugins-defintions.js';

const templateContainer = `

  <div>
    <h1 class="title"></h1>
    <div class="content"></div>
    <button class="btn btn-default">Save &amp; Restart Server</button>
  </div>
`;

export const createView = (model) => {

  return new ConfigView(model).init();
};

export default class ConfigView {

  constructor(model) {

    this.setModel(model);
    model.gatherData();
  }

  init() {

    const projectDir = this.model.getProjectDir();
    const projectConfig = this.model.config;

    this.el = document.createElement('div');
    this.el.classList.add('atom-ternjs-config');
    this.el.innerHTML = templateContainer;

    const elContent = this.el.querySelector('.content');
    const elTitle = this.el.querySelector('.title');
    elTitle.innerHTML = projectDir;

    const buttonSave = this.el.querySelector('button');

    buttonSave.addEventListener('click', (e) => {

      this.model.updateConfig();
    });

    elContent.appendChild(this.buildRadio('ecmaVersion'));
    elContent.appendChild(this.buildlibs('libs', projectConfig.libs));
    elContent.appendChild(this.buildStringArray(projectConfig.loadEagerly, 'loadEagerly'));
    elContent.appendChild(this.buildStringArray(projectConfig.dontLoad, 'dontLoad'));
    elContent.appendChild(this.buildPlugins('plugins', projectConfig.plugins));

    return this.el;
  }

  buildSection(sectionTitle) {

    const section = document.createElement('section');
    section.classList.add(sectionTitle);

    const header = document.createElement('h2');
    header.innerHTML = sectionTitle;

    section.appendChild(header);

    const docs = ternConfigDocs[sectionTitle].doc;

    if (docs) {

      const doc = document.createElement('p');
      doc.innerHTML = docs;

      section.appendChild(doc);
    }

    return section;
  }

  buildRadio(sectionTitle) {

    const section = this.buildSection(sectionTitle);

    for (const key of Object.keys(this.model.config.ecmaVersions)) {

      const inputWrapper = document.createElement('div');
      inputWrapper.classList.add('input-wrapper');

      const label = document.createElement('span');
      label.innerHTML = key;

      const radio = document.createElement('input');
      radio.type = 'radio';
      radio.name = 'ecmaVersions';
      radio.checked = this.model.config.ecmaVersions[key];
      radio.__ternjs_key = key;

      radio.addEventListener('change', (e) => {

        for (const key of Object.keys(this.model.config.ecmaVersions)) {

          this.model.config.ecmaVersions[key] = false;
        }

        this.model.config.ecmaVersions[e.target.__ternjs_key] = e.target.checked;
      }, false);

      inputWrapper.appendChild(label);
      inputWrapper.appendChild(radio);
      section.appendChild(inputWrapper);
    }

    return section;
  }

  buildStringArray(obj, sectionTitle) {

    const section = this.buildSection(sectionTitle);

    for (const path of obj) {

      section.appendChild(this.createInputWrapper(path, sectionTitle));
    }

    if (obj.length === 0) {

      section.appendChild(this.createInputWrapper(null, sectionTitle));
    }

    return section;
  }

  buildPlugins(sectionTitle, availablePlugins) {

    const section = this.buildSection(sectionTitle);

    for (const key of Object.keys(availablePlugins)) {

      const wrapper = document.createElement('p');
      wrapper.appendChild(this.buildBoolean(key, availablePlugins));
      const doc = document.createElement('span');
      doc.innerHTML = pluginDefinitions[key] && pluginDefinitions[key].doc;
      wrapper.appendChild(doc);
      section.appendChild(wrapper);
    }

    return section;
  }

  buildlibs(sectionTitle, availableLibs) {

    const section = this.buildSection(sectionTitle);

    for (const key of Object.keys(availableLibs)) {

      section.appendChild(this.buildBoolean(key, availableLibs));
    }

    return section;
  }

  buildBoolean(option, options) {

    const inputWrapper = document.createElement('div');
    const label = document.createElement('span');
    const checkbox = document.createElement('input');

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

    const inputWrapper = document.createElement('div');
    const editor = this.createTextEditor(path);

    inputWrapper.classList.add('input-wrapper');
    editor.__ternjs_section = sectionTitle;
    inputWrapper.appendChild(editor);
    inputWrapper.appendChild(this.createAdd(sectionTitle));
    inputWrapper.appendChild(this.createSub(editor));

    return inputWrapper;
  }

  createSub(editor) {

    const sub = document.createElement('span');
    sub.classList.add('sub');
    sub.classList.add('inline-block');
    sub.classList.add('status-removed');
    sub.classList.add('icon');
    sub.classList.add('icon-diff-removed');

    sub.addEventListener('click', (e) => {

      this.model.removeEditor(editor);
      const inputWrapper = e.target.closest('.input-wrapper');
      inputWrapper.parentNode.removeChild(inputWrapper);

    }, false);

    return sub;
  }

  createAdd(sectionTitle) {

    const add = document.createElement('span');
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

    const item = document.createElement('atom-text-editor');
    item.setAttribute('mini', true);

    if (path) {

      item.getModel().getBuffer().setText(path);
    }

    this.model.editors.push(item);

    return item;
  }

  getModel() {

    return this.model;
  }

  setModel(model) {

    this.model = model;
  }

  destroy() {

    this.el.remove();
  }
}
