Server = require './atom-ternjs-server'
Client = require './atom-ternjs-client'
Documentation = require './atom-ternjs-documentation'
Type = require './atom-ternjs-type'
Reference = require './atom-ternjs-reference'
Helper = require './atom-ternjs-helper'

module.exports =
class Manager

  disposables: []
  grammars: ['JavaScript']
  client: null
  server: null
  helper: null
  provider: null
  initialised: false

  constructor: (provider) ->
    @provider = provider
    @startServer()
    @helper = new Helper()
    @registerHelperCommands()
    @documentation = new Documentation()
    @type = new Type(this)
    @reference = new Reference(this)
    @disposables.push atom.workspace.onDidOpen (e) =>
      @startServer()

  init: ->
    @initialised = true
    @provider.init(this)
    @registerEvents()
    @registerCommands()

  destroy: ->
    @stopServer()
    @unregisterEventsAndCommands()
    @provider?.destroy()
    @provider = null
    @reference?.destroy()
    @reference = null
    @documentation?.destroy()
    @documentation = null
    @type?.destroy()
    @type = null
    @initialised = false

  unregisterEventsAndCommands: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  startServer: ->
    return unless !@server?.process and atom.project.getDirectories()[0]
    @server = new Server()
    @server.start (port) =>
      @client = new Client() if !@client
      @client.port = port
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
    @server?.stop()
    @server = null

  restartServer: ->
    @server?.stop()
    @server = null
    @startServer()
