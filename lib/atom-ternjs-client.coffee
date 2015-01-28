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

  definition: (file, end, text) ->
    @post(JSON.stringify
      query:
        type: 'definition'
        file: file
        end: end
    )

  post: (data) ->
    $.post("http://localhost:#{@port}", data).then (data) ->
      data
