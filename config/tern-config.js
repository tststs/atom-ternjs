'use babel';

export const defaultProjectConfig = {

  ecmaVersion: 6,
  libs: [],
  loadEagerly: [],
  dontLoad: [
    'node_modules/**'
  ],
  plugins: {

    doc_comment: true
  }
};

export const defaultServerConfig = {

  ecmaVersion: 6,
  libs: [],
  loadEagerly: [],
  dontLoad: [
    'node_modules/**'
  ],
  plugins: {

    doc_comment: true
  },
  dependencyBudget: 20000,
  ecmaScript: true
};

export const ecmaVersions = [5, 6, 7];

export const availableLibs = [

  'browser',
  'chai',
  'jquery',
  'underscore'
];

export const availablePlugins = {

  complete_strings: {

    maxLength: 15
  },
  doc_comment: {

    fullDocs: true,
    strong: false
  },
  node: {

    dontLoad: '',
    load: '',
    modules: ''
  },
  node_resolve: {},
  modules: {

    dontLoad: '',
    load: '',
    modules: ''
  },
  es_modules: {},
  angular: {},
  requirejs: {

    baseURL: '',
    paths: '',
    override: ''
  },
  commonjs: {}
};
