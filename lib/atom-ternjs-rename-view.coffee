{registerElement} = require 'elmer'
Template = require('./templates/atom-ternjs-rename.html')
RenameModel = require './atom-ternjs-rename'

RenameElement = registerElement 'atom-ternjs-rename',
  modelConstructor: RenameModel
  createdCallback: ->
    @appendChild(Template.clone())
    @rootTemplate = @querySelector('template')
    @classList.add 'atom-ternjs-rename'
    @addEventListener 'click', (e) =>
      if e.target.id is 'close'
        @model.hide()
        return
      if e.target.id is 'rename'
        editor = @querySelector('atom-text-editor')
        text = editor.getModel().getBuffer().getText()
        return unless text
        @model.updateAllAndRename(text)

  getModel: -> @model
  setModel: (@model) ->
    @rootTemplate?.model = @model
