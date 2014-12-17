TernServerFactory = require './atom-ternjs-server'
ClientFactory = require './atom-ternjs-client'
AtomTernjsAutocompleteFactory = require './atom-ternjs-autocomplete'
_ = require 'underscore-plus'
apd = require 'atom-package-dependencies'
client = null
provider = null

class AtomTernInitializer

  disposables: []

  # autocomplete
  autocomplete = null
  ap = null
  editorSubscription: null
  providers: []

  activate: (state) ->
    @startServer()

  activatePackage: ->
    atom.packages.activatePackage('autocomplete-plus')
      .then (pkg) =>
        @ap = apd.require('autocomplete-plus')
        @autocomplete = pkg.mainModule
        @registerEditors()

  deactivate: ->
    @stopServer()
    @unregisterEvents()
    # autocomplete
    @editorSubscription?.off()
    @editorSubscription = null
    @providers.forEach (provider) =>
      @autocomplete.unregisterProvider provider
    @providers = []

  update: (editor) ->
    client.update(editor.getUri(), editor.getText())

  findDefinition: ->
    editor = atom.workspace.getActiveEditor()
    cursor = editor.getCursor()
    position = cursor.getBufferPosition()
    client.definition(editor.getUri(),
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
    atom.workspace.onDidAddTextEditor ({item, pane, index}) =>
      @registerEditor(pane.items[index])

    @disposables.push atom.workspace.onDidOpen (e) =>
      if e.item.getGrammar().name is 'JavaScript'
        @startServer()

  registerEditors: ->
    @editorSubscription = atom.workspaceView.eachEditorView (editorView) =>
      if editorView.attached and not editorView.mini
        @registerEditor (editorView)

  registerEditor: (editorView) ->
    editor = editorView.editor
    if editor.getGrammar().name isnt 'JavaScript'
      return
    buffer = editor.getBuffer()
    provider = new AtomTernjsAutocompleteFactory(editorView, client, @ap)
    @disposables.push buffer.onDidStopChanging =>
      _.throttle @update(editor), 2000
    @disposables.push buffer.onDidStopChanging =>
      @callPreBuildSuggestions()
    @autocomplete.registerProviderForEditorView provider, editorView
    @providers.push provider

  callPreBuildSuggestions: ->
    editor = atom.workspace.getActiveEditor()
    cursor = editor.getCursor()
    prefix = cursor.getCurrentWordPrefix()
    if /^[a-z0-9.\"\']$/i.test(prefix[prefix.length - 1])
      provider.preBuildSuggestions()

  unregisterEvents: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  startServer: ->
    if @server?.process
      return
    if !atom.project.getRootDirectory()
      return
    @server = new TernServerFactory()
    @server.start (port) =>
      @ternPort = port
      client = new ClientFactory(port)
      @activatePackage()
      atom.workspaceView.command 'tern:definition', =>
        @findDefinition(atom.workspace.getActiveEditor())

  stopServer: ->
    unless @server?.process
      return
    @server.stop()

#epose init class
module.exports = new AtomTernInitializer()
