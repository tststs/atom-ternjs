# atom-ternjs package

Javascript code intelligence for atom with tern.js.
Uses suggestion provider by autocomplete-plus

# Installation

* Since this package hasn't been released as a package, clone and npm install
* Create a symlink to the cloned repo in /Users/.../.atom/packages like so:
```
  $ ln -s /path/to/repo /path/to/symlink
```
* In your project root, create a file named '.tern-project'. See docs http://ternjs.net/doc/manual.html#configuration. E.g.:
```
{
  "libs": [
    "browser",
    "jquery"
  ],
  "loadEagerly": [
    "path/to/your/js/**/*.js"
  ]
}
```

# Currently supports the following features

* Find definition (set your cursor position to one of variable, function or instance -> open context-menu and trigger "Find definition")
* Completion (completion triggers if we are in the right context)
