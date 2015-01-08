# atom-ternjs package

Javascript code intelligence for atom with tern.js.
Uses suggestion provider by autocomplete-plus.

# Installation

* In your project root, create a file named '.tern-project'. See docs http://ternjs.net/doc/manual.html#configuration.
```
{
  "libs": [
    "browser",
    "jquery"
  ],
  "loadEagerly": [
    "absolute/path/to/your/js/**/*.js"
  ]
}
```

Absolute path is recommended, but not necessary.

# Notes

* This package is a work in progress and may contain various bugs, misbehaviours and performance issues
* If a .tern-project file is added to the current project, reopen the project. If this doesn't works, kill all atom instances and try to open the project again

# Currently supports the following features

* Find definition (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find definition" or use the shortcut strg+alt+d)
* Completion (autocompletion triggers automatically or can be forced with strg+alt+space)
* Documentation (at the current state, only works if a suggestion with a valid doc is selected)
