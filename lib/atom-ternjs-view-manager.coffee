RenameModel = require './atom-ternjs-rename'
RenameView = require './atom-ternjs-rename-view'

module.exports =
class ViewManager

    renamePanel: null
    renameModel: null
    manager: null

    constructor: (manager) ->
        @manager = manager
        @registerViewProvider()

    registerViewProvider: ->
        atom.views.addViewProvider
            modelConstructor: RenameModel
            viewConstructor: RenameView

    showRename: ->
        if @renamePanel
            @renamePanel.show()
            return
        @renameModel = new RenameModel(@manager)
        @renamePanel = atom.workspace.addBottomPanel item: @renameModel

    hideRename: ->
        @renamePanel?.hide()
        @focusEditor()

    focusEditor: ->
        editor = atom.workspace.getActiveTextEditor()
        return unless editor
        view = atom.views.getView(editor)
        view?.focus?()
