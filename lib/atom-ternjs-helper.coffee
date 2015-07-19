fs = require 'fs'
path = require 'path'

module.exports =
class Helper

  projectRoot: null
  manager: null
  checkpointsDefinition: []

  constructor: (manager) ->
    @manager = manager

  updateTernFile: (content) ->
    @projectRoot = @manager.server?.rootPath
    return unless @projectRoot
    @writeFile(path.resolve(__dirname, @projectRoot + '/.tern-project'), content)

  fileExists: (path) ->
    try fs.accessSync path, fs.F_OK, (err) =>
      console.log err
    catch e then return false

  writeFile: (filePath, content) ->
    fs.writeFile filePath, content, (err) =>
      atom.workspace.open(filePath)
      return unless err
      message = 'Could not create/update .tern-project file. Use the README to manually create a .tern-project file.'
      atom.notifications.addInfo(message, dismissable: true)

  readFile: (path) ->
    fs.readFileSync path, 'utf8'

  getFileContent: (filePath, projectRoot) ->
    @projectRoot = @manager.server?.rootPath
    return false unless @projectRoot
    if projectRoot
      filePath = @projectRoot + filePath
    resolvedPath = path.resolve(__dirname, filePath)
    return false unless @fileExists(resolvedPath) is undefined
    @readFile(resolvedPath)

  markerCheckpointBack: ->
    return unless @checkpointsDefinition.length
    checkpoint = @checkpointsDefinition.pop()
    @openFileAndGoToPosition(checkpoint.marker.range.start, checkpoint.editor.getURI())

  setMarkerCheckpoint: ->
    editor = atom.workspace.getActiveTextEditor()
    buffer = editor.getBuffer()
    cursor = editor.getLastCursor()
    return unless cursor
    marker = buffer.markPosition(cursor.getBufferPosition(), {})
    @checkpointsDefinition.push
      marker: marker
      editor: editor

  openFileAndGoToPosition: (position, file) ->
    atom.workspace.open(file).then (textEditor) ->
      buffer = textEditor.getBuffer()
      cursor = textEditor.getLastCursor()
      cursor.setBufferPosition(position)

  openFileAndGoTo: (start, file) ->
    atom.workspace.open(file).then (textEditor) =>
      buffer = textEditor.getBuffer()
      cursor = textEditor.getLastCursor()
      cursor.setBufferPosition(buffer.positionForCharacterIndex(start))
      @markDefinitionBufferRange(cursor, textEditor)

  formatType: (data) ->
    return unless data.type
    data.type = data.type.replace(/->/g, ':').replace('<top>', 'window')
    data.type = data.type.replace(/^fn/, data.exprName)

  prepareType: (data) ->
    return unless data.type
    type = data.type.replace(/->/g, ':').replace('<top>', 'window')

  formatTypeCompletion: (obj) ->
    if obj.isKeyword
      obj._typeSelf = 'keyword'

    return obj if !obj.type

    if !obj.type.startsWith('fn')
      obj._typeSelf = 'variable'

    if obj.type is 'string'
      obj.name = obj.name?.replace /(^"|"$)/g, ''

    obj.type = obj.rightLabel = @prepareType(obj)

    if obj.type.replace(/fn\(.+\)/, '').length is 0
      obj.leftLabel = ''
    else
      if obj.type.indexOf('fn') is -1
        obj.leftLabel = obj.type
      else
        obj.leftLabel = obj.type.replace(/fn\(.{0,}\)/, '').replace(' : ', '')

    if obj.rightLabel.startsWith('fn')
      params = @extractParams(obj.rightLabel)
      if @manager.useSnippets || @manager.useSnippetsAndFunction
        obj._snippet = @buildSnippet(params, obj.name)
        obj._hasParams = if params.length then true else false
      else
        if @manager.doNotAddParantheses
          obj._snippet = "#{obj.name}"
        else
          obj._snippet = if params.length then "#{obj.name}(${#{0}:#{}})" else "#{obj.name}()"
      obj._typeSelf = 'function'

    if obj.name
      if obj.leftLabel is obj.name
        obj.leftLabel = null
        obj.rightLabel = null

    if obj.leftLabel is obj.rightLabel
      obj.rightLabel = null

    obj

  buildSnippet: (params, name) ->
    return "#{name}()" if params.length is 0
    suggestionParams = []
    for param, i in params
      suggestionParams.push "${#{i + 1}:#{param}}"
    "#{name}(#{suggestionParams.join(',')})"

  extractParams: (type) ->
    return [] unless type
    start = type.indexOf('(') + 1
    params = []
    inside = 0
    for i in [start..type.length - 1]
      if type[i] is ':' and inside is -1
        params.push type.substring(start, i - 2)
        break
      if i is type.length - 1
        param = type.substring(start, i)
        params.push param if param.length
        break
      if type[i] is ',' and inside is 0
        params.push type.substring(start, i)
        start = i + 1
        continue
      if type[i].match(/[{\[\(]/)
        inside++
        continue
      if type[i].match(/[}\]\)]/)
        inside--
    params

  markDefinitionBufferRange: (cursor, editor) ->
    range = cursor.getCurrentWordBufferRange()
    marker = editor.markBufferRange(range, {invalidate: 'touch'})

    decoration = editor.decorateMarker(marker, type: 'highlight', class: 'atom-ternjs-definition-marker', invalidate: 'touch')
    setTimeout (-> decoration?.setProperties(type: 'highlight', class: 'atom-ternjs-definition-marker active', invalidate: 'touch')), 1
    setTimeout (-> decoration?.setProperties(type: 'highlight', class: 'atom-ternjs-definition-marker', invalidate: 'touch')), 1501
    setTimeout (-> marker.destroy()), 2500

  focusEditor: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor
    view = atom.views.getView(editor)
    view?.focus?()

  destroy: ->
    for checkpoint in @checkpointsDefinition
      checkpoint.marker?.destroy()
