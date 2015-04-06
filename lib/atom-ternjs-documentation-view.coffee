class DocumentationView extends HTMLElement

  createdCallback: ->
    @classList.add('atom-ternjs-documentation')
    container = document.createElement('div')

    @elTitle = document.createElement('h2')
    @elContent = document.createElement('div')

    container.appendChild(@elTitle)
    container.appendChild(@elContent)

    @appendChild(container)

  initialize: (model) ->
    @setModel(model)
    this

  setTitle: (returnValue, fn) ->
    if returnValue
      @elTitle.innerHTML = "#{returnValue} : #{fn}"
      return
    @elTitle.innerHTML = fn

  setContent: (docs, url, origin) ->
    @elContent.innerHTML = ''
    elDoc = document.createElement('p')
    return if !docs and !url and !origin
    if docs
      docs = docs.replace(/(?:\r\n|\r|\n)/g, '<br />')
      elDoc.innerHTML = docs
    if url
      elUrlWrapper = document.createElement('span')
      elUrlWrapper.innerHTML = 'URL: '
      elUrl = document.createElement('a')
      elUrl.innerHTML = url
      elUrl.href = url
      elUrlWrapper.appendChild(elUrl)
      elDoc.appendChild(elUrlWrapper)
    if origin
      elOriginWrapper = document.createElement('span')
      elOriginWrapper.innerHTML = 'Origin: '
      elOrigin = document.createElement('span')
      elOrigin.innerHTML = origin

      if origin.endsWith('.js') or origin.endsWith('.coffee')
        elOrigin.classList.add('link')
        elOrigin.dataset.origin = origin;
        elOrigin.addEventListener('click', (e) =>
          @model.goToOrigin(e)
        )

      elOriginWrapper.appendChild(elOrigin)
      elDoc.appendChild(elOriginWrapper)
    @elContent.appendChild(elDoc)

  getModel: ->
    @model

  setModel: (model) ->
    @model = model

  destroy: ->
    @remove()

module.exports = document.registerElement('atom-ternjs-documentation', prototype: DocumentationView.prototype)
