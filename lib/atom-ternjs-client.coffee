$ = require('jquery')

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
        guess: true
        docs: atom.config.get('atom-ternjs.displayDocsIfAvailable')
        lineCharPositions: true
        caseInsensitive: true
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
