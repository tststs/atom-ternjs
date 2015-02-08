class TypeView extends HTMLElement

  @container: null

  createdCallback: ->
    @classList.add('atom-ternjs-type')
    @container = document.createElement('span')

    @appendChild(@container)

  initialize: (state) ->
    this

  setData: (data) ->
    @container.innerHTML = data.label

  destroy: ->
    @remove()

module.exports = document.registerElement('atom-ternjs-type', prototype: TypeView.prototype)
