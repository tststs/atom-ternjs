DocumentationView = require './atom-ternjs-documentation-view'

module.exports =
class Reference

  documentation: null
  disposables: []
  orientation: null

  constructor: (state = {}) ->
    @documentation = new DocumentationView()
    @documentation.initialize(state)

    atom.views.getView(atom.workspace).appendChild(@documentation)

  setPosition: ->
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    cursorTop = cursor.getPixelRect().top - editor.getScrollTop()
    editorHeight = editor.getHeight()

    if editorHeight - cursorTop <= 180
      @documentation.classList.remove('bottom')
      @documentation.classList.add('top')
      return

    if editorHeight - cursorTop > 180
      @documentation.classList.remove('top')
      @documentation.classList.add('bottom')

  set: (data) ->
    @setPosition()
    @documentation.setTitle(data.word, data.label)
    @documentation.setContent(data.docs)
    @show()

  hide: ->
    @documentation.classList.remove('active')

  show: ->
    @documentation.classList.add('active')

  destroy: ->
    @documentation?.destroy()
    @documentation = null
