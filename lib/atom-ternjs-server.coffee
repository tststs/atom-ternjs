{BufferedNodeProcess} = require 'atom'

module.exports = ->
  @process = null
  start = (cb) ->
    path = require 'path'
    command = path.resolve __dirname, '../node_modules/.bin/tern'
    args = ['--persistent', '--no-port-file']
    stderr = (output) -> console.error output
    stdout = (output) ->
      output = output.split(" ")
      port = output[output.length - 1]
      console.log "Tern server running on port #{port}"
      cb port
    options =
      cwd: atom.project.getDirectories()[0].path
    exit = (code) -> console.log("tern exited with code: #{code}")
    @process = new BufferedNodeProcess {command, args, options, stdout, stderr, exit}

  stop = ->
    @process?.kill()
    @process = null
  {start, stop}
