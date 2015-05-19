$ = require('jquery')
$.ajaxSetup({ cache: false })

module.exports =
class Client

  port: null
  manager: null
  rootPath: null
  disposables: []
  config:
    sort: false
    guess: false
    urls: false
    origins: false
    caseInsensitive: false
    documentation: false

  constructor: (manager, rootPath) ->
    @manager = manager
    @rootPath = rootPath
    @registerEvents()

  registerEvents: ->
    @disposables.push atom.config.observe 'atom-ternjs.sort', =>
      @config.sort = atom.config.get('atom-ternjs.sort')
    @disposables.push atom.config.observe 'atom-ternjs.guess', =>
      @config.guess = atom.config.get('atom-ternjs.guess')
    @disposables.push atom.config.observe 'atom-ternjs.urls', =>
      @config.urls = atom.config.get('atom-ternjs.urls')
    @disposables.push atom.config.observe 'atom-ternjs.origins', =>
      @config.origins = atom.config.get('atom-ternjs.origins')
    @disposables.push atom.config.observe 'atom-ternjs.caseInsensitive', =>
      @config.caseInsensitive = atom.config.get('atom-ternjs.caseInsensitive')
    @disposables.push atom.config.observe 'atom-ternjs.documentation', =>
      @config.documentation = atom.config.get('atom-ternjs.documentation')

  unregisterEvents: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  completions: (file, end) ->
    @post(JSON.stringify
      query:
        type: 'completions'
        file: file
        end: end
        types: true
        includeKeywords: true
        sort: @config.sort
        guess: @config.guess
        docs: @config.documentation
        urls: @config.urls
        origins: @config.origins
        lineCharPositions: true
        caseInsensitive: @config.caseInsensitive
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

  rename: (file, end, newName) ->
    @post(JSON.stringify
      query:
        type: 'rename'
        file: file
        end: end
        newName: newName
    )

  lint: (file, text) ->
    @post(JSON.stringify
      query:
        type: 'lint'
        file: file,
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
        @manager.helper.setMarkerCheckpoint()
        @manager.helper.openFileAndGoTo(data.start, data.file)
    , (err) ->
      console.log err

  post: (data) ->
    $.post("http://localhost:#{@port}", data).then (data) ->
      data
