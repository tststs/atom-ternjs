'use babel'

let [workspaceElement, editor, editorElement, pack] = [];
let path = require('path');

function sharedSetup() {

  atom.project.setPaths([path.join(__dirname, 'fixtures')]);
  workspaceElement = atom.views.getView(atom.workspace);

  waitsForPromise(() => {

    return new Promise((resolve, reject) => {

      atom.workspace.open('test.js')
      .then(() => {

        pack = atom.packages.enablePackage('atom-ternjs');

        resolve();
      });
    });
  });

  runs(() => {

    editor = atom.workspace.getActiveTextEditor();
    editorElement = atom.views.getView(editor);
  });
}

describe('atom-ternjs', () => {

  beforeEach(() => {

    sharedSetup(true);
  });

  describe('activate()', () => {

    it('activates the atom-ternjs-manager', () => {

      expect(pack.config).toBeDefined();
    });
  });

  describe('deactivate()', () => {

    beforeEach(() => {

      editor.setCursorBufferPosition([4, 15]);
      atom.packages.deactivatePackage('atom-ternjs');
    });

    it('destroys all views', () => {

      expect(workspaceElement.querySelectorAll('atom-ternjs-reference').length).toBe(0);
      expect(workspaceElement.querySelectorAll('atom-ternjs-rename').length).toBe(0);
      expect(workspaceElement.querySelectorAll('.atom-ternjs-config').length).toBe(0);
      expect(workspaceElement.querySelectorAll('atom-ternjs-documentation').length).toBe(0);
      expect(workspaceElement.querySelectorAll('atom-ternjs-type').length).toBe(0);
      expect(editorElement.querySelectorAll('atom-text-editor .atom-ternjs-definition-marker').length).toBe(0);
    });
  });
});

describe('atom-ternjs', () => {

  beforeEach(() => {

    sharedSetup(false);
  });

  describe('activate()', () => {


  });
});
