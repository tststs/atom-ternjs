apd = require 'atom-package-dependencies'
{Function} = require 'loophole'

module.exports =
class Provider

  manager: null
  force: false
  # automcomplete-plus
  autocompletePlus: null
  selector: '.source.js'
  disableForSelector: '.source.js .comment'
  inclusionPriority: 1
  excludeLowerPriority: true

  init: (manager) ->
    @manager = manager
    atom.packages.activatePackage('autocomplete-plus').then (pkg) =>
      @autocompletePlus = apd.require('autocomplete-plus')

  isValidPrefix: (prefix) ->
    return true if prefix[prefix.length - 1] is '\.'
    return false if prefix[prefix.length - 1]?.match(/;|\s/)
    if prefix.length > 1
      prefix = '_' + prefix
    try (new Function("var " + prefix))()
    catch e then return false
    return true

  checkPrefix: (prefix) ->
    return '' if prefix.match(/(\s|;|\.|\"|\')$/) or prefix.replace(/\s/g, '').length is 0
    prefix

  getPrefix: (editor, bufferPosition) ->
    regexp = /(([\$\w]+[\w-]*)|([.:;'"[{( ]+))$/g
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    line.match(regexp)?[0]

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    tempPrefix = @getPrefix(editor, bufferPosition) or prefix
    if !@isValidPrefix(tempPrefix) and !@force
      return []
    prefix = @checkPrefix(tempPrefix)

    that = this

    return new Promise (resolve) ->
      that.manager.client.update(editor.getURI(), editor.getText()).then =>
        that.manager.client.completions(editor.getURI(), {line: bufferPosition.row, ch: bufferPosition.column}).then (data) =>
          if !data.completions.length
            resolve([])
            return

          suggestionsArr = []

          for obj, index in data.completions
            obj = that.manager.helper.formatTypeCompletion(obj)

            description = if obj.doc then obj.doc else null
            url = if obj.url then obj.doc else null

            suggestionsArr.push {
              text: obj.name
              replacementPrefix: prefix
              className: null
              type: obj._typeSelf
              leftLabel: obj.leftLabel
              snippet: obj._snippet
              description: description
              descriptionMoreURL: url
            }
          resolve(suggestionsArr)
        , (err) ->
          console.log err

  forceCompletion: ->
    @force = true
    # need this for now. no plan, to hook this forever
    @autocompletePlus.autocompleteManager.shouldDisplaySuggestions = true
    @autocompletePlus.autocompleteManager.findSuggestions()
    @force = false

  addSelector: (selector) ->
    @selector = @selector + ',' + selector

  removeSelector: (selector) ->
    @selector = @selector.replace(',' + selector, '')
