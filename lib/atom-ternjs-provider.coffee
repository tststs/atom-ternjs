{Function} = require 'loophole'
_ = require 'underscore-plus'

module.exports =
class Provider

  manager: null
  force: false
  # automcomplete-plus
  selector: '.source.js'
  disableForSelector: '.source.js .comment'
  inclusionPriority: 1
  excludeLowerPriority: true

  init: (manager) ->
    @manager = manager

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

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    return [] unless @manager.client
    tempPrefix = @getPrefix(editor, bufferPosition) or prefix
    if !@isValidPrefix(tempPrefix) and !@force and !activatedManually
      return []
    prefix = @checkPrefix(tempPrefix)

    return new Promise (resolve) =>
      @manager.client.update(editor.getURI(), editor.getText()).then =>
        @manager.client.completions(editor.getURI(), {line: bufferPosition.row, ch: bufferPosition.column}).then (data) =>
          if !data.completions.length
            resolve([])
            return

          suggestionsArr = []

          for obj, index in data.completions
            obj = @manager.helper.formatTypeCompletion(obj)
            description = if obj.doc then obj.doc else null
            url = if obj.url then obj.url else null

            suggestion =
              text: obj.name
              replacementPrefix: prefix
              className: null
              type: obj._typeSelf
              leftLabel: obj.leftLabel
              snippet: obj._snippet
              description: description
              descriptionMoreURL: url

            if atom.config.get('atom-ternjs.useSnippetsAndFunction') and obj._hasParams
              suggestionClone = _.clone(suggestion)
              suggestionClone.type = 'snippet'
              suggestion.snippet = if obj._hasParams then "#{obj.name}(${#{0}:#{}})" else "#{obj.name}()"
              suggestionsArr.push suggestion
              suggestionsArr.push suggestionClone
            else
              suggestionsArr.push suggestion

          resolve(suggestionsArr)
        , (err) ->
          console.log err

  forceCompletion: ->
    @force = true
    atom.commands.dispatch(atom.views.getView(atom.workspace.getActiveTextEditor()), 'autocomplete-plus:activate');
    @force = false
