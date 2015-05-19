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
    config = @getModel().config
    for lib in config.libs
      @content.appendChild(@buildBoolean(lib))

  buildBoolean: (obj) ->
    wrapper = document.createElement('div')
    label = document.createElement('span')
    label.innerHTML = obj.name
    checkbox = document.createElement('input')
    checkbox.type = 'checkbox'
    checkbox.checked = obj.value
    wrapper.appendChild(label)
    wrapper.appendChild(checkbox)
    wrapper

  getClose: ->
    @close

  destroy: ->
    @remove()

  getModel: ->
    @model

  setModel: (model) ->
    @model = model

module.exports = document.registerElement('atom-ternjs-config', prototype: ConfigView.prototype)
