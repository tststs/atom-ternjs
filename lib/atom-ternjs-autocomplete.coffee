apd = require 'atom-package-dependencies'
{Function} = require 'loophole'
{Point} = require 'atom'

module.exports =
class AtomTernjsAutocomplete

    exclusive: true
    client: null
    suggestionsArr = null
    currentSuggestionIndex: null
    disposables: null
    documentation = null
    maxItems = null
    force = false
    # automcomplete-plus
    autocompletePlus = null
    id: 'atom-ternjs-provider'
    selector: '.source.js'
    blacklist: '.source.js .comment'

    init: (client, documentation) ->
        atom.packages.activatePackage('autocomplete-plus')
          .then (pkg) =>
            @autocompletePlus = apd.require('autocomplete-plus')
            @registerEvents()
        @disposables = []
        @suggestionsArr = []
        @currentSuggestionIndex = 0
        @client = client
        @documentation = documentation

    isValidPrefix: (prefix) ->
        return true if prefix[prefix.length - 1] is '\.'
        return true if prefix.replace(/\s/g, '').length is 0
        if prefix.length > 1
            prefix = '_' + prefix
        try (new Function("var " + prefix))()
        catch e then return false
        return true

    fixPrefix: (prefix) ->
        if prefix.lastIndexOf(' ') is prefix.length - 1
            return ''
        if (!prefix.replace(/\s/g, '').length) or prefix.endsWith(';')
            return ''
        prefix

    requestHandler: (options) ->
        return [] unless options?.editor? and options?.buffer? and options?.cursor?
        prefix = options.prefix

        # .. crashes the server
        if prefix.indexOf('..') != -1
            @documentation.hide()
            return []

        if !@isValidPrefix(prefix) and !@force
            @documentation.hide()
            return []

        prefix = @fixPrefix(prefix)

        that = this

        return new Promise (resolve) ->
            that.client.update(options.editor.getURI(), options.editor.getText()).then =>
                that.client.completions(options.editor.getURI(), {line: options.position.row, ch: options.position.column}).then (data) =>
                    that.clearSuggestions()
                    if !data.completions.length
                        resolve([])
                        that.documentation.hide()
                        return
                    if data.completions.length is 1 and data.completions[0].name.replace('$', '') is prefix
                        resolve(that.suggestionsArr)
                        that.documentation.hide()
                        return
                    for obj, index in data.completions
                        if index == maxItems
                            break
                        if obj.type == 'string'
                            # remove leading and trailing double quotes since
                            # they are already typed and won't be replaced by
                            # the suggestion and who would use double quotes
                            # anyway duh
                            obj.name = obj.name.replace /(^"|"$)/g, ''

                        that.suggestionsArr.push {
                            word: obj.name,
                            prefix: prefix,
                            label: obj.type,
                            renderLabelAsHtml: false,
                            className: null,
                            _ternDocs: obj.doc,
                            onWillConfirm: ->
                                if this.word[0] is '$'
                                    begin = options.cursor.getBeginningOfCurrentWordBufferPosition()
                                    char = options.editor.getTextInRange([[begin.row, begin.column - 1], [begin.row, begin.column]])
                                    if char is '$'
                                        idx = this.word.lastIndexOf('$')
                                        this.word = this.word.substring(idx + 1)
                                if /^[.\"\']$/i.test(prefix[prefix.length - 1])
                                    this.word = this.prefix + this.word
                            onDidConfirm: ->
                        }
                    resolve(that.suggestionsArr)
                    that.setDocumentationContent()
                , (err) ->
                    console.log err

    setDocumentationContent: ->
        return unless @suggestionsArr.length
        currentSuggestion = @suggestionsArr[@currentSuggestionIndex]
        if !currentSuggestion._ternDocs
            @documentation.hide()
            return
        @documentation.set({
            word: currentSuggestion.word,
            label: currentSuggestion.label,
            docs: currentSuggestion._ternDocs
        })

    forceCompletion: ->
        @force = true
        @autocompletePlus.autocompleteManager.runAutocompletion()
        @force = false

    clearSuggestions: ->
        @suggestionsArr = []
        @currentSuggestionIndex = 0

    forceCancel: ->
        @autocompletePlus.autocompleteManager.hideSuggestionList()
        @clearSuggestions()

    hideDocumentation: ->
        @documentation.hide()

    getMaxIndex: ->
        Math.min(maxItems, @suggestionsArr.length)

    addSelector: (selector) ->
        @selector = @selector + ',' + selector

    removeSelector: (selector) ->
        @selector = @selector.replace(',' + selector, '')

    registerEvents: ->
        @disposables.push atom.config.observe('autocomplete-plus.maxSuggestions', => maxItems = atom.config.get('autocomplete-plus.maxSuggestions'))
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-cancel', =>
            @clearSuggestions()
            @documentation.hide()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-confirm', =>
            @clearSuggestions()
            @documentation.hide()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-select-next', =>
            if ++@currentSuggestionIndex >= @getMaxIndex()
                @currentSuggestionIndex = 0
            @setDocumentationContent()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-select-previous', =>
            if --@currentSuggestionIndex < 0
                @currentSuggestionIndex = @getMaxIndex() - 1
            @setDocumentationContent()

    unregisterEvents: ->
        for disposable in @disposables
            disposable.dispose()
        @disposables = []

    cleanup: ->
        @documentation.hide()
        @unregisterEvents()
