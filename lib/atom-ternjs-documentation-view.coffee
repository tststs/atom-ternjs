module.exports =
class DocumentationView

  @title = null
  @sub = null
  @content = null
  @allowed = false

  constructor: (serializeState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('atom-ternjs-doc')

    # Create child elements
    @title = document.createElement('h1')
    @sub = document.createElement('h2')
    @content = document.createElement('p')

    @title.textContent = ''
    @sub.textContent = ''
    @content.textContent = ''

    @element.appendChild(@title)
    @element.appendChild(@sub)
    @element.appendChild(@content)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  toggle: ->
    @element.classList.toggle('active')

  show: ->
    return unless @allowed
    @element.classList.add('active')

  hide: ->
    @element.classList.remove('active')

  setTitle: (name, params) ->
    @title.textContent = name
    @sub.textContent = params

  setContent: (str) ->
    if str
      @allowed = true
    else
      @allowed = false
      @hide()
    @content.textContent = str

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
