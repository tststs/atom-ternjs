ConfigView = require './atom-ternjs-config-view'
_ = require 'underscore-plus'

module.exports =
class Config

  configView: null
  config: null
  projectConfig: null
  editors: []
  manager: null

  constructor: (manager, state = {}) ->
    @manager = manager
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
    libs = {}
    if !localConfig.libs
      localConfig.libs = {}
    else
      libsAsObject = {}
      for lib in localConfig.libs
        libsAsObject[lib] = true
      localConfig.libs = libsAsObject
    for lib in Object.keys(configStub.libs)
      if !localConfig.libs[lib]
        libs[lib] = false
      else
        libs[lib] = true
    localConfig.libs = libs
    localConfig

  registerEvents: ->
    close = @configView.getClose()
    close.addEventListener('click', (e) =>
      #@configView.getTextEditors()
      @hide()
      @manager.helper.focusEditor()
    )

  mergeConfigObjects: (configStub, localConfig) ->
    _.deepExtend({}, configStub, localConfig)

  hide: ->
    @configPanel?.hide()

  clear: ->
    @hide()
    @config = null
    @projectConfig = null
    @configView?.removeContent()

  gatherData: ->
    @clear()
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

  removeEditor: (editor) ->
    return unless editor
    idx = @editors.indexOf(editor)
    return if idx is -1
    @servers.splice(idx, 1)

  show: ->
    @configPanel.show()

  destroy: ->
    @configView?.destroy()
    @configView = null
    @configPanel?.destroy()
    @configPanel = null
