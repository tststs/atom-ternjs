TernServer = require './atom-ternjs-server'
TernClient = require './atom-ternjs-client'
DocumentationView = require './atom-ternjs-documentation-view'
AtomTernjsAutocomplete = require './atom-ternjs-autocomplete'

class AtomTernInitializer

  disposables: []
  grammars: ['JavaScript']
  client: null
  documentationView: null
  activeTextEditor: null
  editorSubscription: null

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
    @addComponents(state)
    @disposables.push atom.workspace.onDidOpen (e) =>
      return unless e.item and @isValidEditor(e.item)
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
    @registerEditors()

  deactivate: ->
    @stopServer()
    @unregisterEventsAndCommands()
    @editorSubscription?.off()
    @editorSubscription = null
    # autocomplete-plus
    @registration?.dispose()
    @registration = null
    @provider?.cleanup()
    @provider = null

  addComponents: (state) ->
    @documentationView = new DocumentationView(state.atomTernjsViewState)
    atom.views.getView(atom.workspace).appendChild(@documentationView.getElement())

  findDefinition: ->
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    position = cursor.getBufferPosition()
    @client.definition(editor.getURI(),
      line: position.row
      ch: position.column
    editor.getText()).then (data) =>
      if data?.start
        # check if definition is in current active TextEditor
        if editor.getPath().indexOf(data.file) > -1
          buffer = editor.getBuffer()
          cursor.setBufferPosition(buffer.positionForCharacterIndex(data.start))
          return
        # else open the file and set cursor position to definition
        atom.workspace.open(data.file).then (textEditor) ->
          buffer = textEditor.getBuffer()
          cursor = textEditor.getLastCursor()
          cursor.setBufferPosition(buffer.positionForCharacterIndex(data.start))
          return
    , (err) ->
      console.error 'error', err

  isValidEditor: (editor) ->
    return false if editor.mini
    return false if !editor.getGrammar
    return false if editor.getGrammar().name not in @grammars
    return true

  registerEditors: ->
    @editorSubscription = atom.workspace.observeTextEditors (editor) =>
      @disposables.push editor.onDidChangeCursorPosition (event) =>
        if !event.textChanged
          @documentationView.hide()

  unregisterEventsAndCommands: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  startServer: ->
    return unless !@server?.process and atom.project.getDirectories()[0]
    @server = new TernServer()
    @server.start (port) =>
      if !@client
        @client = new TernClient()
      @client.port = port
      if (!@provider)
        @init()

  registerEvents: ->
    @disposables.push atom.config.observe 'atom-ternjs.coffeeScript', =>
      if atom.config.get('atom-ternjs.coffeeScript')
        @provider.addSelector('.source.coffee')
      else
        @provider.removeSelector('.source.coffee')

  registerCommands: ->
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:definition': (event) =>
        @findDefinition()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:startCompletion': (event) =>
      @provider?.forceCompletion()
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:cancel': (event) =>
      @provider?.forceCancel()
      @documentationView.hide()

  stopServer: ->
    return unless @server?.process
    @server.stop()

#expose init class
module.exports = new AtomTernInitializer()
