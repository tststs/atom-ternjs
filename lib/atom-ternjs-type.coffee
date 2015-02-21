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
    return unless cursor

    tolerance = 10
    rowStart = 0
    position = cursor.getBufferPosition()
    lineCount = editor.getLineCount()

    if (position.row - tolerance < 0)
      rowStart = 0
    else
      rowStart = position.row - tolerance

    buffer = editor.getBuffer()
    rangeBefore = false
    tmp = false
    may = false
    skipCounter = 0
    paramPosition = 0
    cancel = false

    buffer.backwardsScanInRange(/\(|\)|\,|\{|\}/g, [[rowStart, 0], [position.row, position.column]], (obj) =>

      if obj.matchText is '}'
        may = true
        return

      if obj.matchText is '{'
        if !may
          rangeBefore = false
          obj.stop()
          return
        may = false
        return

      if obj.matchText is ',' and not skipCounter
        paramPosition++
        return

      if obj.matchText is ')' and tmp is false
        skipCounter++
        return

      if obj.matchText is '(' and skipCounter
        skipCounter--
        return

      if obj.matchText is '(' and tmp is false
        rangeBefore = obj.range
        obj.stop()
        return

      tmp = obj.matchText
    )

    return unless rangeBefore

    text = buffer.getTextInRange([[rangeBefore.start.row, 0], [rangeBefore.start.row, rangeBefore.start.column]])

    return if !text.replace(/\s/g, '').length
    return if text.match(/\bif\b/)

    @manager.client.update(editor.getURI(), editor.getText()).then =>
      @manager.client.type(editor, rangeBefore.start).then (data) =>
        console.log data
        return if data.type is '?'
        return unless data and data.exprName
        data.type = @manager.helper.formatType(data)
        #matches = data.type.match(/(\w{1,}\?{0,}: (\w|\?|\[\?\]){1,})/g)
        matches = data.type.match(/(\w{1,}\?{0,}: (\w|\?|\[\?\]){1,}(\(\))?)/g)
        if matches?[paramPosition]
          data.type = data.type.replace(matches[paramPosition], '<span class=\"current-param\">' + matches[paramPosition] + '</span>')
        @view.setData({
          word: data.exprName,
          label: data.type
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
