# atom-ternjs

> Javascript code intelligence for atom with [Tern](https://github.com/marijnh/tern).
Uses suggestion provider by [autocomplete-plus](https://github.com/atom/autocomplete-plus).

## Installation

Make sure <a href="https://nodejs.org">Node.js</a> is installed and the PATH variable is set.<br>
Make sure <a href="http://git-scm.com">GIT</a> is installed and the PATH variable is set.<br>

Configure your project
* Navigate to Packages -> Atom Ternjs -> Configure project
* The config view appears.
* Hit "Save & Restart Server" to create/update the .tern-project file

**Configure project doesn't support the plugins-section (yet).
Please add plugins manually by editing the .tern-project file as shown below**

If configure project does not work for you
* In your project root create a file named .tern-project. See docs @ http://ternjs.net/doc/manual.html#configuration.
* Check path in loadEagerly
* Restart the server via *Packages -> Atom Ternjs -> Restart server*

If a root file named .tern-project is not found `~/.tern-config` serves as a default.

Example `.tern-project` file (customize to your own needs):
```json
{
  "libs": [
    "browser",
    "ecma5",
    "ecma6",
    "jquery"
  ],
  "loadEagerly": [
    "absolute/or/relative/path/to/your/js/**/*.js"
  ],
  "dontLoad": [
    "absolute/or/relative/path/to/your/js/**/*.js"
  ],
  "plugins": {
    "complete_strings": {},
    "node": {},
    "lint": {},
    "angular": {},
    "requirejs": {},
    "doc_comment": {
      "fullDocs": true
    }
  }
}
```
## Libs
* browser: completion for vanilla js (optional)
* ecma5: es5 (optional)
* ecma6: es6 (optional)
* jquery: completion for jQuery (optional)

## Options
* loadEagerly: provide the path to your projects js. Absolute path is recommended, but not necessary. (For relative path do not use `./` as a prefix. This sometimes leads to an unexpected behaviour)
* dontLoad: can be used to prevent Tern from loading certain files. It also takes an array of file names or glob patterns.

## Plugins
* complete_strings: When enabled, this plugin will gather (short) strings in your code, and completing when inside a string will try to complete to previously seen strings. Takes a single option, maxLength, which controls the maximum length of string values to gather, and defaults to 15. (optional)
* doc_comment: tern will look for JSDoc-style type declarations. Returns the full comment text instead of the first sentence. (optional)
* node: NodeJS (optional)
* lint: <a href="https://github.com/angelozerr/tern-lint">angelozerr/tern-lint</a> is a tern plugin which is able to validate JavaScript files to collect semantic errors. <a href="https://github.com/AtomLinter/Linter">Linter</a> is used to display these errors and warnings (optional)
* angular: AngularJS (optional)
* requirejs: RequireJS (optional, understand RequireJS-style dependency management)
* For a list of possible plugins goto http://ternjs.net/doc/manual.html#plugins

## .tern-project created/modified
* After the file was created or has been modified, restart the server via *Packages -> Atom Ternjs -> Restart server*

## Features
* Completion (autocompletion triggers automatically, via strg+space or can be forced in any context with <kbd>ctrl+alt+space</kbd>)

![atom-ternjs](http://www.tobias-schubert.com/github/github-atom-ternjs-9.png)

![atom-ternjs](http://www.tobias-schubert.com/github/github-atom-ternjs-inline-2.png)
* Find references (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find references" or use the shortcut <kbd>ctrl+shift+r</kbd>) Click any item in the generated reference-list and navigate directly to file and position

![atom-ternjs](http://www.tobias-schubert.com/github/github-atom-ternjs-reference.png)

* Documentation (displayed if a suggestion with a valid documentation is selected in the select-list)
* Find definition (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find definition" or use the shortcut <kbd>ctrl+alt+d</kbd>)
* Back from definition <kbd>ctrl+alt+z</kbd>
* Rename variable (set your cursor position to a variable -> open context-menu and trigger "Rename" or use the shortcut <kbd>ctrl+alt+c</kbd>)
