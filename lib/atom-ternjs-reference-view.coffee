Helper = require './atom-ternjs-helper'

class ReferenceView extends HTMLElement

  content: null
  close: null
  data: null
  helper: null

  createdCallback: ->
    @classList.add('atom-ternjs-reference')
    container = document.createElement('div')
    @content = document.createElement('div')
    @close = document.createElement('button')
    @close.classList.add('btn', 'atom-ternjs-reference-close')
    @close.innerHTML = 'Close'
    container.appendChild(@close)
    container.appendChild(@content)
    @appendChild(container)

  initialize: (state) ->
    @helper = new Helper()
    this

  buildItems: (data) ->
    @data = data
    @content.innerHTML = ''
    headline = document.createElement('h2')
    headline.innerHTML = @data.name + " (#{@data.type})"
    @content.appendChild(headline)
    list = document.createElement('ul')
    for item, i in @data.refs
      li = document.createElement('li')
      li.dataset.idx = i;
      li.innerHTML = item.file + ':' + item.start
      li.addEventListener('click', (e) =>
        @goToReference(e)
      )
      list.appendChild(li)
    @content.appendChild(list)

  goToReference: (e) ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor
    idx = e.target.dataset.idx
    ref = @data.refs[idx]
    @helper.openFileAndGoTo(ref.start, ref.file)

  destroy: ->
    @remove()

  getClose: ->
    @close

module.exports = document.registerElement('atom-ternjs-reference', prototype: ReferenceView.prototype)
