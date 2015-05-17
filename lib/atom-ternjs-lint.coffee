{Range} = require 'atom'
module.exports =
class Lint

  manager: null
  overlayDecoration: null
  marker: null

  constructor: (manager, state = {}) ->
    @manager = manager

  setMarker: (data) ->
    editor = atom.workspace.getActiveTextEditor()
    range = new Range([0, 0], [0, 0])
    @marker = editor.markBufferRange(range, invalidate: 'touch')
    return unless @marker
    @overlayDecoration = editor.decorateMarker(@marker, {type: 'highlight', class: 'atom-ternjs-lint'})

  destroyOverlay: ->
    @overlayDecoration?.destroy()
    @overlayDecoration = null
    @marker = null

  destroy: ->
    @destroyOverlay()
