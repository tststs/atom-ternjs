'use babel';

export default {
  complete_strings: {
    doc: 'When enabled, this plugin will gather (short) strings in your code, and completing when inside a string will try to complete to previously seen strings. Takes a single option, maxLength, which controls the maximum length of string values to gather, and defaults to 15.',
    definition: {
      maxLength: {
        doc: '',
        type: 'number'
      }
    }
  },
  doc_comment: {
    doc: 'This plugin, which is enabled by default in the bin/tern server, parses comments before function declarations, variable declarations, and object properties. It will look for JSDoc-style type declarations, and try to parse them and add them to the inferred types, and it will treat the first sentence of comment text as the docstring for the defined variable or property.',
    definition: {
      fullDocs: {
        doc: 'Can be set to true to return the full comment text instead of the first sentence.',
        type: 'boolean'
      },
      strong: {
        doc: 'When enabled, types specified in comments take precedence over inferred types.',
        type: 'boolean'
      }
    }
  },
  node: {
    doc: 'The node.js plugin, called \"node\", provides variables that are part of the node environment, such as process and __dirname, and loads the commonjs and node_resolve plugins to allow node-style module loading. It defines types for the built-in modules that node.js provides (\"fs\", \"http\", etc).',
    definition: {
      dontLoad: {
        doc: 'Can be set to true to disable dynamic loading of required modules entirely, or to a regular expression to disable loading of files that match the expression.',
        type: 'string'
      },
      load: {
        doc: 'If dontLoad isn’t given, this setting is checked. If it is a regular expression, the plugin will only load files that match the expression.',
        type: 'string'
      },
      modules: {
        doc: 'Can be used to assign JSON type definitions to certain modules, so that those are loaded instead of the source code itself. If given, should be an object mapping module names to either JSON objects defining the types in the module, or a string referring to a file name (relative to the project directory) that contains the JSON data.',
        type: 'string'
      }
    }
  },
  node_resolve: {
    doc: 'This plugin defines the node.js module resolution strategy—things like defaulting to index.js when requiring a directory and searching node_modules directories. It depends on the modules plugin. Note that this plugin only does something meaningful when the Tern server is running on node.js itself.',
    definition: {}
  },
  modules: {
    doc: 'This is a supporting plugin to act as a dependency for other module-loading and module-resolving plugins.',
    definition: {
      dontLoad: {
        doc: 'Can be set to true to disable dynamic loading of required modules entirely, or to a regular expression to disable loading of files that match the expression.',
        type: 'string'
      },
      load: {
        doc: 'If dontLoad isn’t given, this setting is checked. If it is a regular expression, the plugin will only load files that match the expression.',
        type: 'string'
      },
      modules: {
        doc: 'Can be used to assign JSON type definitions to certain modules, so that those are loaded instead of the source code itself. If given, should be an object mapping module names to either JSON objects defining the types in the module, or a string referring to a file name (relative to the project directory) that contains the JSON data.',
        type: 'string'
      }
    }
  },
  es_modules: {
    doc: 'This plugin (es_modules) builds on top of the modules plugin to support ECMAScript 6’s import and export based module inclusion.',
    definition: {}
  },
  angular: {
    doc: 'Adds the angular object to the top-level environment, and tries to wire up some of the bizarre dependency management scheme from this library, so that dependency injections get the right types. Enabled with the name \"angular\".',
    definition: {}
  },
  requirejs: {
    doc: 'This plugin (\"requirejs\") teaches the server to understand RequireJS-style dependency management. It defines the global functions define and requirejs, and will do its best to resolve dependencies and give them their proper types.',
    defintions: {
      baseURL: {
        doc: 'The base path to prefix to dependency filenames.',
        type: 'string'
      },
      paths: {
        doc: 'An object mapping filename prefixes to specific paths. For example {\"acorn\": \"lib/acorn/\"}.',
        type: 'string'
      },
      override: {
        doc: 'An object that can be used to override some dependency names to refer to predetermined types. The value associated with a name can be a string starting with the character =, in which case the part after the = will be interpreted as a global variable (or dot-separated path) that contains the proper type. If it is a string not starting with =, it is interpreted as the path to the file that contains the code for the module. If it is an object, it is interpreted as JSON type definition.',
        type: 'string'
      }
    }
  },
  commonjs: {
    doc: 'This plugin implements CommonJS-style (require(\"foo\")) modules. It will wrap files in a file-local scope, and bind require, module, and exports in this scope. Does not implement a module resolution strategy (see for example the node_resolve plugin). Depends on the modules plugin.',
    definition: {}
  }
};
