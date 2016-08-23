'use babel';

import TernView from './atom-ternjs-view';
import packageConfig from './atom-ternjs-package-config';

class TypeView extends TernView {

  createdCallback() {

    this.addEventListener('click', () => {

      this.getModel().destroyOverlay();

    }, false);

    this.container = document.createElement('div');
    this.appendChild(this.container);
  }

  setData(data) {

    if (packageConfig.options.inlineFnCompletionDocumentation) {

      this.container.innerHTML = data.doc ? `${data.type}<br /><br />${data.doc}` : `${data.type}`;

      return;
    }

    this.container.innerHTML = data.type;
  }
}

module.exports = document.registerElement('atom-ternjs-type', {

  prototype: TypeView.prototype
});
