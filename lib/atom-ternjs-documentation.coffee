DocumentationView = require './atom-ternjs-documentation-view'

module.exports =
class Reference

  documentation: null
  disposables: []
  client: null

  constructor: (client, state = {}) ->
    state.attached ?= true

    @client = client

    @documentation = new DocumentationView()
    @documentation.initialize(state)
    @documentationPanel = atom.workspace.addBottomPanel(item: @documentation, priority: 0)
    @documentationPanel.hide()

    atom.views.getView(@documentationPanel).classList.add("atom-ternjs-documentation-panel", "panel-bottom")

  set: (data) ->
    @documentation.setTitle(data.word, data.label)
    @documentation.setContent(data.docs)
    @show()

  hide: ->
    @documentationPanel?.hide()

  show: ->
    @documentationPanel?.show()

  destroy: ->
    @documentation?.destroy()
    @documentation = null

    @documentationPanel?.destroy()
    @documentationPanel = null
