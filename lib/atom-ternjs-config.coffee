ConfigView = require './atom-ternjs-config-view'
_ = require 'underscore-plus'

module.exports =
class Config

  configView: null
  config: []
  manager: null
  projectConfig: null

  constructor: (manager, state = {}) ->
    @manager = manager

    @configView = new ConfigView()
    @configView.initialize(this)
    @configView.buildOptionsMarkup()
    @configPanel = atom.workspace.addBottomPanel(item: @configView, priority: 0)
    @configPanel.hide()

    atom.views.getView(@configPanel).classList.add('atom-ternjs-config-panel', 'panel-bottom')
    @registerEvents()

  buildJSON: ->
    configStub = @manager.helper.getConfigJSONData()
    return unless configStub
    configStub = JSON.parse(configStub)
    return unless configStub
    configStub

  getProjectConfig: ->
    localConfig = @manager.helper.getConfig()
    return unless localConfig
    localConfig = JSON.parse(localConfig)
    return unless localConfig
    localConfig

  registerEvents: ->
    close = @configView.getClose()
    close.addEventListener('click', (e) =>
      @hide()
      @manager.helper.focusEditor()
    )

  mergeConfigObjects: (configStub, localConfig) ->
    _.deepExtend({}, configStub, localConfig)

  hide: ->
    @configPanel.hide()

  show: ->
    configStub = @buildJSON()
    localConfig = @getProjectConfig()
    if configStub and localConfig
      @config = @mergeConfigObjects(configStub, localConfig)
    else
      @config = configStub
    #@configPanel.show()

  destroy: ->
    @configView?.destroy()
    @configView = null

    @configPanel?.destroy()
    @configPanel = null
