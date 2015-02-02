ReferenceView = require './atom-ternjs-reference-view'

module.exports =
class Reference

  reference: null
  disposables: []
  client: null

  constructor: (client, state = {}) ->
    state.attached ?= true

    @client = client

    @reference = new ReferenceView()
    @reference.initialize(state)
    @referencePanel = atom.workspace.addBottomPanel(item: @reference, priority: 0)
    @referencePanel.hide()

    atom.views.getView(@referencePanel).classList.add("atom-ternjs-reference-panel", "panel-bottom")

    @registerEvents()
    @registerCommands()

  registerCommands: ->
    @disposables.push atom.commands.add 'atom-text-editor', 'tern:references': (event) =>
      @findReference()

  registerEvents: ->
    close = @reference.getClose()
    close.addEventListener('click', (e) =>
      @hide()
      editor = atom.workspace.getActiveTextEditor()
      return unless editor
      view = atom.views.getView(editor)
      view?.focus?()
    )

  findReference: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor
    cursor = editor.getLastCursor()
    position = cursor.getBufferPosition()
    @client.refs(editor.getURI(), {line: position.row, ch: position.column}).then (data) =>
      @referencePanel?.show()
      @reference.buildItems(data)

  hide: ->
    @referencePanel?.hide()

  show: ->
    @referencePanel?.show()

  destroy: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

    @reference?.destroy()
    @reference = null

    @referencePanel?.destroy()
    @referencePanel = null
