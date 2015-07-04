class TypeView extends HTMLElement

  createdCallback: ->
    @getModel()
    @addEventListener('click', =>
      @getModel().destroyOverlay()
    , false)
    @classList.add('atom-ternjs-type')
    @container = document.createElement('span')
    @appendChild(@container)

  initialize: (model) ->
    @setModel(model)
    this

  getModel: ->
    @model

  setModel: (model) ->
    @model = model

  setData: (data) ->
    @container.innerHTML = data.label

  destroy: ->
    @remove()

module.exports = document.registerElement('atom-ternjs-type', prototype: TypeView.prototype)
