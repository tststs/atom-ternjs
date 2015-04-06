DocumentationView = require './atom-ternjs-documentation-view'

module.exports =
class Documentation

  documentation: null
  disposables: []
  orientation: null
  position: null

  constructor: (state = {}) ->
    @documentation = new DocumentationView()
    @documentation.initialize(this)

    atom.views.getView(atom.workspace).appendChild(@documentation)
    @registerEvents()

  setPosition: ->
    if @position is 'force top'
      @documentation.classList.add('top')
      return

    if @position is 'force bottom'
      @documentation.classList.add('bottom')
      return

    if @position is 'force middle'
      @documentation.classList.add('middle')
      return

    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    cursorTop = cursor.getPixelRect().top - editor.getScrollTop()
    editorHeight = editor.getHeight()

    if editorHeight - cursorTop <= 180
      @documentation.classList.remove('bottom')
      @documentation.classList.add('top')
    else
      @documentation.classList.remove('top')
      @documentation.classList.add('bottom')

  goToOrigin: (e) ->
    file = e.target.dataset.origin
    atom.workspace.open(file)

  removeClasses: ->
    @documentation.classList.remove('bottom', 'top', 'middle')

  registerEvents: ->
    @disposables.push atom.config.observe('atom-ternjs.docsPosition', =>
      @position = atom.config.get('atom-ternjs.docsPosition')
      @removeClasses()
    )

  set: (suggestion) ->
    @documentation.setTitle(suggestion.leftLabel, suggestion._rightLabelDoc or suggestion.text)
    @documentation.setContent(suggestion._ternDocs, suggestion._ternUrl, suggestion._ternOrigin)
    @setPosition()
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
