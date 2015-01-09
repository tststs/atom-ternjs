TernServer = require './atom-ternjs-server'
TernClient = require './atom-ternjs-client'
DocumentationView = require './atom-ternjs-documentation-view'
AtomTernjsAutocomplete = require './atom-ternjs-autocomplete'
_ = require 'underscore-plus'
apd = require 'atom-package-dependencies'

class AtomTernInitializer

  disposables: []
  grammars: ['JavaScript', 'CoffeeScript']
  client: null
  documentationView: null
  currentProviderIdx: 0

  # autocomplete
  autocompletePlus = null
  editorSubscription: null
  providers: []

  # config
  config:
    displayDocsIfAvailable:
      type: 'boolean'
      default: true

  activate: (state) ->
    @startServer()
    @registerEvents()
    @addComponents(state)

  serialize: ->
    atomTernjsViewState: @documentationView.serialize()

  activatePackage: ->
    atom.packages.activatePackage('autocomplete-plus')
      .then (pkg) =>
        @autocompletePlus = apd.require('autocomplete-plus')
        @registerEditors()

  deactivate: ->
    @stopServer()
    @unregisterEvents()
    # autocomplete
    @editorSubscription?.off()
    @editorSubscription = null
    @unregisterProviders()

  addComponents: (state) ->
    @documentationView = new DocumentationView(state.atomTernjsViewState)
    atom.workspaceView.append(@documentationView.getElement())

  unregisterProviders: ->
    @providers.forEach (provider) =>
      @autocompletePlus.unregisterProvider provider
    @providers = []

  update: (editor) ->
    @client.update(editor.getUri(), editor.getText())

  findDefinition: ->
    editor = atom.workspace.getActiveEditor()
    cursor = editor.getCursor()
    position = cursor.getBufferPosition()
    @client.definition(editor.getUri(),
      line: position.row
      ch: position.column
    editor.getText()).then (data) =>
      if data?.start
        # check if definition is in current active TextEditor
        if atom.workspace.getActiveTextEditor().getPath().indexOf(data.file) > -1
          buffer = editor.getBuffer()
          cursor.setBufferPosition(buffer.positionForCharacterIndex(data.start))
          return
        # else open the file and set cursor position to definition
        atom.workspace.open(data.file).then (textEditor) ->
          buffer = textEditor.getBuffer()
          cursor = textEditor.getCursor()
          cursor.setBufferPosition(buffer.positionForCharacterIndex(data.start))
          return
    , (err) ->
      console.error 'error', err

  registerEvents: ->
    @disposables.push atom.workspace.onDidOpen (e) =>
      grammar = e.item.getGrammar().name
      if grammar in @grammars
        @startServer()
    @disposables.push atom.workspace.onDidChangeActivePaneItem =>
      @setCurrentProvider()

  setCurrentProvider: ->
    editor = atom.workspace.getActiveEditor()
    for provider, idx in @providers
      if provider.editor.id is editor.id
        @currentProviderIdx = idx
        break

  registerEditors: ->
    @editorSubscription = atom.workspace.observeTextEditors (editor) =>
      @registerEditor(editor)

  registerEditor: (editor) ->
    return unless (editorView = atom.views.getView(editor))?
    return unless !editorView.mini
    return unless editor.getGrammar().name in @grammars
    buffer = editor.getBuffer()
    index = @providers.push new AtomTernjsAutocomplete(editor, @client, @autocompletePlus, @documentationView)
    @disposables.push buffer.onDidStopChanging =>
      _.throttle @update(editor), 2000
    @disposables.push buffer.onDidStopChanging =>
      _.throttle @callPreBuildSuggestions(), 500
    @autocompletePlus.registerProviderForEditor @providers[index - 1], editor

  callPreBuildSuggestions: (force) ->
    editor = atom.workspace.getActiveEditor()
    cursor = editor.getCursor()
    prefix = cursor.getCurrentWordPrefix()
    if force || /^[a-z0-9.\"\']$/i.test(prefix[prefix.length - 1])
      @providers[@currentProviderIdx].preBuildSuggestions()
    else
      @providers[@currentProviderIdx].cancelAutocompletion()

  unregisterEvents: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  startServer: ->
    return unless !@server?.process
    return unless atom.project.getRootDirectory()
    @server = new TernServer()
    @server.start (port) =>
      if !@client
        @client = new TernClient()
      @client.port = port
      if !@autocompletePlus
        @activatePackage()
        @registerCommands()

  registerCommands: ->
    atom.workspaceView.command 'tern:definition', =>
      @findDefinition(atom.workspace.getActiveEditor())
    atom.workspaceView.command 'tern:startCompletion', =>
      @callPreBuildSuggestions(true)
    atom.workspaceView.command 'tern:stop', =>
      @stopServer()
    atom.workspaceView.command 'tern:start', =>
      @startServer()

  stopServer: ->
    return unless @server?.process
    @server.stop()

#expose init class
module.exports = new AtomTernInitializer()
