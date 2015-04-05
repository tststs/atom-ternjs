class RenameView extends HTMLElement

  createdCallback: ->

    @classList.add('atom-ternjs-rename')

    container = document.createElement('div')
    wrapper = document.createElement('div')

    title = document.createElement('h1')
    title.innerHTML = 'Rename'

    sub = document.createElement('h2')
    sub.innerHTML = 'Rename a variable in a scope-aware way. (experimental)'

    buttonClose = document.createElement('button')
    buttonClose.innerHTML = 'Close'
    buttonClose.id = 'close'
    buttonClose.classList.add('btn')
    buttonClose.classList.add('atom-ternjs-rename-close')
    buttonClose.addEventListener 'click', (e) =>
      @model.hide()
      return

    editor = document.createElement('atom-text-editor')
    editor.setAttribute('mini', true)

    buttonRename = document.createElement('button')
    buttonRename.innerHTML = 'Rename'
    buttonRename.id = 'close'
    buttonRename.classList.add('btn')
    buttonRename.classList.add('mt')
    buttonRename.addEventListener 'click', (e) =>
      editor = @querySelector('atom-text-editor')
      text = editor.getModel().getBuffer().getText()
      return unless text
      @model.updateAllAndRename(text)

    wrapper.appendChild(title)
    wrapper.appendChild(sub)
    wrapper.appendChild(editor)
    wrapper.appendChild(buttonClose)
    wrapper.appendChild(buttonRename)
    container.appendChild(wrapper)

    @appendChild(container)

  initialize: (model) ->
    @setModel(model)
    this

  getModel: ->
    @model

  setModel: (model) ->
    @model = model

  destroy: ->
    @remove()

module.exports = document.registerElement('atom-ternjs-rename', prototype: RenameView.prototype)
