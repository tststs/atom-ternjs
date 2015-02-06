DocumentationView = require './atom-ternjs-documentation-view'

module.exports =
class Reference

  documentation: null
  disposables: []
  client: null
  orientation: null

  constructor: (client, state = {}) ->
    state.attached ?= true

    @client = client

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
    cursorTop = cursor.getPixelRect().top
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

  # queryType: ->
  #   editor = atom.workspace.getActiveTextEditor()
  #   cursor = editor.getLastCursor()
  #   lineText = cursor.getCurrentBufferLine()
  #   positionInLine = cursor.getBufferPosition()
  #   before = lineText.substring(0, positionInLine.column)
  #   after = lineText.substring(positionInLine.column, lineText.length)
  #
  #   return unless before.indexOf('(') > -1 and after.indexOf(')') > -1
  #
  #   begin = cursor.getBeginningOfCurrentWordBufferPosition()
  #   @client.type(editor, begin).then (data) =>
  #     return unless data
  #     @set({
  #       word: data.exprName,
  #       label: data.type,
  #       docs: {
  #         doc: data.doc,
  #         url: data.url,
  #         origin: data.origin,
  #       }
  #     })

  hide: ->
    @documentationPanel?.hide()

  show: ->
    @documentationPanel?.show()

  destroy: ->
    @documentation?.destroy()
    @documentation = null
