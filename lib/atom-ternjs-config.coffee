ConfigView = require './atom-ternjs-config-view'

module.exports =
class Config

  configView: null
  manager: null
  options: null

  constructor: (manager, state = {}) ->
    @manager = manager

    @configView = new ConfigView()
    @configView.initialize(this)
    @configView.buildOptionsMarkup()
    @configPanel = atom.workspace.addBottomPanel(item: @configView, priority: 0)
    @configPanel.hide()

    atom.views.getView(@configPanel).classList.add('atom-ternjs-config-panel', 'panel-bottom')
    @registerEvents()

  registerEvents: ->
    close = @configView.getClose()
    close.addEventListener('click', (e) =>
      @hide()
      @manager.helper.focusEditor()
    )

  hide: ->
    @configPanel.hide()

  show: ->
    @configPanel.show()

  destroy: ->
    @configView?.destroy()
    @configView = null

    @configPanel?.destroy()
    @configPanel = null
