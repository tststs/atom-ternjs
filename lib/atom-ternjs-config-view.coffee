class ConfigView extends HTMLElement

  createdCallback: ->
    @classList.add('atom-ternjs-config')

    container = document.createElement('div')
    @content = document.createElement('div')
    @close = document.createElement('button')
    @close.classList.add('btn', 'atom-ternjs-config-close')
    @close.innerHTML = 'Close'
    container.appendChild(@close)
    container.appendChild(@content)
    @appendChild(container)

  initialize: (model) ->
    @setModel(model)
    this

  buildOptionsMarkup: ->
    console.log @model.options.libs
    for own lib of @model.options.libs
      console.log lib

  getClose: ->
    @close

  destroy: ->
    @remove()

  getModel: ->
    @model

  setModel: (model) ->
    @model = model

module.exports = document.registerElement('atom-ternjs-config', prototype: ConfigView.prototype)
