# atom-ternjs package

Javascript code intelligence for atom with tern.js.
Uses suggestion provider by autocomplete-plus.

![atom-ternjs](http://www.tobias-schubert.com/github/github-atom-ternjs.png)

# Installation

* In your project root, create a file named '.tern-project'. See docs @ http://ternjs.net/doc/manual.html#configuration.
```
{
  "libs": [
    "browser",
    "jquery"
  ],
  "loadEagerly": [
    "absolute/or/relative/path/to/your/js/**/*.js"
  ],
  "plugins": {
    "doc_comment": {
      "fullDocs": true
    }
  }
}
```
* Absolute path is recommended, but not necessary
* loadEagerly: recommended, but not necessary. If no files are provided via 'loadEagerly', tern will register all files opened in the current workspace
* doc_comment: tern will look for JSDoc-style type declarations. Returns the full comment text instead of the first sentence. (optional)
* browser: completion for vanilla js (optional)
* jquery: completion for jquery (optional)

# Notes

* This package is a work in progress and may contain various bugs, misbehaviours and performance issues
* If a .tern-project file is added to the current project, reopen the project. If this doesn't work, kill all atom instances and try to open the project again

# Features

* Find definition (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find definition" or use the shortcut strg+alt+d)
* Completion (autocompletion triggers automatically or can be forced with strg+alt+space)
* Documentation (displayed if a suggestion with a valid documentation is selected in the select-list)

# Max Suggestions

* Use autocomplete-plus's settings to increase the max suggestions being displayed
