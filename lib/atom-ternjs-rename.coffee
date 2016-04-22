RenameView = require './atom-ternjs-rename-view'
{Point, Range} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'

module.exports =
class Rename

  renameView: null
  manager: null

  constructor: (manager, state = {}) ->
    @manager = manager

    @renameView = new RenameView()
    @renameView.initialize(this)
    @renamePanel = atom.workspace.addBottomPanel(item: @renameView, priority: 0)
    @renamePanel.hide()

    atom.views.getView(@renamePanel).classList.add('atom-ternjs-rename-panel', 'panel-bottom')

  hide: ->
    return unless @renamePanel?.isVisible()
    @renamePanel.hide()
    @manager.helper.focusEditor()

  show: ->
    codeEditor = atom.workspace.getActiveTextEditor()

    currentNameRange = codeEditor.getLastCursor().getCurrentWordBufferRange
      includeNonWordCharacters: false

    currentName = codeEditor.getTextInBufferRange(currentNameRange)

    @renameView.nameEditor.getModel().setText(currentName)
    @renameView.nameEditor.getModel().selectAll()

    @renamePanel.show()
    @renameView.nameEditor.focus()

  updateAllAndRename: (newName) ->
    return unless @manager.client
    idx = 0
    editors = atom.workspace.getTextEditors()

    for editor in editors
      if !@manager.isValidEditor(editor)
        idx++
        continue
      if atom.project.relativizePath(editor.getURI())[0] isnt @manager.client.projectDir
        idx++
        continue
      @manager.client.update(editor).then (data) =>
        if ++idx is editors.length
          editor = atom.workspace.getActiveTextEditor()
          cursor = editor.getLastCursor()
          return unless cursor
          position = cursor.getBufferPosition()
          @manager.client.rename(atom.project.relativizePath(editor.getURI())[1], {line: position.row, ch: position.column}, newName).then (data) =>
            return unless data
            @rename(data)
          , (err) ->
            atom.notifications.addError(err, dismissable: false)

  rename: (obj) ->
    dir = @manager.server.projectDir
    return unless dir

    translateColumnBy = obj.changes[0].text.length - obj.name.length

    for change in obj.changes
      change.file = change.file.replace(/^.\//, '')
      change.file = path.resolve(atom.project.relativizePath(dir)[0], change.file)
    changes = _.uniq(obj.changes, (item) =>
      JSON.stringify item
    )

    currentFile = false
    arr = []
    idx = 0
    for change in changes
      if currentFile isnt change.file
        currentFile = change.file
        idx = (arr.push []) - 1
      arr[idx].push change

    for arrObj in arr
      @openFilesAndRename(arrObj, translateColumnBy)

  openFilesAndRename: (obj, translateColumnBy) ->
    atom.workspace.open(obj[0].file).then (textEditor) =>
      currentColumnOffset = 0
      buffer = textEditor.getBuffer()
      checkpoint = buffer.createCheckpoint()
      for change, i in obj
        @setTextInRange(buffer, change, currentColumnOffset, (i is obj.length - 1), textEditor)
        currentColumnOffset += translateColumnBy
      buffer.groupChangesSinceCheckpoint(checkpoint)

  setTextInRange: (buffer, change, offset, moveCursor, textEditor) ->
    change.start += offset
    change.end += offset
    position = buffer.positionForCharacterIndex(change.start)
    length = change.end - change.start
    end = position.translate(new Point(0, length))
    range = new Range(position, end)
    buffer.setTextInRange(range, change.text)
    return unless moveCursor
    textEditor.getLastCursor()?.setBufferPosition(position)

  destroy: ->
    @renameView?.destroy()
    @renameView = null

    @renamePanel?.destroy()
    @renamePanel = null
