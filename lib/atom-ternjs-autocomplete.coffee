{Provider, Suggestion} = require atom.packages.resolvePackagePath('autocomplete-plus')

_ = require 'underscore-plus'

suggestionsArr = []
maxItems = null

module.exports =
class AtomTernjsAutocomplete extends Provider

    exclusive: true
    autocompletePlus: null
    client: null
    _editor: null
    _buffer: null
    currentSuggestionIndex: false
    disposables: []
    documentationView = null
    autocompleteManager = null
    isActive = false

    constructor: (_editor, _buffer, client, autocompletePlus, documentationView) ->
        @autocompletePlus = autocompletePlus
        @client = client
        @_editor = _editor
        @_buffer = _buffer
        @documentationView = documentationView
        super

    init: ->
        @getAutocompletionManager()
        @registerEvents()

    buildSuggestions: ->
        suggestions = []
        selection = @_editor.getLastSelection()
        prefix = @prefixOfSelection selection
        for item, index in suggestionsArr
            if index == maxItems
                break
            suggestions.push new Suggestion(this, word: item[0], label: item[1], prefix: prefix)
        return suggestions

    callPreBuildSuggestions: (force) ->
        cursor = @_editor.getLastCursor()
        prefix = cursor.getCurrentWordPrefix()
        if force || /^[a-z0-9.\"\']$/i.test(prefix[prefix.length - 1])
          @preBuildSuggestions()
        else
          @cancelAutocompletion()

    preBuildSuggestions: ->
        return unless @autocompleteManager
        suggestionsArr = []
        @checkCompletion().then (data) =>
            return unless data?.length
            for obj, index in data
                if index == maxItems
                    break
                suggestionsArr.push [obj.name, obj.type, obj.doc]
            # refresh
            @triggerCompletion()

    triggerCompletion: =>
        @autocompleteManager.runAutocompletion()
        @currentSuggestionIndex = 0
        @setDocumentationContent()

    setDocumentationContent: ->
        return unless suggestionsArr.length
        @documentationView.setTitle(suggestionsArr[@currentSuggestionIndex][0], suggestionsArr[@currentSuggestionIndex][1])
        @documentationView.setContent(suggestionsArr[@currentSuggestionIndex][2])
        @documentationView.show()

    cancelAutocompletion: ->
        @documentationView.hide()
        return unless @autocompleteManager
        @autocompleteManager.cancel()

    getMaxIndex: ->
        Math.min(maxItems, suggestionsArr.length)

    update: ->
        @client.update(@_editor.getURI(), @_editor.getText())

    registerEvents: ->
        @disposables.push @_buffer.onDidStopChanging =>
            _.throttle @update(@_editor), 2000
        @disposables.push @_buffer.onDidStopChanging =>
            _.throttle @callPreBuildSuggestions(), 500
        @disposables.push atom.config.observe('autocomplete-plus.maxSuggestions', => maxItems = atom.config.get('autocomplete-plus.maxSuggestions'))
        @disposables.push atom.workspace.onDidChangeActivePaneItem =>
            @cancelAutocompletion()
        @disposables.push @autocompleteManager.emitter.on 'do-select-next', =>
            return unless @isActive
            if ++@currentSuggestionIndex >= @getMaxIndex()
                @currentSuggestionIndex = 0
            @setDocumentationContent()
        @disposables.push @autocompleteManager.emitter.on 'do-select-previous', =>
            return unless @isActive
            if --@currentSuggestionIndex < 0
                @currentSuggestionIndex = @getMaxIndex() - 1
            @setDocumentationContent()

    unregisterEvents: ->
        for disposable in @disposables
            disposable.dispose()
        @disposables = []

    dispose: ->
        @documentationView.hide()
        @unregisterEvents()

    getAutocompletionManager: ->
        for manager in @autocompletePlus.autocompleteManagers
            if manager.editor is @_editor
                @autocompleteManager = manager

    checkCompletion: ->
        cursor = @_editor.getLastCursor()
        position = cursor.getBufferPosition()
        @client.completions(@_editor.getURI(),
            line: position.row
            ch: position.column
            ).then (data) =>
                data.completions
        , (err) ->
            console.log err
