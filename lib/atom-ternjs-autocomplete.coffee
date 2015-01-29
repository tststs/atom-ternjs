apd = require 'atom-package-dependencies'

module.exports =
class AtomTernjsAutocomplete

    exclusive: true
    client: null
    suggestionsArr = null
    currentSuggestionIndex: null
    disposables: null
    documentationView = null
    maxItems = null
    force = false
    # automcomplete-plus
    autocompletePlus = null
    id: 'atom-ternjs-provider'
    selector: '.source.js'
    blacklist: '.source.js .comment'

    init: (client, documentationView) ->
        atom.packages.activatePackage('autocomplete-plus')
          .then (pkg) =>
            @autocompletePlus = apd.require('autocomplete-plus')
            @registerEvents()
        @disposables = []
        @suggestionsArr = []
        @currentSuggestionIndex = 0
        @client = client
        @documentationView = documentationView

    requestHandler: (options) ->
        return [] unless options?.editor? and options?.buffer? and options?.cursor?
        prefix = options.prefix

        if (!(/^[a-z0-9.\"\' ]$/i).test(prefix[prefix.length - 1]) or prefix.indexOf('..') != -1) and !@force
            @documentationView.hide()
            return []

        if (!prefix.replace(/\s/g, '').length) or prefix.endsWith(';')
            prefix = ''

        that = this

        return new Promise (resolve) ->
            that.client.update(options.editor.getURI(), options.editor.getText()).then =>
                that.client.completions(options.editor.getURI(), {line: options.position.row, ch: options.position.column}).then (data) =>
                    that.clearSuggestions()
                    if !data.completions.length
                        resolve([])
                        that.documentationView.hide()
                        return
                    if data.completions.length is 1 and data.completions[0].name.replace('$', '') is prefix
                        resolve(that.suggestionsArr)
                        that.documentationView.hide()
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
        @documentationView.setTitle(@suggestionsArr[@currentSuggestionIndex].word, @suggestionsArr[@currentSuggestionIndex].label)
        @documentationView.setContent(@suggestionsArr[@currentSuggestionIndex]._ternDocs)
        @documentationView.show()

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
        @documentationView.hide()

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
            @documentationView.hide()
        @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-confirm', =>
            @clearSuggestions()
            @documentationView.hide()
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
        @documentationView.hide()
        @unregisterEvents()
