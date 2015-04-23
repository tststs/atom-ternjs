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

  getContent: (filePath, projectRoot) ->
    content = @manager.helper.getFileContent(filePath, projectRoot)
    return unless content
    content = JSON.parse(content)
    return unless content
    content

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
    configStub = @getContent('../tern-config.json', false)
    return unless configStub
    localConfig = @getContent('/.tern-project', true)
    if localConfig
      @config = @mergeConfigObjects(configStub, localConfig)
    else
      @config = configStub
    #@configPanel.show()

  destroy: ->
    @configView?.destroy()
    @configView = null

    @configPanel?.destroy()
    @configPanel = null
