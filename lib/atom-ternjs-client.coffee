$ = require('jquery')
$.ajaxSetup({ cache: false })
Helper = require './atom-ternjs-helper'

module.exports =
class AtomTernjsClient

  port: null
  helper: null

  constructor: ->
    @helper = new Helper()

  completions: (file, end) ->
    @post(JSON.stringify
      query:
        type: 'completions'
        file: file
        end: end
        types: true
        sort: atom.config.get('atom-ternjs.sort')
        guess: atom.config.get('atom-ternjs.guess')
        docs: atom.config.get('atom-ternjs.docs')
        lineCharPositions: true
        caseInsensitive: atom.config.get('atom-ternjs.caseInsensitive')
    )

  refs: (file, end) ->
    @post(JSON.stringify
      query:
        type: 'refs'
        file: file
        end: end
    )

  update: (file, text) ->
    @post(JSON.stringify
      files: [
          type: 'full'
          name: file
          text: text
      ]
    )

  definition: ->
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    position = cursor.getBufferPosition()
    file = editor.getURI()
    end = {line: position.row, ch: position.column}
    text = editor.getText()

    @post(JSON.stringify
      query:
        type: 'definition'
        file: file
        end: end
    ).then (data) =>
      if data?.start
        @helper.openFileAndGoTo(data.start, data.file, editor)
    , (err) ->
      console.error 'error', err

  post: (data) ->
    $.post("http://localhost:#{@port}", data).then (data) ->
      data
