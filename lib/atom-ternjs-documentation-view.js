'use babel';

import TernView from './atom-ternjs-view';

class DocumentationView extends TernView {

  createdCallback() {

    this.getModel();
    this.addEventListener('click', () => {

      this.getModel().destroyOverlay();

    }, false);

    this.container = document.createElement('div');

    this.container.onmousewheel = (e) => {

      e.stopPropagation();
    };

    this.appendChild(this.container);
  }

  setData(data) {

    this.container.innerHTML = `

      <h3>${data.type}</h3>
      <p>${data.doc}</p>
      <a href="${data.url}">${data.url}</p>
    `;
  }
}

module.exports = document.registerElement('atom-ternjs-documentation', {

  prototype: DocumentationView.prototype
});
