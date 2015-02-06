class TypeView extends HTMLElement

  createdCallback: ->
    @classList.add('atom-ternjs-type')
    container = document.createElement('div')

    @appendChild(container)

  initialize: (state) ->
    this

  destroy: ->
    @remove()

module.exports = document.registerElement('atom-ternjs-type', prototype: TypeView.prototype)
