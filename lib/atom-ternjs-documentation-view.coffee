class DocumentationView extends HTMLElement

  @elTitle = null
  @elSub = null
  @elContent = null
  #@allowed = false
  @active = false

  createdCallback: ->
    @classList.add('atom-ternjs-documentation')
    container = document.createElement('div')

    @elTitle = document.createElement('h1')
    seperator = document.createElement('h1')
    seperator.classList.add('seperator')
    seperator.innerHTML = '-'
    @elSub = document.createElement('h2')
    @elContent = document.createElement('p')

    container.appendChild(@elTitle)
    container.appendChild(seperator)
    container.appendChild(@elSub)
    container.appendChild(@elContent)

    @appendChild(container)

  initialize: (state) ->
    this

  setTitle: (name, params) ->
    return unless name
    @elTitle.innerHTML = name
    @elSub.innerHTML = params

  setContent: (str) ->
    if str
      str = str.replace(/(?:\r\n|\r|\n)/g, '<br />')
      @elContent.innerHTML = str
    else
      @elContent.innerHTML = ''

  destroy: ->
    @remove()

module.exports = document.registerElement('atom-ternjs-documentation', prototype: DocumentationView.prototype)
