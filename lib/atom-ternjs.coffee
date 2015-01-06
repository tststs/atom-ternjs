TernServerFactory = require './atom-ternjs-server'
ClientFactory = require './atom-ternjs-client'
AtomTernjsAutocompleteFactory = require './atom-ternjs-autocomplete'
_ = require 'underscore-plus'
apd = require 'atom-package-dependencies'
provider = null

class AtomTernInitializer

  disposables: []
  grammars: ['JavaScript', 'CoffeeScript']
  client: null

  # autocomplete
  autocomplete = null
  ap = null
  editorSubscription: null
  providers: []

  activate: (state) ->
    @startServer()
    @registerEvents()

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
    @unregisterProviders()

  unregisterProviders: ->
    @providers.forEach (provider) =>
      @autocomplete.unregisterProvider provider
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

  registerEditors: ->

    @editorSubscription = atom.workspace.observeTextEditors (editor) =>
      @registerEditor(editor)

    # @editorSubscription = atom.workspaceView.eachEditorView (editorView) =>
    #   if editorView.attached and not editorView.mini
    #     @registerEditor (editorView)

  registerEditor: (editor) ->
    #editor = editorView.editor
    editorView = atom.views.getView(editor)
    return unless editorView?
    if editorView.mini
      return
    grammar = editor.getGrammar().name
    if grammar not in @grammars
      return
    buffer = editor.getBuffer()
    #provider = new AtomTernjsAutocompleteFactory(editorView, @client, @ap)
    provider = new AtomTernjsAutocompleteFactory(editor, @client, @ap)
    #provider = new AtomTernjsAutocompleteFactory.ProviderClass(@autocomplete.Provider, @autocomplete.Suggestion)
    @disposables.push buffer.onDidStopChanging =>
      _.throttle @update(editor), 2000
    @disposables.push buffer.onDidStopChanging =>
      @callPreBuildSuggestions()
    #@autocomplete.registerProviderForEditorView provider, editorView
    @autocomplete.registerProviderForEditor provider, editor
    # force maxItems for now
    for view in @autocomplete.autocompleteManagers
      grammar = view.editor.getGrammar().name
      if grammar in @grammars
        view.maxItems = 250
    @providers.push provider

  callPreBuildSuggestions: ->
    editor = atom.workspace.getActiveEditor()
    cursor = editor.getCursor()
    prefix = cursor.getCurrentWordPrefix()
    if /^[a-z0-9.\"\']$/i.test(prefix[prefix.length - 1])
      provider.preBuildSuggestions()
    else
      provider.cancelAutocompletion()

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
      if !@client
        @client = new ClientFactory()
      @client.port = port
      if !@ap
        @activatePackage()
        @registerCommands()

  registerCommands: ->
    atom.workspaceView.command 'tern:definition', =>
      @findDefinition(atom.workspace.getActiveEditor())
    atom.workspaceView.command 'tern:stop', =>
      @stopServer()
    atom.workspaceView.command 'tern:start', =>
      @startServer()

  stopServer: ->
    unless @server?.process
      return
    @server.stop()

#epose init class
module.exports = new AtomTernInitializer()
