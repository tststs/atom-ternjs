class DocumentationView extends HTMLElement

  @elTitle = null
  @elContent = null

  createdCallback: ->
    @classList.add('atom-ternjs-documentation')
    container = document.createElement('div')

    @elTitle = document.createElement('h2')
    @elContent = document.createElement('div')

    container.appendChild(@elTitle)
    container.appendChild(@elContent)

    @appendChild(container)

  initialize: (state) ->
    this

  setTitle: (word, label) ->
    if word
      @elTitle.innerHTML = "#{word} : #{label}"
    else
      @elTitle.innerHTML = label

  setContent: (data) ->
    @elContent.innerHTML = ''
    elDoc = document.createElement('p')
    return if !data.doc and !data.url and !data.origin
    if data.doc
      data.doc = data.doc.replace(/(?:\r\n|\r|\n)/g, '<br />')
      elDoc.innerHTML = data.doc
    if data.url
      elUrlWrapper = document.createElement('span')
      elUrlWrapper.innerHTML = 'URL: '
      elUrl = document.createElement('a')
      elUrl.innerHTML = data.url
      elUrl.href = data.url
      elUrlWrapper.appendChild(elUrl)
      elDoc.appendChild(elUrlWrapper)
    if data.origin
      elOriginWrapper = document.createElement('span')
      elOriginWrapper.innerHTML = 'Origin: '
      elOrigin = document.createElement('span')
      elOrigin.innerHTML = data.origin

      if data.origin.endsWith('.js') or data.origin.endsWith('.coffee')
        elOrigin.classList.add('link')
        elOrigin.dataset.origin = data.origin;
        elOrigin.addEventListener('click', (e) =>
          @goToOrigin(e)
        )

      elOriginWrapper.appendChild(elOrigin)
      elDoc.appendChild(elOriginWrapper)
    @elContent.appendChild(elDoc)

  goToOrigin: (e) ->
    file = e.target.dataset.origin
    atom.workspace.open(file)

  destroy: ->
    @remove()

module.exports = document.registerElement('atom-ternjs-documentation', prototype: DocumentationView.prototype)
