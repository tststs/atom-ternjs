# atom-ternjs package

Javascript code intelligence for atom with [Tern](http://ternjs.net/).
Uses suggestion provider by [autocomplete-plus](https://github.com/atom-community/autocomplete-plus).

# Installation

Install the package [autocomplete-plus](https://github.com/atom-community/autocomplete-plus).

In your project root create a file named .tern-project

* With default config via menu (Packages -> Atom Ternjs -> Create default .tern-project) or by adding it manually. See docs @ http://ternjs.net/doc/manual.html#configuration.
* Check path in loadEagerly
* Restart the server via Packages -> Atom Ternjs -> Restart server

Example .tern-project file (customize to your own needs):
```
{
  "libs": [
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
    "angular": {},
    "requirejs": {},
    "doc_comment": {
      "fullDocs": true
    }
  }
}
```
##### libs
* browser: completion for vanilla js (optional)
* ecma5: es5 (optional)
* ecma6: es6 (optional)
* jquery: completion for jQuery (optional)

##### options
* loadEagerly: provide the path to your projects js. Absolute path is recommended, but not necessary. (For relative path do not use './' as a prefix. This sometimes leads to an unexpected behaviour)
* dontLoad: can be used to prevent Tern from loading certain files. It also takes an array of file names or glob patterns.

##### plugins
* complete_strings: When enabled, this plugin will gather (short) strings in your code, and completing when inside a string will try to complete to previously seen strings. Takes a single option, maxLength, which controls the maximum length of string values to gather, and defaults to 15. (optional)
* doc_comment: tern will look for JSDoc-style type declarations. Returns the full comment text instead of the first sentence. (optional)
* node: NodeJS (optional)
* angular: AngularJS (optional)
* requirejs: RequireJS (optional, understand RequireJS-style dependency management)
* For a list of possible plugins goto http://ternjs.net/doc/manual.html#plugins

# .tern-project created/modified
* After the file was created or has been modified, restart the server via Packages -> Atom Ternjs -> Restart server

# Platform Windows
* Make sure node is installed and the PATH variable is set

# Notes
* This package is a work in progress and may contain various bugs, misbehaviours and performance issues

# Features
* Completion (autocompletion triggers automatically or can be forced with strg+alt+space)

![atom-ternjs](http://www.tobias-schubert.com/github/github-atom-ternjs-5.png)

![atom-ternjs](http://www.tobias-schubert.com/github/github-atom-ternjs-inline-2.png)
* Find references (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find references" or use the shortcut strg+alt+r) Click any item in the generated reference-list and navigate directly to file and position
* Documentation (displayed if a suggestion with a valid documentation is selected in the select-list)
* Find definition (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find definition" or use the shortcut strg+alt+d)

![atom-ternjs](http://www.tobias-schubert.com/github/github-atom-ternjs-6.png)
* Back from definition (strg+alt+z)
* Rename variable (set your cursor position to a variable -> open context-menu and trigger "Rename" or use the shortcut strg+alt+c)
