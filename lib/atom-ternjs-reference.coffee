ReferenceView = require './atom-ternjs-reference-view'
_ = require 'underscore-plus'

module.exports =
class Reference

  reference: null
  disposables: []
  manager: null

  constructor: (manager, state = {}) ->
    state.attached ?= true

    @manager = manager

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
    dir = atom.project.getDirectories()[0]
    return unless dir
    editor = atom.workspace.getActiveTextEditor()
    return unless editor
    cursor = editor.getLastCursor()
    position = cursor.getBufferPosition()
    @manager.client.refs(editor.getURI(), {line: position.row, ch: position.column}).then (data) =>
      for ref in data.refs
        ref.file = ref.file.replace(/^.\//, '')
        ref.file = dir.relativize(ref.file)
      data.refs = _.uniq(data.refs, (item) =>
        JSON.stringify item
      )
      @referencePanel.show()
      @reference.buildItems(data)

  hide: ->
    @referencePanel.hide()

  show: ->
    @referencePanel.show()

  destroy: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

    @reference?.destroy()
    @reference = null

    @referencePanel?.destroy()
    @referencePanel = null
