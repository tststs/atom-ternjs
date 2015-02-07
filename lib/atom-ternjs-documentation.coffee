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
    @registerEvents()

  setPosition: ->

    position = atom.config.get('atom-ternjs.docsPosition')

    if position is 'force top'
      @documentation.classList.add('top')
      return

    if position is 'force bottom'
      @documentation.classList.add('bottom')
      return

    if position is 'force middle'
      @documentation.classList.add('middle')
      return

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

  removeClasses: ->
    @documentation.classList.remove('bottom', 'top', 'middle')

  registerEvents: ->
    @disposables.push atom.config.observe('atom-ternjs.docsPosition', => @removeClasses())

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
    for disposable in @disposables
      disposable.dispose()
    @documentation?.destroy()
    @documentation = null
