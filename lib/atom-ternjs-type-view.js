'use babel';

import TernView from './atom-ternjs-view';

class TypeView extends TernView {

  initialize(model) {

    super.initialize(model);

    this.addEventListener('click', model.destroyOverlay);
  }

  setData(type, documentation) {

    this.innerHTML = documentation ? `${type}<br /><br />${documentation}` : `${type}`;
  }
}

module.exports = document.registerElement('atom-ternjs-type', {

  prototype: TypeView.prototype
});
