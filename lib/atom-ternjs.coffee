TernServer = require './atom-ternjs-server'
TernClient = require './atom-ternjs-client'
Documentation = require './atom-ternjs-documentation'
#Type = require './atom-ternjs-type'
Reference = require './atom-ternjs-reference'
Autocomplete = require './atom-ternjs-autocomplete'
Helper = require './atom-ternjs-helper'

class AtomTernInitializer

  disposables: []
  grammars: ['JavaScript']
  client: null
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
      description: 'Whether to include documentation strings (if found) in the result data.'
      type: 'boolean'
      default: true
    urls:
      title: 'Url'
      description: 'Whether to include documentation urls (if found) in the result data.'
      type: 'boolean'
      default: true
    origins:
      title: 'Origin'
      description: 'Whether to include origins (if found) in the result data.'
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
    @disposables.push atom.workspace.onDidOpen (e) =>
      @startServer()

  serialize: ->

  activatePackage: ->
    @provider = new Autocomplete()
    @documentation = new Documentation()
    #@type = new Type()
    @provider.init(@client, @documentation)
    @reference = new Reference(@client)
    @registerEvents()
    @registration = atom.packages.serviceHub.provide('autocomplete.provider', '1.0.0', {provider: @provider})

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
    @reference?.destroy()
    @reference = null

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

  isValidEditor: (editor) ->
    return false if !editor or editor.mini
    return false if !editor.getGrammar
    return false if !editor.getGrammar()
    return false if editor.getGrammar().name not in @grammars
    return true

  registerEvents: ->
    @disposables.push atom.workspace.observeTextEditors (editor) =>
      @disposables.push editor.onDidChangeCursorPosition (event) =>
        #@type.queryType()
        return if event.textChanged
        @documentation.hide()
      @disposables.push editor.getBuffer().onDidChangeModified (modified) =>
        return unless modified
        @reference.hide()
    @disposables.push atom.workspace.onDidChangeActivePaneItem (item) =>
      @provider?.clearSuggestionsAndHide()
      if !@isValidEditor(item)
        @reference.hide()
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
