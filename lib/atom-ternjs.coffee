TernServer = require './atom-ternjs-server'
TernClient = require './atom-ternjs-client'
DocumentationView = require './atom-ternjs-documentation-view'
AtomTernjsAutocomplete = require './atom-ternjs-autocomplete'
Helper = require './atom-ternjs-helper'

class AtomTernInitializer

  disposables: []
  grammars: ['JavaScript']
  client: null
  documentationView: null
  server: null
  helper: null

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
    docs:
      title: 'Documentation'
      description: 'Whether to include documentation strings, urls, and origin files (if found) in the result data.'
      type: 'boolean'
      default: true
    guess:
      title: 'Guess'
      description: 'When completing a property and no completions are found, Tern will use some heuristics to try and return some properties anyway. Set this to false to turn that off.'
      type: 'boolean'
      default: true
    sort:
      title: 'Sort'
      description: 'Determines whether the result set will be sorted.'
      type: 'boolean'
      default: true
    caseInsensitive:
      title: 'Case-insensitive'
      description: 'Whether to use a case-insensitive compare between the current word and potential completions.'
      type: 'boolean'
      default: true

  activate: (state) ->
    @startServer()
    @helper = new Helper()
    @registerHelperCommands()
    @addComponents(state)
    @disposables.push atom.workspace.onDidOpen (e) =>
      @startServer()

  serialize: ->
    atomTernjsViewState: @documentationView.serialize()

  activatePackage: ->
    @provider = new AtomTernjsAutocomplete()
    @provider.init(@client, @documentationView)
    @registerEvents()
    @registration = atom.services.provide('autocomplete.provider', '1.0.0', {provider: @provider})

  init: ->
    @activatePackage()
    @registerCommands()

  deactivate: ->
    @stopServer()
    @unregisterEventsAndCommands()
    # autocomplete-plus
    @registration?.dispose()
    @registration = null
    @provider?.cleanup()
    @provider = null

  addComponents: (state) ->
    @documentationView = new DocumentationView(state.atomTernjsViewState)
    atom.views.getView(atom.workspace).appendChild(@documentationView.getElement())

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
      if !@provider
        @init()

  registerEvents: ->
    @disposables.push atom.workspace.observeTextEditors (editor) =>
      @disposables.push editor.onDidChangeCursorPosition (event) =>
        return if event.textChanged
        @documentationView.hide()
    @disposables.push atom.workspace.onDidChangeActivePaneItem =>
      @documentationView.hide()
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
    @disposables.push atom.commands.add 'atom-panel-container', 'tern:createTernProjectFile': (event) =>
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
      @documentationView.hide()

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
