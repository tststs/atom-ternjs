Manager = require './atom-ternjs-manager'
Provider = require './atom-ternjs-provider'
LinterTern = require './linter'

module.exports =

  manager: null
  provider: null

  # config
  config:
    guess:
      title: 'Guess'
      description: 'When completing a property and no completions are found, Tern will use some heuristics to try and return some properties anyway. Set this to false to turn that off.'
      type: 'boolean'
      default: true
      order: 0
    sort:
      title: 'Sort'
      description: 'Determines whether the result set will be sorted.'
      type: 'boolean'
      default: true
      order: 1
    caseInsensitive:
      title: 'Case-insensitive'
      description: 'Whether to use a case-insensitive compare between the current word and potential completions.'
      type: 'boolean'
      default: true
      order: 2
    useSnippets:
      title: 'Use autocomplete-snippets'
      description: 'Adds snippets to autocomplete+ suggestions'
      type: 'boolean'
      default: true
      order: 3
    useSnippetsAndFunction:
      title: 'Display both, autocomplete-snippets and function name'
      description: 'Choose to just complete the function name or expand the snippet'
      type: 'boolean'
      default: false
      order: 4
    doNotAddParantheses:
      title: 'Do not add parantheses if method is completed'
      description: 'Currently only works if "Use autocomplete-snippets" and "Display both, autocomplete-snippets and function name" are both disabled.'
      type: 'boolean'
      default: false
      order: 5
    inlineFnCompletion:
      title: 'Display inline suggestions for function params'
      description: 'Displays a inline suggestion located right next to the current cursor'
      type: 'boolean'
      default: true
      order: 6
    lint:
      title: 'Use tern-lint'
      description: 'Use tern-lint to validate JavaScript files to collect semantic errors'
      type: 'boolean'
      default: true
      order: 7
    documentation:
      title: 'Documentation'
      description: 'Whether to include documentation string (if found) in the result data.'
      type: 'boolean'
      default: true
      order: 8
    urls:
      title: 'Url'
      description: 'Whether to include documentation urls (if found) in the result data.'
      type: 'boolean'
      default: true
      order: 9
    origins:
      title: 'Origin'
      description: 'Whether to include origins (if found) in the result data.'
      type: 'boolean'
      default: true
      order: 10

  activate: (state) ->
    @provider = new Provider()
    @manager = new Manager(@provider)
    @providerLinter = new LinterTern(@manager)

  deactivate: ->
    @manager.destroy()
    @manager = null

  provide: ->
    @provider

  provideLinter: ->
    @providerLinter
