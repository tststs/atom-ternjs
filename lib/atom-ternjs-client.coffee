module.exports =
class Client

  port: null
  manager: null
  projectDir: null

  constructor: (manager, projectDir) ->
    @manager = manager
    @projectDir = projectDir

  completions: (file, end) ->
    @post('query', query:
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

  documentation: (file, end) ->
    @post('query', query:
      type: 'documentation'
      file: file
      end: end
    )

  refs: (file, end) ->
    @post('query', query:
      type: 'refs'
      file: file
      end: end
    )

  update: (editor) ->
    _editor = @manager.getEditor(editor)
    file = atom.project.relativizePath(editor.getURI())[1].replace(/\\/g, '/')
    # check if this file is excluded via dontLoad
    return Promise.resolve({}) if @manager.server?.dontLoad(file)
    # check if the file is registered, else return
    @files().then (data) =>
      registered = data.files.indexOf(file) > -1
      return Promise.resolve({}) if _editor and _editor.diffs.length is 0 and registered
      _editor?.diffs = []
      promise = @post('query', files: [
          type: 'full'
          name: atom.project.relativizePath(editor.getURI())[1]
          text: editor.getText()
        ]
      )
      if registered
        return promise
      else
        return Promise.resolve({isQueried: true})
    # buffer = editor.getBuffer()
    # if buffer.getMaxCharacterIndex() > 5000
    #   doDiff = true
    #   for diff in _editor.diffs
    #     start = Math.max(0, diff.oldRange.start.row - 50)
    #     end = Math.min(buffer.getLineCount(), diff.oldRange.end.row + 20)
    #   text = buffer.getTextInRange([[start, 0], [end, buffer.lineLengthForRow(end)]])
    # if (false)
      # @post(JSON.stringify
      #   files: [
      #       type: 'part'
      #       name: editor.getURI()
      #       text: text
      #       offsetLines: start
      #   ]
      # )
    # else

  rename: (file, end, newName) ->
    @post('query', query:
      type: 'rename'
      file: file
      end: end
      newName: newName
    )

  lint: (file, text) ->
    @post('query', query:
      type: 'lint'
      file: file,
      files: [
        type: 'full'
        name: file
        text: text
      ]
    )

  type: (editor, position) ->
    file = atom.project.relativizePath(editor.getURI())[1]
    end = {line: position.row, ch: position.column}

    @post('query', query:
      type: 'type'
      file: file
      end: end
      preferFunction: true
    )

  definition: ->
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    position = cursor.getBufferPosition()
    file = atom.project.relativizePath(editor.getURI())[1]
    end = {line: position.row, ch: position.column}

    @post('query', query:
      type: 'definition'
      file: file
      end: end
    ).then (data) =>
      if data?.start
        @manager.helper?.setMarkerCheckpoint()
        @manager.helper?.openFileAndGoTo(data.start, data.file)
    , (err) ->
      console.log err

  files: ->
    @post('query', query:
      type: 'files'
    ).then (data) =>
      data

  post: (type, data) ->
    promise = @manager.server.request(type, data)
    return promise
