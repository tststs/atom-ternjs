# atom-ternjs

> JavaScript code intelligence for atom with [Tern](https://github.com/ternjs/tern).
Adds support for ES5, ES6, ES7, Node.js, jQuery, Angular and more. Extendable via plugins.
Uses suggestion provider by [autocomplete-plus](https://github.com/atom/autocomplete-plus).

## Installation

Configure your project
* Open any JavaScript file from within you project
* Navigate to Packages -> Atom Ternjs -> Configure project
* The config view appears.
* Hit "Save & Restart Server" to create/update the .tern-project file

**In order to use third party plugins read the [Third party plugins](#third-party-plugins) section!**

**In order to use third party plugins from within your project's ```node_modules``` read the [Third party plugins local](#third-party-plugins-local) section! This is also an alternative if [Third party plugins](#third-party-plugins) aren't working.**

If configure project does not work for you
* In your project root create a file named .tern-project. See docs @ http://ternjs.net/doc/manual.html#configuration.
* Restart the server via *Packages -> Atom Ternjs -> Restart server*

Example `.tern-project` file (customize to your own needs):

```json
{
  "ecmaVersion": 6,
  "libs": [
    "browser",
    "jquery"
  ],
  "loadEagerly": [
    "path/to/your/js/**/*.js"
  ],
  "dontLoad": [
    "path/to/your/js/**/*.js"
  ],
  "plugins": {
    "complete_strings": {
      "maxLength": 15
    },
    "node": {},
    "doc_comment": {
      "fullDocs": true,
      "strong": true
    }
  }
}
```

### EcmaVersion
* 5: use ECMAScript5
* 6: use ECMAScript6 (default)
* 7: use ECMAScript7

### Libs
* browser: completion for vanilla js (optional)
* jquery: completion for jQuery (optional)
* underscore: completion for underscore (optional)
* chai: completion for chai (optional)

### Options
* loadEagerly: provide the path to your projects js. For relative paths do not use `./` as a prefix. This sometimes leads to an unexpected behaviour.
* **loadEagerly is expensive. Do not add paths like `node_modules`.**
* dontLoad: can be used to prevent Tern from loading certain files. It also takes an array of file names or glob patterns.

### Plugins
* For a list of build in server plugins, visit: http://ternjs.net/doc/manual.html#plugins

### Keybindings
List of [keybindings](#features).
To use your own keybindings goto `atom-ternjs` package settings and disable keybindings.

## Third party plugins
In order to use third party plugins (e.g. [tern-node-express](https://github.com/angelozerr/tern-node-express)):
```
$ cd ~/.atom/packages/atom-ternjs
$ npm install tern-node-express
```
Add the plugin to your .tern-project file:
```json
{
  "ecmaVersion": 6,
  "libs": [
    "browser"
  ],
  "loadEagerly": [
    "app/**/*.js"
  ],
  "plugins": {
    "node-express": {}
  }
}
```

Third party plugins are still an issue and sometimes do not work as expected, especially if the plugin is requiring a tern version that does not match the tern version that is used by atom-ternjs.
Restart the server: *Packages -> Atom Ternjs -> Restart server*

## Third party plugins local

Example for node-express.
Open node_modules/tern-node-express/tern-express.js

Replace:

```js
(function(mod) {
  if (typeof exports == "object" && typeof module == "object") // CommonJS
    return mod(require("tern/lib/infer"), require("tern/lib/tern"));
  if (typeof define == "function" && define.amd) // AMD
    return define([ "tern/lib/infer", "tern/lib/tern" ], mod);
  mod(tern, tern);
}...
```

With

```js
(function(mod) {
  return mod(process.__infer, process.__tern);
}...

```

Restart Atom.

## .tern-project created/modified
* After the file was created or has been modified, restart the server via *Packages -> Atom Ternjs -> Restart server*

## Features
* Completion (autocompletion triggers automatically), or via the keybindings:
  * <kbd>strg+space</kbd>
  * <kbd>ctrl+alt+space</kbd> (force autocompletion in any context)

![atom-ternjs](http://www.tobias-schubert.com/github/completion-1.png)

![atom-ternjs](http://www.tobias-schubert.com/github/completion-2.png)
* Find references (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find references" or use the keybindings:
  * <kbd>ctrl+shift+r</kbd> (mac, windows)
  * <kbd>ctrl+alt+shift+e</kbd> (linux)

Click any item in the generated reference-list and navigate directly to file and position

![atom-ternjs](http://www.tobias-schubert.com/github/reference-1.png)

* Documentation
  * Show documentation for the thing under the cursor via <kbd>alt+o</kbd> (mac, windows, linux)
  ![atom-ternjs](http://www.tobias-schubert.com/github/docs.png)
  * Also displayed if a suggestion with a valid documentation is selected in the autocomplete-plus select-list

* Find definition (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find definition") or use the keybindings:
  * <kbd>alt+click</kbd> (mac, windows, linux)
  * <kbd>ctrl+alt+shift+d</kbd> (mac, windows, linux)

* Back from definition
  * <kbd>ctrl+alt+z</kbd> (mac, windows)
  * <kbd>ctrl+alt+shift+z</kbd> (linux)

* Rename variable (set your cursor position to a variable -> open context-menu and trigger "Rename") or use the keybindings:
  * <kbd>ctrl+alt+c</kbd> (mac, windows)
  * <kbd>ctrl+alt+shift+c</kbd> (linux)
