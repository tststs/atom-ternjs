$ = require('jquery')
$.ajaxSetup({ cache: false })
Helper = require './atom-ternjs-helper'

module.exports =
class Client

  port: null
  helper: null

  constructor: ->
    @helper = new Helper()

  completions: (file, end) ->
    docs = atom.config.get('atom-ternjs.docs')
    @post(JSON.stringify
      query:
        type: 'completions'
        file: file
        end: end
        types: true
        sort: atom.config.get('atom-ternjs.sort')
        guess: atom.config.get('atom-ternjs.guess')
        docs: docs and atom.config.get('atom-ternjs.documentation')
        urls: docs and atom.config.get('atom-ternjs.urls')
        origins: docs and atom.config.get('atom-ternjs.origins')
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

  type: (editor, position) ->
    file = editor.getURI()
    end = {line: position.row, ch: position.column}

    @post(JSON.stringify
      query:
        type: 'type'
        file: file
        end: end
        preferFunction: true
    )

  definition: ->
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    position = cursor.getBufferPosition()
    file = editor.getURI()
    end = {line: position.row, ch: position.column}

    @post(JSON.stringify
      query:
        type: 'definition'
        file: file
        end: end
    ).then (data) =>
      if data?.start
        @helper.openFileAndGoTo(data.start, data.file, editor)
    , (err) ->
      console.log err

  post: (data) ->
    $.post("http://localhost:#{@port}", data).then (data) ->
      data
