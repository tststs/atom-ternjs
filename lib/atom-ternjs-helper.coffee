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

  openFileAndGoTo: (start, file, editor) ->
    # check if definition is in active TextEditor
    if editor.getPath().indexOf(file) > -1
      cursor = editor.getLastCursor()
      buffer = editor.getBuffer()
      cursor.setBufferPosition(buffer.positionForCharacterIndex(start))
      return
    # else open the file and set cursor position to definition
    atom.workspace.open(file).then (textEditor) ->
      buffer = textEditor.getBuffer()
      cursor = textEditor.getLastCursor()
      cursor.setBufferPosition(buffer.positionForCharacterIndex(start))
