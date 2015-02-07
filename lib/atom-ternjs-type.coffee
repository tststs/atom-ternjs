TypeView = require './atom-ternjs-type-view'
{Point} = require 'atom'

module.exports =
class Type

  view: null
  disposables: []
  client: null
  overlayDecoration: null
  marker: null

  constructor: (client, state = {}) ->
    @client = client

    @view = new TypeView()
    @view.initialize(state)

    atom.views.getView(atom.workspace).appendChild(@view)

  setPosition: ->
    editor = atom.workspace.getActiveTextEditor()
    @marker = editor.getLastCursor()?.getMarker()
    @overlayDecoration = editor.decorateMarker(@marker, {type: 'overlay', item: @view, class: 'atom-ternjs-type', position: 'tale', invalidate: 'touch'})

  destroyOverlay: ->
    @overlayDecoration?.destroy()
    @overlayDecoration = null

  queryType: ->
    @destroyOverlay()
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()

    lineText = cursor.getCurrentBufferLine()
    positionInLine = cursor.getBufferPosition()
    before = lineText.substring(0, positionInLine.column)
    after = lineText.substring(positionInLine.column, lineText.length)

    idxBefore = before.lastIndexOf('(')
    idxAfter = after.lastIndexOf(')')
    return unless idxBefore > -1 and idxAfter > -1

    positionAtParentheses = new Point(positionInLine.row, idxBefore)

    @client.type(editor, positionAtParentheses).then (data) =>
      return unless data and data.exprName
      @view.setData({
        word: data.exprName,
        label: data.type,
        docs: {
          doc: data.doc,
          url: data.url,
          origin: data.origin,
        }
      })
      @setPosition()

  hide: ->
    @view.classList.remove('active')

  show: ->
    @view.classList.add('active')

  destroy: ->
    @view?.destroy()
    @view = null
