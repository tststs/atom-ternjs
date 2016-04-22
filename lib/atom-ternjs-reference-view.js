"use babel";

import {replaceTags} from './atom-ternjs-helper.js';

class ReferenceView extends HTMLElement {

  createdCallback() {

    const container = document.createElement('div');

    this.content = document.createElement('div');
    this.closeButton = document.createElement('button');

    this.classList.add('atom-ternjs-reference');
    this.closeButton.classList.add('btn', 'atom-ternjs-reference-close');
    this.closeButton.innerHTML = 'Close';

    container.appendChild(this.closeButton);
    container.appendChild(this.content);

    this.appendChild(container);
  }

  initialize(model) {

    this.setModel(model);

    return this;
  }

  clickHandle(i) {

    this.getModel().goToReference(i);
  }

  buildItems(data) {

    let headline = document.createElement('h2');
    let list = document.createElement('ul');
    let i = 0;

    this.content.innerHTML = '';
    headline.innerHTML = `${data.name} (${data.type})`;
    this.content.appendChild(headline);

    for (const item of data.refs) {

      let li = document.createElement('li');
      let lineText = replaceTags(item.lineText);
      lineText = lineText.replace(data.name, `<strong>${data.name}</strong>`);

      li.innerHTML = `
        <h3>
          <span>
            <span class="darken">
              (${item.position.row + 1}:${item.position.column}):
            </span>
            <span> ${lineText}</span>
          </span>
          <span class="darken"> (${item.file})</span>
          <div class="clear"></div>
        </h3>
      `;

      li.addEventListener('click', this.clickHandle.bind(this, i), false);
      list.appendChild(li);

      i++;
    }

    this.content.appendChild(list);
  }

  getClose() {

    return this.closeButton;
  }

  getModel() {

    return this.model;
  }

  setModel(model) {

    this.model = model;
  }

  destroy() {

    this.remove();
  }
}

module.exports = document.registerElement('atom-ternjs-reference', {

  prototype: ReferenceView.prototype
});
