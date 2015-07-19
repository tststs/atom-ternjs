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
    @configPanel = atom.workspace.addRightPanel(item: @configView, priority: 0)
    @configPanel.hide()

    atom.views.getView(@configPanel).classList.add('atom-ternjs-config-panel')
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
    for lib in Object.keys(localConfig.libs)
      if !libs[lib]
        libs[lib] = true
    localConfig.libs = libs
    localConfig

  registerEvents: ->
    close = @configView.getClose()
    close.addEventListener('click', (e) =>
      @updateConfig()
      @hide()
      @manager.helper.focusEditor()
    )
    cancel = @configView.getCancel()
    cancel.addEventListener('click', (e) =>
      @destroyEditors()
      @hide()
      @manager.helper.focusEditor()
    )

  mergeConfigObjects: (obj1, obj2) ->
    _.deepExtend({}, obj1, obj2)

  hide: ->
    @configPanel?.hide()

  clear: ->
    @hide()
    @destroyEditors()
    @config = null
    @projectConfig = null
    @configView?.removeContent()

  gatherData: ->
    configStub = @getContent('../tern-config.json', false)
    return unless configStub
    @projectConfig = @getContent('/.tern-project', true)
    @config = {}
    @config = @mergeConfigObjects(@projectConfig, @config)
    if @projectConfig
      @config = @prepareLibs(@config, configStub)
      for plugin of @config.plugins
        @config.plugins[plugin]?.active = true
      @config = @mergeConfigObjects(configStub, @config)
    else
      @config = configStub
    @configView.buildOptionsMarkup(@manager)

  removeEditor: (editor) ->
    return unless editor
    idx = @editors.indexOf(editor)
    return if idx is -1
    @editors.splice(idx, 1)

  destroyEditors: ->
    for editor in @editors
      buffer = editor.getModel().getBuffer()
      buffer.destroy()
    @editors = []

  updateConfig: ->
    @config.loadEagerly = []
    @config.dontLoad = []
    for editor in @editors
      buffer = editor.getModel().getBuffer()
      text = buffer.getText()
      text = text.trim()
      continue if text is ''
      @config[editor.__ternjs_section].push(text)
    @destroyEditors()
    newConfig = @buildNewConfig()
    newConfigJSON = JSON.stringify(newConfig, null, 2)
    @manager.helper.updateTernFile(newConfigJSON)
    @manager.restartServer()

  buildNewConfig: ->
    newConfig = {}
    if !_.isEmpty(@config.libs)
      newConfig.libs = []
      for key in Object.keys(@config.libs)
        if @config.libs[key]
          newConfig.libs.push(key)
    if @config.loadEagerly.length isnt 0
      newConfig.loadEagerly = @config.loadEagerly
    if @config.dontLoad.length isnt 0
      newConfig.dontLoad = @config.dontLoad
    if @projectConfig and !_.isEmpty(@projectConfig.plugins)
      newConfig.plugins = @projectConfig.plugins
    newConfig

  show: ->
    @clear()
    if !@gatherData()
      atom.notifications.addInfo('There is no active project. Please re-open or focus at least one JavaScript file of the project to configure.', dismissable: true)
      return
    @configPanel.show()

  destroy: ->
    @configView?.destroy()
    @configView = null
    @configPanel?.destroy()
    @configPanel = null
