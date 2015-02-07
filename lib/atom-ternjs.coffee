TernServer = require './atom-ternjs-server'
TernClient = require './atom-ternjs-client'
Documentation = require './atom-ternjs-documentation'
Type = require './atom-ternjs-type'
Reference = require './atom-ternjs-reference'
Autocomplete = require './atom-ternjs-autocomplete'
Helper = require './atom-ternjs-helper'

class AtomTernInitializer

  disposables: []
  grammars: ['JavaScript']
  client: null
  server: null
  helper: null
  active: false

  # autocomplete-plus
  registration: null
  provider: null

  # config
  config:
    coffeeScript:
      title: 'CoffeeScript'
      description: 'Completions for CoffeeScript.'
      type: 'boolean'
      default: false
      order: 8
    docs:
      title: 'Show Documentation'
      description: 'Display the documentation view'
      type: 'boolean'
      default: true
      order: 3
    inlineFnCompletion:
      title: 'Display inline suggestions for function params'
      description: 'Displays a inline suggestion located right next to the current cursor'
      type: 'boolean'
      default: true
      order: 4
    documentation:
      title: 'Documentation'
      description: 'Whether to include documentation string (if found) in the result data.'
      type: 'boolean'
      default: true
      order: 5
    docsPosition:
      title: 'Force the documentation view to be positioned top/bottom/middle'
      type: 'string'
      default: 'auto'
      enum: ['auto', 'force top', 'force bottom', 'force middle']
    urls:
      title: 'Url'
      description: 'Whether to include documentation urls (if found) in the result data.'
      type: 'boolean'
      default: true
      order: 6
    origins:
      title: 'Origin'
      description: 'Whether to include origins (if found) in the result data.'
      type: 'boolean'
      default: true
      order: 7
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

  activate: (state) ->
    @startServer()
    @provider = new Autocomplete()
    @helper = new Helper()
    @registerHelperCommands()
    @disposables.push atom.workspace.onDidOpen (e) =>
      @startServer()

  serialize: ->

  activatePackage: ->
    @documentation = new Documentation()
    @type = new Type(@client)
    @provider.init(@client, @documentation)
    @reference = new Reference(@client)
    @registerEvents()

  init: ->
    @active = true
    @activatePackage()
    @registerCommands()

  provide: ->
    return {providers: [@provider]}

  deactivate: ->
    @stopServer()
    @unregisterEventsAndCommands()
    # autocomplete-plus
    @registration?.dispose()
    @registration = null
    @provider?.cleanup()
    @provider = null
    @reference?.destroy()
    @reference = null
    @documentation?.destroy()
    @documentation = null
    @type?.destroy()
    @type = null
    @active = false

  unregisterEventsAndCommands: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  startServer: ->
    return unless !@server?.process and atom.project.getDirectories()[0]
    if !@server
      @server = new TernServer()
    @server.start (port) =>
      if !@client
        @client = new TernClient()
      @client.port = port
      if !@active
        @init()

  isValidEditor: (editor) ->
    return false if !editor or editor.mini
    return false if !editor.getGrammar
    return false if !editor.getGrammar()
    return false if editor.getGrammar().name not in @grammars
    return true

  registerEvents: ->
    @disposables.push atom.workspace.observeTextEditors (editor) =>
      @disposables.push editor.onDidChangeCursorPosition (event) =>
        return unless @isValidEditor(editor)
        if atom.config.get('atom-ternjs.inlineFnCompletion')
          if event.textChanged
            @client.update(editor.getURI(), editor.getText()).then =>
              @type.queryType()
          else
            @type.queryType()
        return if event.textChanged
        @documentation.hide()

      @disposables.push editor.getBuffer().onDidChangeModified (modified) =>
        return unless modified
        @reference.hide()
    @disposables.push atom.workspace.onDidChangeActivePaneItem (item) =>
      @provider?.clearSuggestionsAndHide()
      if !@isValidEditor(item)
        @reference.hide()
    @disposables.push atom.config.observe 'atom-ternjs.inlineFnCompletion', =>
      @type?.destroyOverlay()
    @disposables.push atom.config.observe 'atom-ternjs.coffeeScript', =>
      if atom.config.get('atom-ternjs.coffeeScript')
        @addGrammar('CoffeeScript')
        @provider.addSelector('.source.coffee')
      else
        @removeGrammar('CoffeeScript')
        @provider.removeSelector('.source.coffee')

  addGrammar: (grammar) ->
    return unless @grammars.indexOf(grammar) is -1
    @grammars.push grammar

  removeGrammar: (grammar) ->
    idx = @grammars.indexOf(grammar)
    return if idx is -1
    @grammars.splice(idx, 1)

  registerHelperCommands: ->
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:createTernProjectFile': (event) =>
      @helper.createTernProjectFile()

  registerCommands: ->
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:definition': (event) =>
      @client?.definition()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:restart': (event) =>
      @restartServer()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:startCompletion': (event) =>
      @provider?.forceCompletion()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:cancel': (event) =>
      @provider?.forceCancel()
      @documentation.hide()

  stopServer: ->
    if @server?.process
      @server.stop()
    @server = null

  restartServer: ->
    if @server?.process
      @server.stop()
    @server = null
    @startServer()

#expose init class
module.exports = new AtomTernInitializer()
