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
    @content.appendChild(@buildBoolean(config.libs))
    @content.appendChild(@buildStringArray(config.loadEagerly, 'loadEagerly'))

  buildStringArray: (obj, section) ->
    wrapper = document.createElement('div')
    header = document.createElement('h2')
    header.innerHTML = section
    doc = document.createElement('p')
    doc.innerHTML = @getModel().config.docs[section].doc
    wrapper.appendChild(header)
    wrapper.appendChild(doc)
    for path in obj
      item = document.createElement('atom-text-editor')
      item.setAttribute('mini', true)
      item.getModel().getBuffer().setText(path)
      wrapper.appendChild(item)
    wrapper

  buildBoolean: (libs) ->
    wrapper = document.createElement('div')
    header = document.createElement('h2')
    header.innerHTML = 'libs:'
    wrapper.appendChild(header)
    for lib in libs
      inputWrapper = document.createElement('div')
      inputWrapper.classList.add('input-wrapper')
      label = document.createElement('span')
      label.innerHTML = lib.name
      checkbox = document.createElement('input')
      checkbox.type = 'checkbox'
      checkbox.checked = lib.value
      inputWrapper.appendChild(label)
      inputWrapper.appendChild(checkbox)
      wrapper.appendChild(inputWrapper)
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
