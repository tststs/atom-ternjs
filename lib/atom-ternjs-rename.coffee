{Point, Range} = require 'atom'
_ = require 'underscore-plus'

module.exports =
class Rename

  rename: null
  disposables: []
  manager: null
  title: 'Rename'
  sub: 'Rename a variable in a scope-aware way. (experimental)'

  constructor: (manager, state = {}) ->
    state.attached ?= true
    @manager = manager

  hide: ->
    @manager.viewManager.hideRename()

  updateAllAndRename: (newName) ->
    idx = 0
    editors = atom.workspace.getTextEditors()
    for editor in editors
      if !@manager.isValidEditor(editor)
        idx++
        continue
      @manager.client.update(editor.getURI(), editor.getText()).then =>
        if ++idx is editors.length
          editor = atom.workspace.getActiveEditor()
          cursor = editor.getLastCursor()
          return unless cursor
          position = cursor.getBufferPosition()
          @manager.client?.rename(editor.getURI(), {line: position.row, ch: position.column}, newName).then (data) =>
            return unless data
            @rename(data)
          , (err) ->
            content = "atom-ternjs<br />#{err.responseText}"
            atom.notifications.addError(content, dismissable: false)

  rename: (obj) ->
    dir = atom.project.getDirectories()[0]
    return unless dir

    that = this

    translateColumnBy = obj.changes[0].text.length - obj.name.length

    for change in obj.changes
      change.file = change.file.replace(/^.\//, '')
      change.file = dir.relativize(change.file)
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
    that = this
    atom.workspace.open(obj[0].file).then (textEditor) ->
      currentColumnOffset = 0
      buffer = textEditor.getBuffer()
      for change, i in obj
        that.setTextInRange(buffer, change, currentColumnOffset, (i is obj.length - 1), textEditor)
        currentColumnOffset += translateColumnBy

  setTextInRange: (buffer, change, offset, moveCursor, textEditor) ->
    change.start += offset
    change.end += offset
    position = buffer.positionForCharacterIndex(change.start)
    length = change.end - change.start
    end = position.translate(new Point(0, length))
    range = new Range(position, end)
    buffer.setTextInRange(range, change.text)
    return unless moveCursor
    textEditor.getLastCursor()?.setBufferPosition(start)
