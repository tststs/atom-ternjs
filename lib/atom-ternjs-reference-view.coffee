class ReferenceView extends HTMLElement

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

  initialize: (model) ->
    @setModel(model)
    this

  buildItems: (data) ->
    @content.innerHTML = ''
    headline = document.createElement('h2')
    headline.innerHTML = data.name + " (#{data.type})"
    @content.appendChild(headline)
    list = document.createElement('ul')
    for item, i in data.refs
      li = document.createElement('li')
      li.dataset.idx = i;
      li.innerHTML = item.file + ':' + item.start
      li.addEventListener('click', (e) =>
        @model.goToReference(e)
      )
      list.appendChild(li)
    @content.appendChild(list)

  destroy: ->
    @remove()

  getClose: ->
    @close

  getModel: ->
    @model

  setModel: (model) ->
    @model = model

module.exports = document.registerElement('atom-ternjs-reference', prototype: ReferenceView.prototype)
