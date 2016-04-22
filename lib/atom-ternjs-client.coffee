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

  updateFull: (editor, editorMeta) ->
    editorMeta?.diffs = []
    @post('query', files: [
        type: 'full'
        name: atom.project.relativizePath(editor.getURI())[1]
        text: editor.getText()
      ]
    )

  updatePart: (editor, editorMeta, start, text) ->
    editorMeta?.diffs = []
    @post('query', files: [
        type: 'part'
        name: atom.project.relativizePath(editor.getURI())[1]
        offset: {line: start, ch: 0}
        text: editor.getText()
      ]
    )

  update: (editor) ->
    editorMeta = @manager.getEditor(editor)
    file = atom.project.relativizePath(editor.getURI())[1].replace(/\\/g, '/')
    # check if this file is excluded via dontLoad
    return Promise.resolve({}) if @manager.server?.dontLoad(file)
    # check if the file is registered, else return
    @files().then (data) =>
      registered = data.files.indexOf(file) > -1
      return Promise.resolve({}) if editorMeta and editorMeta.diffs.length is 0 and registered
      if registered
        buffer = editor.getBuffer()
        # if buffer.getMaxCharacterIndex() > 5000
        #   start = 0
        #   end = 0
        #   text = ''
        #   for diff in editorMeta.diffs
        #     start = Math.max(0, diff.oldRange.start.row - 50)
        #     end = Math.min(buffer.getLineCount(), diff.oldRange.end.row + 5)
        #     text = buffer.getTextInRange([[start, 0], [end, buffer.lineLengthForRow(end)]])
        #   promise = @updatePart(editor, editorMeta, start, text)
        # else
        promise = @updateFull(editor, editorMeta)
      else
        Promise.resolve({})
    , (err) ->
      console.log err

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
