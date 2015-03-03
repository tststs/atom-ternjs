TypeView = require './atom-ternjs-type-view'
{Point} = require 'atom'

module.exports =
class Type

  view: null
  manager: null
  overlayDecoration: null
  marker: null

  constructor: (manager, state = {}) ->
    @manager = manager

    @view = new TypeView()
    @view.initialize(state)

    atom.views.getView(atom.workspace).appendChild(@view)

  setPosition: ->
    if !@marker
      editor = atom.workspace.getActiveTextEditor()
      @marker = editor.getLastCursor?().getMarker()
      return unless @marker
      @overlayDecoration = editor.decorateMarker(@marker, {type: 'overlay', item: @view, class: 'atom-ternjs-type', position: 'tale', invalidate: 'touch'})
    else
      @marker.setProperties({type: 'overlay', item: @view, class: 'atom-ternjs-type', position: 'tale', invalidate: 'touch'})

  destroyOverlay: ->
    @overlayDecoration?.destroy()
    @overlayDecoration = null
    @marker = null

  queryType: (editor) ->
    cursor = editor.getLastCursor()
    return unless cursor
    scopeDescriptor = cursor.getScopeDescriptor()
    if scopeDescriptor.scopes.join().match(/comment/)
      @destroyOverlay()
      return

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

      return if editor.scopeDescriptorForBufferPosition(obj.range.start).scopes.join().match(/string/)

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

    if !rangeBefore
      @destroyOverlay()
      return

    text = buffer.getTextInRange([[rangeBefore.start.row, 0], [rangeBefore.start.row, rangeBefore.start.column]])

    if !text.replace(/\s/g, '').length or text.match(/\bif\b/)
      @destroyOverlay()
      return

    @manager.client.update(editor.getURI(), editor.getText()).then =>
      @manager.client.type(editor, rangeBefore.start).then (data) =>
        if !data or data.type is '?' or !data.exprName
          @destroyOverlay()
          return
        data.type = @manager.helper.formatType(data)
        type = data.type.substring(data.type.indexOf('(') + 1, data.type.lastIndexOf(')'))
        matches = type.match(/(\w+:? ?(\{.+\})?\B ?\??(\w+(\(\))?\.?\|?(\([^,\n]+\))?\??:? ?(\??\w*))?)/g)
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
