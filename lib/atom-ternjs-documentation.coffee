DocumentationView = require './atom-ternjs-documentation-view'

module.exports =
class Reference

  documentation: null
  disposables: []
  orientation: null

  constructor: (state = {}) ->
    state.attached ?= true

    @documentation = new DocumentationView()
    @documentation.initialize(state)

    @addBottom()
    @documentationPanel.hide()

    atom.views.getView(@documentationPanel).classList.add("atom-ternjs-documentation-panel", "panel-bottom")

  addBottom: ->
    @orientation = 'bottom'
    @documentationPanel = atom.workspace.addBottomPanel(item: @documentation, priority: 0)

  addTop: ->
    @orientation = 'right'
    @documentationPanel = atom.workspace.addModalPanel(item: @documentation, priority: 0)

  destroyPanel: ->
    @documentationPanel?.destroy()
    @documentationPanel = null

  setPosition: ->
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    cursorTop = cursor.getPixelRect().top - editor.getScrollTop()
    editorHeight = editor.getHeight()

    if editorHeight - cursorTop <= 200 and @orientation is 'bottom'
      @destroyPanel()
      @addTop()
      return

    if editorHeight - cursorTop > 200 and @orientation is 'right'
      @destroyPanel()
      @addBottom()

  set: (data) ->
    @setPosition()
    @documentation.setTitle(data.word, data.label)
    @documentation.setContent(data.docs)
    @show()

  hide: ->
    @documentationPanel?.hide()

  show: ->
    @documentationPanel?.show()

  destroy: ->
    @documentation?.destroy()
    @documentation = null
