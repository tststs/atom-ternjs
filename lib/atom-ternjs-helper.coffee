fs = require 'fs'
path = require 'path'

module.exports =
class Helper

  projectRoot: null
  manager: null
  checkpointsDefinition: []

  constructor: (manager) ->
    @manager = manager
    @projectRoot = @getProjectRoot()

  getProjectRoot: ->
    @projectRoot = atom.project.getDirectories()[0]

  updateTernFile: ->
    @writeFile(path.resolve(__dirname, @projectRoot.path + '/.tern-project'))

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
    if not @projectRoot
      @getProjectRoot()
    return false unless @projectRoot
    if projectRoot
      filePath = @projectRoot.path + filePath
    resolvedPath = path.resolve(__dirname, filePath)
    return false unless @fileExists(resolvedPath) is undefined
    @readFile(resolvedPath)

  markerCheckpointBack: ->
    return unless @checkpointsDefinition.length
    checkpoint = @checkpointsDefinition.pop()
    @openFileAndGoToPosition(checkpoint.marker.range.start, checkpoint.editor.getURI())

  setMarkerCheckpoint: ->
    editor = atom.workspace.getActiveEditor()
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
    that = this
    atom.workspace.open(file).then (textEditor) ->
      buffer = textEditor.getBuffer()
      cursor = textEditor.getLastCursor()
      cursor.setBufferPosition(buffer.positionForCharacterIndex(start))
      that.markDefinitionBufferRange(cursor, textEditor)

  formatType: (data) ->
    str = data.type.replace('fn', data.exprName).replace(/->/g, ':').replace('<top>', 'window')

  formatTypeCompletion: (obj) ->
    if obj.isKeyword
      obj._typeSelf = 'keyword'

    return obj if !obj.type

    if !obj.type.startsWith('fn')
      obj._typeSelf = 'variable'

    if obj.type is 'string'
      obj.name = obj.name?.replace /(^"|"$)/g, ''

    obj.type = obj.type?.replace(/->/g, ':').replace('<top>', 'window')

    if obj.type.replace(/fn\(.+\)/, '').length is 0
      obj.leftLabel = ''
    else
      if obj.type.indexOf('fn') is -1
        obj.leftLabel = obj.type
      else
        obj.leftLabel = obj.type.replace(/fn\(.{0,}\)/, '').replace(' : ', '')

    obj.rightLabel = obj.rightLabelDoc = obj.type.replace(/( : .+)/, '')

    if obj.rightLabel.startsWith('fn')
      obj._snippet = @extractParams(obj.rightLabel.replace(/^fn\(/, '').replace(/\)$/, ''), obj.name)
      obj._typeSelf = 'function'

    if obj.name
      obj.rightLabelDoc = obj.rightLabel.replace(/^fn/, obj.name)
      if obj.leftLabel is obj.name
        obj.leftLabel = null
        obj.rightLabel = null

    if obj.leftLabel is obj.rightLabel
      obj.rightLabelDoc = null
      obj.rightLabel = null

    obj

  extractParams: (type, name) ->
    params = type.match(@manager.regExp.params)
    suggestionParams = []
    return unless params
    for param, i in params
      suggestionParams.push "${#{i + 1}:#{param}}"
    "#{name}(#{suggestionParams.join(',')})"

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
