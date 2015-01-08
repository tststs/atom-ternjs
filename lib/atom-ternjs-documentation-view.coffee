module.exports =
class DocumentationView

  @title = null
  @content = null
  @allowed = false

  constructor: (serializeState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('atom-ternjs-doc')

    # Create child elements
    @title = document.createElement('h1')
    @content = document.createElement('p')

    @title.textContent = @title
    @content.textContent = @content

    @element.appendChild(@title)
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

  setTitle: (str) ->
    @title.textContent = str

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
