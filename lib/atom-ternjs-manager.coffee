Helper = require './atom-ternjs-helper'

module.exports =
class Manager

  disposables: []
  grammars: ['JavaScript']
  client: null
  server: null
  helper: null
  rename: null
  type: null
  reference: null
  provider: null
  initialised: false
  inlineFnCompletion: false

  # regexp
  regExp:
    params: /(([\w:\.\$\?\[\]\| ]+)(\([\w:\.\$\?\[\]\|, ]*\))?({[\w:\.\$\?\[\]\|, ]*})?\|?([\w:\.\$\?\[\]\| ]*))/ig

  constructor: (provider) ->
    @provider = provider
    @checkGrammarSettings()
    @helper = new Helper(this)
    @registerHelperCommands()
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
    @client?.unregisterEvents()
    @client = null
    @unregisterEventsAndCommands()
    @provider?.destroy()
    @provider = null
    @reference?.destroy()
    @reference = null
    @rename?.destroy()
    @rename = null
    @type?.destroy()
    @type = null
    @helper?.destroy()
    @helper = null
    @initialised = false

  unregisterEventsAndCommands: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  startServer: ->
    return unless !@server?.process and atom.project.getDirectories()[0]
    Server = require './atom-ternjs-server'
    @server = new Server()
    @server.start (port) =>
      if !@client
        Client = require './atom-ternjs-client'
        @client = new Client(this)
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
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:references': (event) =>
      if !@reference
        Reference = require './atom-ternjs-reference'
        @reference = new Reference(this)
      @reference.findReference()
    @disposables.push atom.workspace.observeTextEditors (editor) =>
      return unless @isValidEditor(editor)
      @disposables.push editor.onDidChangeCursorPosition (event) =>
        if @inlineFnCompletion
          if !@type
            Type = require './atom-ternjs-type'
            @type = new Type(this)
          @type.queryType(editor, event.cursor)
        @rename?.hide()
        return if event.textChanged
      @disposables.push editor.getBuffer().onDidChangeModified (modified) =>
        return unless modified
        @reference?.hide()
      @disposables.push editor.getBuffer().onDidSave (event) =>
        @client?.update(editor.getURI(), editor.getText())
    @disposables.push atom.workspace.onDidChangeActivePaneItem (item) =>
      @type?.destroyOverlay()
      @rename?.hide()
      if !@isValidEditor(item)
        @reference?.hide()
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
      if !@rename
        Rename = require './atom-ternjs-rename'
        @rename = new Rename(this)
      @rename.show()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:markerCheckpointBack': (event) =>
      @helper?.markerCheckpointBack()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:startCompletion': (event) =>
      @provider?.forceCompletion()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:definition': (event) =>
      @client?.definition()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:restart': (event) =>
      @restartServer()

  stopServer: ->
    @server?.stop()
    @server = null

  restartServer: ->
    @server?.stop()
    @server = null
    @startServer()
