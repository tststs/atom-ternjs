class TypeView extends HTMLElement {

  createdCallback() {
    
    this.addEventListener('click', () => {

      this.getModel().destroyOverlay();

    }, false);

    this.container = document.createElement('div');
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

    this.container.innerHTML = data.label;
  }

  destroy() {

    this.remove();
  }
}

module.exports = document.registerElement('atom-ternjs-type', {

  prototype: TypeView.prototype
});
