apd = require 'atom-package-dependencies'
{Function} = require 'loophole'

module.exports =
class Provider

  exclusive: true
  manager: null
  suggestionsArr: []
  currentSuggestionIndex: 0
  disposables: []
  maxItems: 200
  force: false
  # automcomplete-plus
  autocompletePlus: null
  selector: '.source.js'
  disableForSelector: '.source.js .comment'
  inclusionPriority: 1
  excludeLowerPriority: false

  init: (manager) ->
    @manager = manager
    atom.packages.activatePackage('autocomplete-plus').then (pkg) =>
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

  checkPrefix: (prefix) ->
    return '' if prefix.match(/(\s|;|\.|\"|\')$/) or prefix.replace(/\s/g, '').length is 0
    prefix

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
    @clearSuggestions()
    @manager.documentation.hide()

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    if !@isValidPrefix(prefix) and !@force
      @manager.documentation.hide()
      return []
    prefix = @checkPrefix(prefix)

    that = this

    return new Promise (resolve) ->
      that.manager.client.update(editor.getURI(), editor.getText()).then =>
        that.manager.client.completions(editor.getURI(), {line: bufferPosition.row, ch: bufferPosition.column}).then (data) =>
          that.clearSuggestions()
          if !data.completions.length
            resolve([])
            that.manager.documentation.hide()
            return
          for obj, index in data.completions
            if index == that.maxItems
              break
            obj = that.manager.helper.formatTypeCompletion(obj)

            that.suggestionsArr.push {
              text: obj.name,
              replacementPrefix: prefix,
              className: null,
              rightLabel: obj.type
              _ternDocs: obj.doc,
              _ternUrl: obj.url,
              _ternOrigin: obj.origin,
            }
          resolve(that.suggestionsArr)
          that.setDocumentationContent()
        , (err) ->
          console.log err

  setDocumentationContent: ->
    if @currentSuggestionIndex >= @suggestionsArr.length
      @manager.documentation.hide()
      return

    currentSuggestion = @suggestionsArr[@currentSuggestionIndex]
    return unless currentSuggestion
    if !currentSuggestion._ternDocs and !currentSuggestion._ternUrl and !currentSuggestion._ternOrigin
      @manager.documentation.hide()
      return

    @manager.documentation.set({
      word: currentSuggestion.text,
      label: currentSuggestion.rightLabel,
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
    Math.min(@maxItems, length)

  addSelector: (selector) ->
    @selector = @selector + ',' + selector

  removeSelector: (selector) ->
    @selector = @selector.replace(',' + selector, '')

  registerEvents: ->
    @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-cancel', =>
      @clearSuggestions()
      @manager.documentation.hide()
    @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-select-next', =>
      return unless @suggestionsArr?.length
      length = @autocompletePlus.autocompleteManager.suggestionList.items.length
      if ++@currentSuggestionIndex >= @getMaxIndex(length)
        @currentSuggestionIndex = 0
      @setDocumentationContent()
    @disposables.push @autocompletePlus.autocompleteManager.suggestionList.emitter.on 'did-select-previous', =>
      return unless @suggestionsArr?.length
      length = @autocompletePlus.autocompleteManager.suggestionList.items.length
      if --@currentSuggestionIndex < 0
        @currentSuggestionIndex = @getMaxIndex(length) - 1
      @setDocumentationContent()

  unregisterEvents: ->
    for disposable in @disposables
      disposable.dispose()
    @disposables = []

  destroy: ->
    @unregisterEvents()
