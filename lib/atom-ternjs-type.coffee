TypeView = require './atom-ternjs-type-view'
{Point} = require 'atom'

module.exports =
class Type

  view: null
  manager: null
  overlayDecoration: null

  constructor: (manager, state = {}) ->
    @manager = manager

    @view = new TypeView()
    @view.initialize(state)

    atom.views.getView(atom.workspace).appendChild(@view)

  setPosition: ->
    editor = atom.workspace.getActiveTextEditor()
    marker = editor.getLastCursor?().getMarker()
    return unless marker
    @overlayDecoration = editor.decorateMarker(marker, {type: 'overlay', item: @view, class: 'atom-ternjs-type', position: 'tale', invalidate: 'touch'})

  destroyOverlay: ->
    @overlayDecoration?.destroy()
    @overlayDecoration = null

  queryType: (editor) ->
    @destroyOverlay()

    cursor = editor.getLastCursor()
    lineText = cursor.getCurrentBufferLine()

    return if lineText.indexOf('..') != -1

    positionInLine = cursor.getBufferPosition()
    before = lineText.substring(0, positionInLine.column)
    after = lineText.substring(positionInLine.column, lineText.length)

    idxBefore = before.lastIndexOf('(')
    idxAfter = after.lastIndexOf(')')
    return unless idxBefore > -1 and idxAfter > -1

    positionAtParentheses = new Point(positionInLine.row, idxBefore)

    @manager.client.update(editor.getURI(), editor.getText()).then =>
      @manager.client.type(editor, positionAtParentheses).then (data) =>
        return unless data and data.exprName
        data.type = data.type.replace('fn', data.exprName).replace('->', ':')
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
    @destroyOverlay()
    @view?.destroy()
    @view = null
