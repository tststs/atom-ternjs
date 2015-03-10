Server = require './atom-ternjs-server'
Client = require './atom-ternjs-client'
Documentation = require './atom-ternjs-documentation'
Type = require './atom-ternjs-type'
Reference = require './atom-ternjs-reference'
Helper = require './atom-ternjs-helper'
ViewManager = require './atom-ternjs-view-manager'

module.exports =
class Manager

  disposables: []
  grammars: ['JavaScript']
  client: null
  viewManager: null
  server: null
  helper: null
  documentation: null
  type: null
  reference: null
  provider: null
  initialised: false
  inlineFnCompletion: false

  constructor: (provider) ->
    @provider = provider
    @checkGrammarSettings()
    @registerHelperCommands()
    @helper = new Helper()
    @client = new Client(this)
    @documentation = new Documentation(this)
    @type = new Type(this)
    @reference = new Reference(this)
    @viewManager = new ViewManager(this)
    @provider.init(this)
    @startServer()
    @disposables.push atom.workspace.onDidOpen (e) =>
      @startServer()

  init: ->
    @initialised = true
    @registerEvents()
    @registerCommands()

  destroy: ->
    @stopServer()
    @client.unregisterEvents()
    @client = null
    @unregisterEventsAndCommands()
    @provider?.destroy()
    @provider = null
    @reference?.destroy()
    @reference = null
    @documentation?.destroy()
    @documentation = null
    @type?.destroy()
    @type = null
    @helper.destroy()
    @helper = null
    @initialised = false

  unregisterEventsAndCommands: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  startServer: ->
    return unless !@server?.process and atom.project.getDirectories()[0]
    @server = new Server()
    @server.start (port) =>
      @client.port = port
      return if @initialised
      @init()

  isValidEditor: (editor) ->
    return false if !editor or editor.mini
    return false if !editor.getGrammar
    return false if !editor.getGrammar()
    return false if editor.getGrammar().name not in @grammars
    return true

  registerEvents: ->
    @disposables.push atom.workspace.observeTextEditors (editor) =>
      return unless @isValidEditor(editor)
      @disposables.push editor.onDidChangeCursorPosition (event) =>
        if @inlineFnCompletion
          @type.queryType(editor)
        @viewManager?.hideRename()
        return if event.textChanged
        @documentation.hide()
      @disposables.push editor.getBuffer().onDidChangeModified (modified) =>
        return unless modified
        @reference.hide()
    @disposables.push atom.workspace.onDidChangeActivePaneItem (item) =>
      @provider?.clearSuggestionsAndHide()
      @viewManager?.hideRename()
      if !@isValidEditor(item)
        @reference.hide()
    @disposables.push atom.config.observe 'atom-ternjs.inlineFnCompletion', =>
      @inlineFnCompletion = atom.config.get('atom-ternjs.inlineFnCompletion')
      @type?.destroyOverlay()
    @disposables.push atom.config.observe 'atom-ternjs.coffeeScript', =>
      @checkGrammarSettings()

  checkGrammarSettings: ->
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
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:rename': (event) =>
      @viewManager?.showRename()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:markerCheckpointBack': (event) =>
      @helper?.markerCheckpointBack()
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
    @server?.stop()
    @server = null

  restartServer: ->
    @server?.stop()
    @server = null
    @startServer()
