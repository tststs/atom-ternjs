# atom-ternjs package

Javascript code intelligence for atom with tern.js.
Uses suggestion provider by autocomplete-plus.

# Installation

* In your project root, create a file named '.tern-project'. See docs http://ternjs.net/doc/manual.html#configuration. E.g.:
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

# Currently supports the following features

* Find definition (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find definition" or use the shortcut strg+alt+d)
* Completion (autocompletion triggers automatically or can be forced with strg+alt+space)
