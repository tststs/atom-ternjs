"use babel";

class DocumentationView extends HTMLElement {

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

  initialize(model) {

    this.setModel(model);

    return this;
  }

  getModel() {

    return this.model;
  }

  setModel(model) {

    this.model = model;
  }

  setData(data) {

    this.container.innerHTML = `

      <h3>${data.type}</h3>
      <p>${data.doc}</p>
      <a href="${data.url}">${data.url}</p>
    `;
  }

  destroy() {

    this.remove();
  }
}

module.exports = document.registerElement('atom-ternjs-documentation', {

  prototype: DocumentationView.prototype
});
