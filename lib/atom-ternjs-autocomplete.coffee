{Provider, Suggestion} = require atom.packages.resolvePackagePath('autocomplete-plus')

suggestionsArr = []
maxItems = null

module.exports =
class AtomTernjsAutocomplete extends Provider

    exclusive: true
    autocompletePlus: null
    client: null
    editor: null
    currentSuggestionIndex: false
    disposables: []
    documentationView = null

    constructor: (editor, client, autocompletePlus, documentationView) ->
        @autocompletePlus = autocompletePlus
        @client = client
        @editor = editor
        @documentationView = documentationView
        atom.workspaceView.command 'tern:cancel', =>
            @cancelAutocompletion()
        super

    buildSuggestions: ->
        suggestions = []
        selection = atom.workspace.getActiveEditor().getLastSelection()
        prefix = @prefixOfSelection selection
        for item, index in suggestionsArr
            if index == maxItems
                break
            suggestions.push new Suggestion(this, word: item[0], label: item[1], prefix: prefix)
        return suggestions

    preBuildSuggestions: ->
        suggestionsArr = []
        @unregisterEvents()
        @currentSuggestionIndex = false
        @checkCompletion().then (data) =>
            if data?.length
                for obj, index in data
                    if index == maxItems
                        break
                    suggestionsArr.push [obj.name, obj.type, obj.doc]
                # refresh
                @triggerCompletion()

    triggerCompletion: =>
        @currentSuggestionIndex = 0
        @registerEvents()
        @getCurrentAutocompleteManager().runAutocompletion()
        @setDocumentationContent()

    setDocumentationContent: ->
        return unless suggestionsArr.length
        @documentationView.setTitle(suggestionsArr[@currentSuggestionIndex][0])
        @documentationView.setContent(suggestionsArr[@currentSuggestionIndex][2])
        @documentationView.show()

    cancelAutocompletion: ->
        @documentationView.hide()
        @unregisterEvents()
        @getCurrentAutocompleteManager().cancel()

    getMaxIndex: ->
        Math.min(maxItems, suggestionsArr.length)

    registerEvents: ->
        @disposables.push atom.config.observe('autocomplete-plus.maxSuggestions', => maxItems = atom.config.get('autocomplete-plus.maxSuggestions'))
        @disposables.push atom.workspace.onDidChangeActivePaneItem =>
            @cancelAutocompletion()
        @disposables.push @getCurrentAutocompleteManager().emitter.on 'do-select-next', =>
            if ++@currentSuggestionIndex >= @getMaxIndex()
                @currentSuggestionIndex = 0
            @setDocumentationContent()
        @disposables.push @getCurrentAutocompleteManager().emitter.on 'do-select-previous', =>
            if --@currentSuggestionIndex < 0
                @currentSuggestionIndex = @getMaxIndex() - 1
            @setDocumentationContent()

    unregisterEvents: ->
        for disposable in @disposables
            disposable.dispose()
        @disposables = []

    getCurrentAutocompleteManager: ->
        for manager in @autocompletePlus.autocompleteManagers
            if manager.editor is atom.workspace.getActiveEditor()
                return manager

    checkCompletion: ->
        editor = atom.workspace.getActiveEditor()
        cursor = editor.getCursor()
        position = cursor.getBufferPosition()
        @client.completions(editor.getUri(),
            line: position.row
            ch: position.column
            ).then (data) =>
            if data.completions.length
                return data.completions
        , (err) ->
            console.log err
