{Provider, Suggestion} = require atom.packages.resolvePackagePath('autocomplete-plus')
apd = require 'atom-package-dependencies'
ap = null
clientRef = null
suggestionsArr = []
module.exports =
class AtomTernjsAutocomplete extends Provider
    exclusive: false
    constructor: (editorView, client, autocompletePlus) ->
        ap = autocompletePlus
        clientRef = client
        super
    buildSuggestions: ->
        selection = atom.workspace.getActiveEditor().getLastSelection()
        prefix = @prefixOfSelection selection
        suggestions = []
        for item in suggestionsArr
            suggestions.push new Suggestion(this, word: item[0], label: item[1], prefix: prefix)
        return suggestions
    preBuildSuggestions: ->
        suggestionsArr = []
        @checkCompletion().then (data) =>
            if data?.length
                for obj in data
                    suggestionsArr.push [obj.name, obj.type]
                # refresh
                @triggerCompletion()
    triggerCompletion: =>
        @getEditorView().runAutocompletion()
    cancelAutocompletion: ->
        @getEditorView().cancel()
    getEditorView: ->
        for view in ap.autocompleteViews
            if view.editor is atom.workspace.getActiveEditor()
                return view
    checkCompletion: ->
        editor = atom.workspace.getActiveEditor()
        cursor = editor.getCursor()
        position = cursor.getBufferPosition()
        clientRef.completions(editor.getUri(),
            line: position.row
            ch: position.column
            editor.getText()).then (data) =>
            if data.completions.length
                return data.completions
        , (err) ->
            console.log err
