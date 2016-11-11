'use babel';

export default {

  excludeLowerPriorityProviders: {

    title: 'Exclude lower priority providers',
    description: 'Whether to exclude lower priority providers (e.g. autocomplete-paths)',
    type: 'boolean',
    default: false,
    order: 0
  },
  guess: {

    title: 'Guess',
    description: 'When completing a property and no completions are found, Tern will use some heuristics to try and return some properties anyway. Set this to false to turn that off.',
    type: 'boolean',
    default: true,
    order: 1
  },
  sort: {

    title: 'Sort',
    description: 'Determines whether the result set will be sorted.',
    type: 'boolean',
    default: true,
    order: 2
  },
  caseInsensitive: {

    title: 'Case-insensitive',
    description: 'Whether to use a case-insensitive compare between the current word and potential completions.',
    type: 'boolean',
    default: true,
    order: 3
  },
  useSnippets: {

    title: 'Use autocomplete-snippets',
    description: 'Adds snippets to autocomplete+ suggestions',
    type: 'boolean',
    default: false,
    order: 4
  },
  snippetsFirst: {

    title: 'Display snippets above',
    description: 'Displays snippets above tern suggestions. Requires a restart.',
    type: 'boolean',
    default: false,
    order: 5
  },
  useSnippetsAndFunction: {

    title: 'Display both, autocomplete-snippets and function name',
    description: 'Choose to just complete the function name or expand the snippet',
    type: 'boolean',
    default: false,
    order: 6
  },
  inlineFnCompletion: {

    title: 'Display inline suggestions for function params',
    description: 'Displays a inline suggestion located right next to the current cursor',
    type: 'boolean',
    default: true,
    order: 7
  },
  inlineFnCompletionDocumentation: {

    title: 'Display inline suggestions with additional documentation (if any)',
    description: 'Adds documentation to the inline function completion',
    type: 'boolean',
    default: false,
    order: 8
  },
  documentation: {

    title: 'Documentation',
    description: 'Whether to include documentation string (if found) in the result data.',
    type: 'boolean',
    default: true,
    order: 9
  },
  urls: {

    title: 'Url',
    description: 'Whether to include documentation urls (if found) in the result data.',
    type: 'boolean',
    default: true,
    order: 10
  },
  origins: {

    title: 'Origin',
    description: 'Whether to include origins (if found) in the result data.',
    type: 'boolean',
    default: true,
    order: 11
  },
  ternServerGetFileAsync: {

    title: 'Tern Server getFile async',
    description: 'Indicates whether getFile is asynchronous. Default is true. Requires a restart.',
    type: 'boolean',
    default: true,
    order: 12
  },
  ternServerDependencyBudget: {

    title: 'Tern Server dependency-budget',
    description: 'http://ternjs.net/doc/manual.html#dependency_budget. Requires a restart.',
    type: 'number',
    default: 20000,
    order: 13
  }
};
