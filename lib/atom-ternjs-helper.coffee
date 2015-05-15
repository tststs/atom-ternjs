fs = require 'fs'
path = require 'path'

module.exports =
class Helper

  projectRoot: null
  manager: null
  checkpointsDefinition: []
  ternProjectFileContent: '{\n
    \ "libs": [\n
    \ \ \ "browser",\n
    \ \ \ "ecma5",\n
    \ \ \ "ecma6",\n
    \ \ \ "jquery"\n
    \ ],\n
    \ "loadEagerly": [\n
    \ \ \ "js/**/*.js"\n
    \ ],\n
    \ "plugins": {\n
    \ \ \ "complete_strings": {},\n
    \ \ \ "doc_comment": {\n
    \ \ \ \ "fullDocs": true\n
    \ \ \ }\n
    \ }\n}'

  constructor: (manager) ->
    @manager = manager

  hasTernProjectFile: ->
    return false if !@manager.server
    @projectRoot = @manager.server.rootPath
    return undefined unless @projectRoot
    return true if @fileExists(path.resolve(__dirname, @projectRoot + '/.tern-project')) is undefined
    return false

  createTernProjectFile: ->
    return unless @hasTernProjectFile() is false
    @writeFile(path.resolve(__dirname, @projectRoot + '/.tern-project'))

  fileExists: (path) ->
    try fs.accessSync path, fs.F_OK, (err) =>
      console.log err
    catch e then return false

  writeFile: (path) ->
    fs.writeFile path, @ternProjectFileContent, (err) =>
      atom.workspace.open(path)
      return unless err
      content = 'Could not create .tern-project file. Use the README to manually create a .tern-project file.'
      atom.notifications.addInfo(content, dismissable: true)

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
    that = this
    atom.workspace.open(file).then (textEditor) ->
      buffer = textEditor.getBuffer()
      cursor = textEditor.getLastCursor()
      cursor.setBufferPosition(buffer.positionForCharacterIndex(start))
      that.markDefinitionBufferRange(cursor, textEditor)

  formatType: (data) ->
    return unless data.type
    data.type = data.type.replace(/->/g, ':').replace('<top>', 'window')
    data.type = data.type.replace(/^fn/, data.exprName)

  prepareType: (data) ->
    return unless data.type
    type = data.type.replace(/->/g, ':').replace('<top>', 'window')
    if !type.endsWith(')') or type.match(/\(\)$/)
      type = type.replace(/( : .+)/, '')
    type = type.replace(/^fn\(/, '').replace(/\)$/, '')

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

    if !obj.type.endsWith(')') or obj.type.match(/\(\)$/)
      obj.rightLabel = obj.rightLabelDoc = obj.type.replace(/( : .+)/, '')
    else
      obj.rightLabel = obj.rightLabelDoc = obj.type

    if obj.rightLabel.startsWith('fn')
      if atom.config.get('atom-ternjs.useSnippets')
        params = @extractParams(obj.rightLabel.replace(/^fn\(/, '').replace(/\)$/, ''))
        obj._snippet = @buildSnippet(params, obj.name)
      else
        obj._snippet = "#{obj.name}"
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

  buildSnippet: (params, name) ->
    return "#{name}()" if params.length is 0
    suggestionParams = []
    for param, i in params
      suggestionParams.push "${#{i + 1}:#{param}}"
    "#{name}(#{suggestionParams.join(',')})"

  extractParams: (type) ->
    start = 0
    params = []
    inside = 0
    for i in [0..type.length - 1]
      if i is type.length - 1
        params.push type.substring(start, i + 1)
        break
      if type[i] is ',' and inside is 0
        params.push type.substring(start, i)
        start = i + 1
        continue
      if type[i] is '['
        inside++
        continue
      if type[i] is ']'
        inside--
        continue
      if type[i] is '('
        inside++
        continue
      if type[i] is ')'
        inside--
        continue
      if type[i] is '{'
        inside++
        continue
      if type[i] is '}'
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
