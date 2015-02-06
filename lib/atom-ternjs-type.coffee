TypeView = require './atom-ternjs-type-view'
{Point} = require 'atom'

module.exports =
class Type

  type: null
  disposables: []
  client: null

  constructor: (client, state = {}) ->
    state.attached ?= true

    @client = client

    @type = new TypeView()
    @type.initialize(state)

    @typePanel = atom.workspace.addRightPanel(item: @type, priority: 0)
    @typePanel.hide()

    atom.views.getView(@typePanel).classList.add("atom-ternjs-documentation-panel", "panel-right")

  set: (data) ->
    @show()

  queryType: ->
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    lineText = cursor.getCurrentBufferLine()
    positionInLine = cursor.getBufferPosition()
    before = lineText.substring(0, positionInLine.column)
    after = lineText.substring(positionInLine.column, lineText.length)

    idxBefore = before.indexOf('(')
    idxAfter = after.indexOf(')')
    return unless idxBefore > -1 and idxAfter > -1

    positionAtParentheses = new Point(positionInLine.row, idxBefore)

    @client.type(editor, positionAtParentheses).then (data) =>
      return unless data
      @set({
        word: data.exprName,
        label: data.type,
        docs: {
          doc: data.doc,
          url: data.url,
          origin: data.origin,
        }
      })

  hide: ->
    @documentationPanel?.hide()

  show: ->
    @documentationPanel?.show()

  destroy: ->
    @documentation?.destroy()
    @documentation = null
