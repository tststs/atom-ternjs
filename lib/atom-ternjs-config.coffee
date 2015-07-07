ConfigView = require './atom-ternjs-config-view'
_ = require 'underscore-plus'

module.exports =
class Config

  configView: null
  config: null
  projectConfig: null
  manager: null

  constructor: (manager, state = {}) ->
    @manager = manager
    @gatherData()
    @configView = new ConfigView()
    @configView.initialize(this)
    @configPanel = atom.workspace.addModalPanel(item: @configView, priority: 0)
    @configPanel.hide()

    atom.views.getView(@configPanel).classList.add('atom-ternjs-config-panel', 'panel-bottom')
    @registerEvents()

  getContent: (filePath, projectRoot) ->
    content = @manager.helper.getFileContent(filePath, projectRoot)
    return unless content
    content = JSON.parse(content)
    return unless content
    content

  prepareLibs: (localConfig, configStub) ->
    libs = []
    localConfig.libs = [] if !localConfig.libs
    for lib in Object.keys(configStub.libs)
      if localConfig.libs.indexOf(lib) is -1
        libs.push
          name: lib
          value: false
      else
        libs.push
          name: lib
          value: true
    localConfig.libs = libs
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

  gatherData: ->
    configStub = @getContent('../tern-config.json', false)
    return unless configStub
    @projectConfig = @config = @getContent('/.tern-project', true)
    if @projectConfig
      @config = @prepareLibs(@config, configStub)
      for plugin of @config.plugins
        @config.plugins[plugin]?.active = true
      @config = @mergeConfigObjects(configStub, @config)
    else
      @config = configStub
    @configView.buildOptionsMarkup()

  show: ->
    @configPanel.show()

  destroy: ->
    @configView?.destroy()
    @configView = null
    @configPanel?.destroy()
    @configPanel = null
