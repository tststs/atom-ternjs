$ = require('jquery')
$.ajaxSetup({ cache: false })

module.exports =
class AtomTernjsClient

  port: null

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
        # check if definition is in active TextEditor
        if editor.getPath().indexOf(data.file) > -1
          buffer = editor.getBuffer()
          cursor.setBufferPosition(buffer.positionForCharacterIndex(data.start))
          return
        # else open the file and set cursor position to definition
        atom.workspace.open(data.file).then (textEditor) ->
          buffer = textEditor.getBuffer()
          cursor = textEditor.getLastCursor()
          cursor.setBufferPosition(buffer.positionForCharacterIndex(data.start))
    , (err) ->
      console.error 'error', err

  post: (data) ->
    $.post("http://localhost:#{@port}", data).then (data) ->
      data
