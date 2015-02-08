apd = require 'atom-package-dependencies'
{Function} = require 'loophole'

module.exports =
class Provider

    exclusive: true
    manager: null
    suggestionsArr = []
    currentSuggestionIndex: 0
    disposables: []
    maxItems = null
    force = false
    # automcomplete-plus
    autocompletePlus = null
    id: 'atom-ternjs-provider'
    selector: '.source.js'
    blacklist: '.source.js .comment'

    init: (manager) ->
        @manager = manager
        atom.packages.activatePackage('autocomplete-plus')
          .then (pkg) =>
            @autocompletePlus = apd.require('autocomplete-plus')
            @registerEvents()

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
            @manager.documentation.hide()
            return []

        if !@isValidPrefix(prefix) and !@force
            @manager.documentation.hide()
            return []

        prefix = @fixPrefix(prefix)

        that = this

        return new Promise (resolve) ->
            that.manager.client.update(options.editor.getURI(), options.editor.getText()).then =>
                that.manager.client.completions(options.editor.getURI(), {line: options.position.row, ch: options.position.column}).then (data) =>
                    that.clearSuggestions()
                    if !data.completions.length
                        resolve([])
                        that.manager.documentation.hide()
                        return
                    if data.completions.length is 1 and data.completions[0].name.replace('$', '') is prefix
                        resolve([])
                        that.manager.documentation.hide()
                        return
                    for obj, index in data.completions
                        if index == maxItems
                            break
                        obj = that.fixCompletion(obj)

                        that.suggestionsArr.push {
                            word: obj.name,
                            prefix: prefix,
                            label: obj.type,
                            renderLabelAsHtml: false,
                            className: null,
                            _ternDocs: obj.doc,
                            _ternUrl: obj.url,
                            _ternOrigin: obj.origin,
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
                                that.clearSuggestions()
                                that.manager.documentation.hide()
                        }
                    resolve(that.suggestionsArr)
                    that.setDocumentationContent()
                , (err) ->
                    console.log err

    fixCompletion: (obj) ->
        if obj.type == 'string'
            # remove leading and trailing double quotes since
            # they are already typed and won't be replaced by
            # the suggestion and who would use double quotes
            # anyway duh
            obj.name = obj.name.replace /(^"|"$)/g, ''

        obj.type = obj.type.replace('->', ':')
        obj

    setDocumentationContent: (length) ->
        return unless @suggestionsArr.length
        if @currentSuggestionIndex >= @suggestionsArr.length
            @manager.documentation.hide()
            return

        currentSuggestion = @suggestionsArr[@currentSuggestionIndex]
        if !currentSuggestion._ternDocs and !currentSuggestion._ternUrl and !currentSuggestion._ternOrigin
            @manager.documentation.hide()
            return

        @manager.documentation.set({
            word: currentSuggestion.word,
            label: currentSuggestion.label,
            docs: {
                doc: currentSuggestion._ternDocs,
                url: currentSuggestion._ternUrl,
                origin: currentSuggestion._ternOrigin,
            }
        })

    forceCompletion: ->
        @force = true
        # need this for now. no plan, to hook this forever
        @autocompletePlus.autocompleteManager.shouldDisplaySuggestions = true
        @autocompletePlus.autocompleteManager.findSuggestions()
        @force = false

    clearSuggestionsAndHide: ->
        @suggestionsArr = []
        @currentSuggestionIndex = 0
        @manager.documentation.hide()

    clearSuggestions: ->
        @suggestionsArr = []
        @currentSuggestionIndex = 0

    forceCancel: ->
        @autocompletePlus.autocompleteManager.hideSuggestionList()
        @clearSuggestions()

    getMaxIndex: (length) ->
        Math.min(maxItems, length)

    addSelector: (selector) ->
        @selector = @selector + ',' + selector

    removeSelector: (selector) ->
        @selector = @selector.replace(',' + selector, '')

    registerEvents: ->
        @disposables.push atom.config.observe('autocomplete-plus.maxSuggestions', => maxItems = atom.config.get('autocomplete-plus.maxSuggestions'))
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-cancel', =>
            @clearSuggestions()
            @manager.documentation.hide()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-select-next', =>
            length = @autocompletePlus.autocompleteManager.suggestionList.items.length
            if ++@currentSuggestionIndex >= @getMaxIndex(length)
                @currentSuggestionIndex = 0
            @setDocumentationContent(length)
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-select-previous', =>
            length = @autocompletePlus.autocompleteManager.suggestionList.items.length
            if --@currentSuggestionIndex < 0
                @currentSuggestionIndex = @getMaxIndex(length) - 1
            @setDocumentationContent(length)

    unregisterEvents: ->
        for disposable in @disposables
            disposable.dispose()
        @disposables = []

    destroy: ->
        @unregisterEvents()
