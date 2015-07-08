class ConfigView extends HTMLElement

  createdCallback: ->
    @classList.add('atom-ternjs-config')

    container = document.createElement('div')
    @content = document.createElement('div')
    @close = document.createElement('button')
    @close.classList.add('btn', 'atom-ternjs-config-close')
    @close.innerHTML = 'Save & Restart Server'
    container.appendChild(@content)
    @appendChild(container)

  initialize: (model) ->
    @setModel(model)
    this

  buildOptionsMarkup: ->
    config = @getModel().config
    @content.appendChild(@buildBoolean())
    @content.appendChild(@buildStringArray(config.loadEagerly, 'loadEagerly'))
    @content.appendChild(@buildStringArray(config.dontLoad, 'dontLoad'))
    @content.appendChild(@close)

  buildStringArray: (obj, section) ->
    wrapper = document.createElement('section')
    wrapper.dataset.type = section
    header = document.createElement('h2')
    header.innerHTML = section
    doc = document.createElement('p')
    doc.innerHTML = @getModel().config.docs[section].doc
    wrapper.appendChild(header)
    wrapper.appendChild(doc)
    for path in obj
      wrapper.appendChild(@createInputWrapper(path, section))
    if obj.length is 0
      wrapper.appendChild(@createInputWrapper(null, section))
    wrapper

  createInputWrapper: (path, section) ->
    inputWrapper = document.createElement('div')
    inputWrapper.classList.add('input-wrapper')
    editor = @createTextEditor(path)
    editor.__ternjs_section = section
    inputWrapper.appendChild(editor)
    inputWrapper.appendChild(@createAdd(section))
    inputWrapper.appendChild(@createSub(editor))
    inputWrapper

  createSub: (editor) ->
    sub = document.createElement('span')
    sub.classList.add('sub')
    sub.classList.add('inline-block')
    sub.classList.add('status-removed')
    sub.classList.add('icon')
    sub.classList.add('icon-diff-removed')
    sub.addEventListener('click', (e) =>
      @getModel().removeEditor(editor)
      inputWrapper = e.target.closest('.input-wrapper')
      inputWrapper.parentNode.removeChild(inputWrapper)
    , false)
    sub

  createAdd: (section) ->
    add = document.createElement('span')
    add.classList.add('add')
    add.classList.add('inline-block')
    add.classList.add('status-added')
    add.classList.add('icon')
    add.classList.add('icon-diff-added')
    add.addEventListener('click', (e) =>
      e.target.closest('section').appendChild(@createInputWrapper(null, section))
    , false)
    add

  createTextEditor: (path) ->
    item = document.createElement('atom-text-editor')
    item.setAttribute('mini', true)
    item.getModel().getBuffer().setText(path) if path
    @getModel().editors.push(item)
    item

  buildBoolean: ->
    wrapper = document.createElement('section')
    header = document.createElement('h2')
    header.innerHTML = 'libs:'
    wrapper.appendChild(header)
    for key in Object.keys(@getModel().config.libs)
      inputWrapper = document.createElement('div')
      inputWrapper.classList.add('input-wrapper')
      label = document.createElement('span')
      label.innerHTML = key
      checkbox = document.createElement('input')
      checkbox.type = 'checkbox'
      checkbox.checked = @getModel().config.libs[key]
      checkbox.__ternjs_key = key
      checkbox.addEventListener('change', (e) =>
        @getModel().config.libs[e.target.__ternjs_key] = e.target.checked
      , false)
      inputWrapper.appendChild(label)
      inputWrapper.appendChild(checkbox)
      wrapper.appendChild(inputWrapper)
    wrapper

  removeContent: ->
    @content?.innerHTML = ''

  getClose: ->
    @close

  destroy: ->
    @remove()

  getModel: ->
    @model

  setModel: (model) ->
    @model = model

module.exports = document.registerElement('atom-ternjs-config', prototype: ConfigView.prototype)
