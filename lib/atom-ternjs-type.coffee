TypeView = require './atom-ternjs-type-view'

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

  queryType: (editor, cursor) ->
    return if cursor.destroyed
    scopeDescriptor = cursor.getScopeDescriptor()
    if scopeDescriptor.scopes.join().match(/comment/)
      @destroyOverlay()
      return

    tolerance = 20
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
    may = 0
    may2 = 0
    skipCounter = 0
    skipCounter2 = 0
    paramPosition = 0
    cancel = false

    buffer.backwardsScanInRange(/\]|\[|\(|\)|\,|\{|\}/g, [[rowStart, 0], [position.row, position.column]], (obj) =>

      return if editor.scopeDescriptorForBufferPosition(obj.range.start).scopes.join().match(/string/)

      if obj.matchText is '}'
        may++
        return

      if obj.matchText is ']'
        if tmp is false
          skipCounter2++
        may2++
        return

      if obj.matchText is '{'
        if !may
          rangeBefore = false
          obj.stop()
          return
        may--
        return

      if obj.matchText is '['
        if skipCounter2
          skipCounter2--
        if !may2
          rangeBefore = false
          obj.stop()
          return
        may2--
        return

      if obj.matchText is ')' and tmp is false
        skipCounter++
        return

      if obj.matchText is ',' and not skipCounter and not skipCounter2 and not may and not may2
        paramPosition++
        return

      if obj.matchText is ','
        return

      if obj.matchText is '(' and skipCounter
        skipCounter--
        return

      if skipCounter or skipCounter2
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
        type = data.type.substring(data.type.indexOf('(') + 1, data.type.length)
        matches = type.match(@manager.regExp.params)
        if matches?[matches.length - 1].startsWith(' :')
          matches.splice(matches.length - 1)
        if matches?[paramPosition]
          offsetFix = if paramPosition > 0 then ' ' else ''
          data.type = data.type.replace(matches[paramPosition], offsetFix + "<span class=\"current-param\">#{matches[paramPosition]}</span>")
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
