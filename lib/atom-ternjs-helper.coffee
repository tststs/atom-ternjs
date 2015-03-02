fs = require 'fs'
path = require 'path'

module.exports =
class Helper

  projectRoot: null
  ternProjectFileContent: '{\n
    \ "libs": [\n
    \ \ \ "browser",\n
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

  constructor: ->
    #@init()

  init: ->
    return unless @hasTernProjectFile() is false
    content = 'No .tern-project file was found.<br />Create one via context-menu -> Atom Ternjs -> Create default .tern-project file.'
    atom.notifications.addInfo(content, dismissable: false)

  hasTernProjectFile: ->
    @projectRoot = atom.project.getDirectories()[0]
    return undefined unless @projectRoot
    return true if @fileExists(path.resolve(__dirname, @projectRoot.path + '/.tern-project')) is undefined
    return false

  createTernProjectFile: ->
    return unless @hasTernProjectFile() is false
    @writeFile(path.resolve(__dirname, @projectRoot.path + '/.tern-project'))

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
    return unless @checkPointDefinition
    @openFileAndGoToPosition(@checkPointDefinition.marker.range.start, @checkPointDefinition.editor.getURI())

  setMarkerCheckpoint: ->
    editor = atom.workspace.getActiveEditor()
    buffer = editor.getBuffer()
    cursor = editor.getLastCursor()
    return unless cursor
    @checkPointDefinition?.marker.destroy()
    marker = buffer.markPosition(cursor.getBufferPosition(), {})
    @checkPointDefinition =
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

  formatTypeDocumentation: (data) ->
    if data.label.startsWith('fn')
      data.label = data.label.replace('fn', data.word)
      data.word = false
    data.label = data.label.replace(/->/g, ':').replace('<top>', 'window')
    data

  markDefinitionBufferRange: (cursor, editor) ->
    range = cursor.getCurrentWordBufferRange()
    marker = editor.markBufferRange(range, {invalidate: 'touch'})

    decoration = editor.decorateMarker(marker, type: 'highlight', class: 'atom-ternjs-definition-marker', invalidate: 'touch')
    setTimeout (-> decoration?.setProperties(type: 'highlight', class: 'atom-ternjs-definition-marker active', invalidate: 'touch')), 1
    setTimeout (-> decoration?.setProperties(type: 'highlight', class: 'atom-ternjs-definition-marker', invalidate: 'touch')), 1501
    setTimeout (-> marker.destroy()), 2500
