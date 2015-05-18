linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

class LinterTern extends Linter

  @syntax: 'source.js'
  linterName: 'ternlint'
  _manager: null

  constructor: (editor) ->
    @_manager = atom.packages.enablePackage('atom-ternjs').mainModule.manager
    super(editor)

  lintFile: (filePath, callback) ->
    editor = atom.workspace.getActiveTextEditor()
    buffer = editor.getBuffer()
    URI = editor.getURI()
    text = editor.getText()
    @_manager.client?.update(URI, text).then =>
      @_manager.client?.lint(URI, text).then (data) =>
        console.log data

module.exports = LinterTern
