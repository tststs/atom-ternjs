fs = require 'fs'
path = require 'path'

module.exports =
class AtomTernjsHelper

  projectRoot: null
  package: null
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
    return true if @fileExists(path.resolve(__dirname, @projectRoot.path + '/.tern-project'))
    return false

  createTernProjectFile: ->
    return unless @hasTernProjectFile() is false
    @writeFile(path.resolve(__dirname, @projectRoot.path + '/.tern-project'))

  fileExists: (path) ->
    fs.existsSync(path)

  writeFile: (path) ->
    fs.writeFile path, @ternProjectFileContent, (err) =>
      return unless err
      content = 'Could not create .tern-project file. Use the README to manually create a .tern-project file.'
      atom.notifications.addInfo(content, dismissable: true)
