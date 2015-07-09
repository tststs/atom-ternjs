Helper = require './atom-ternjs-helper'
Config = require './atom-ternjs-config'
Server = null
Client = null

module.exports =
class Manager

  disposables: []
  grammars: ['JavaScript']
  clients: []
  client: null
  servers: []
  server: null
  helper: null
  rename: null
  config: null
  useSnippets: false
  useSnippetsAndFunction: false
  doNotAddParantheses: false
  type: null
  useLint: null
  reference: null
  provider: null
  initialised: false
  inlineFnCompletion: false

  constructor: (provider) ->
    @provider = provider
    @helper = new Helper(this)
    @config = new Config(this)
    @registerHelperCommands()
    @provider.init(this)
    @initServers()
    @disposables.push atom.project.onDidChangePaths (paths) =>
      @destroyServer(paths)
      @checkPaths(paths)
      @setActiveServerAndClient()

  init: ->
    @initialised = true
    @registerEvents()
    @registerCommands()

  destroy: ->
    for server in @servers
      server.stop()
      server = null
    @servers = []
    for client in @clients
      client.unregisterEvents()
      client = null
    @clients = []
    @server = null
    @client = null
    @unregisterEventsAndCommands()
    @provider = null
    @config?.destroy()
    @config = null
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

  initServers: ->
    dirs = atom.project.getDirectories()
    return unless dirs.length
    for i in [0..dirs.length - 1]
      dir = atom.project.relativizePath(dirs[i].path)[0]
      @startServer(dir)

  startServer: (dir) ->
    Server = require './atom-ternjs-server' if !Server
    return if @getServerForProject(dir)
    idxServer = @servers.push(new Server(dir)) - 1
    @servers[idxServer].start (port) =>
      client = @getClientForProject(dir)
      if !client
        Client = require './atom-ternjs-client' if !Client
        clientIdx = @clients.push(new Client(this, dir)) - 1
        @clients[clientIdx].port = port
      else
        client.port = port
      if @servers.length is @clients.length
        @init() if !@initialised
        @setActiveServerAndClient(dir)

  setActiveServerAndClient: (URI) ->
    if !URI
      activePane = atom.workspace.getActivePaneItem()
      URI = if activePane then activePane.getURI?() else false
    if !URI
      @server = null
      @client = null
      return
    dir = atom.project.relativizePath(URI)[0]
    server = @getServerForProject(dir)
    client = @getClientForProject(dir)
    if server and client
      @server = server
      @config.gatherData()
      @client = client
    else
      @server = null
      @config.clear()
      @client = null

  checkPaths: (paths) ->
    for path in paths
      dir = atom.project.relativizePath(path)[0]
      @startServer(dir)

  destroyServer: (paths) ->
    return unless @servers.length
    serverIdx = undefined
    for i in [0..@servers.length - 1]
      if paths.indexOf(@servers[i].rootPath) is -1
        serverIdx = i
    return if serverIdx is undefined
    server = @servers[serverIdx]
    client = @getClientForProject(server.rootPath)
    client?.unregisterEvents()
    client = null
    server.stop()
    server = null
    @servers.splice(serverIdx, 1)

  getServerForProject: (rootPath) ->
    for server in @servers
      return server if server.rootPath is rootPath
    return

  getClientForProject: (rootPath) ->
    for client in @clients
      return client if client.rootPath is rootPath
    return

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
      @config?.clear()
      @type?.destroyOverlay()
      @rename?.hide()
      if !@isValidEditor(item)
        @reference?.hide()
      else
        @setActiveServerAndClient(item.getURI())
    @disposables.push atom.config.observe 'atom-ternjs.inlineFnCompletion', =>
      @inlineFnCompletion = atom.config.get('atom-ternjs.inlineFnCompletion')
      @type?.destroyOverlay()
    @disposables.push atom.config.observe 'atom-ternjs.lint', =>
      @useLint = atom.config.get('atom-ternjs.lint')
    @disposables.push atom.config.observe 'atom-ternjs.useSnippets', (value) =>
      @useSnippets = value
      return unless value
      atom.config.set('atom-ternjs.doNotAddParantheses', false)
    @disposables.push atom.config.observe 'atom-ternjs.useSnippetsAndFunction', (value) =>
      @useSnippetsAndFunction = value
      return unless value
      atom.config.set('atom-ternjs.doNotAddParantheses', false)
    @disposables.push atom.config.observe 'atom-ternjs.doNotAddParantheses', (value) =>
      @doNotAddParantheses = atom.config.get('atom-ternjs.lint')
      return unless value
      atom.config.set('atom-ternjs.useSnippets', false)
      atom.config.set('atom-ternjs.useSnippetsAndFunction', false)

  addGrammar: (grammar) ->
    return unless @grammars.indexOf(grammar) is -1
    @grammars.push grammar

  removeGrammar: (grammar) ->
    idx = @grammars.indexOf(grammar)
    return if idx is -1
    @grammars.splice(idx, 1)

  registerHelperCommands: ->
    @disposables.push atom.commands.add 'atom-workspace', 'tern:openConfig': (event) =>
      if !@config
        Config = require './atom-ternjs-config'
        @config = new Config(this)
      @config.show()

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
    @disposables.push atom.commands.add 'atom-workspace', 'tern:restart': (event) =>
      @restartServer()

  restartServer: ->
    return unless @server
    dir = @server.rootPath
    for i in [0..@servers.length - 1]
      if dir is @servers[i].rootPath
        serverIdx = i
        break
    @server?.stop()
    @server = null
    @servers.splice(serverIdx, 1)
    @startServer(dir)
