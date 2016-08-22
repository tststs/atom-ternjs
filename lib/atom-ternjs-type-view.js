'use babel';

import TernView from './atom-ternjs-view';

class TypeView extends TernView {

  createdCallback() {

    this.addEventListener('click', () => {

      this.getModel().destroyOverlay();

    }, false);

    this.container = document.createElement('div');
    this.appendChild(this.container);
  }

  setData(data) {

    this.container.innerHTML = data.label;
  }
}

module.exports = document.registerElement('atom-ternjs-type', {

  prototype: TypeView.prototype
});
