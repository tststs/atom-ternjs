module.exports =
class Client

  port: null
  manager: null
  projectDir: null

  constructor: (manager, projectDir) ->
    @manager = manager
    @projectDir = projectDir

  completions: (file, end) ->
    @post(JSON.stringify
      query:
        type: 'completions'
        file: file
        end: end
        types: true
        includeKeywords: true
        sort: @manager.packageConfig.options.sort
        guess: @manager.packageConfig.options.guess
        docs: @manager.packageConfig.options.documentation
        urls: @manager.packageConfig.options.urls
        origins: @manager.packageConfig.options.origins
        lineCharPositions: true
        caseInsensitive: @manager.packageConfig.options.caseInsensitive
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
        @manager.helper?.setMarkerCheckpoint()
        @manager.helper?.openFileAndGoTo(data.start, data.file)
    , (err) ->
      console.log err

  post: (data) ->
    fetch("http://localhost:#{@port}",
      method:
        'post'
      body:
        data
      ).then (response) ->
        if response.ok
          response.json().then (data) ->
            data
