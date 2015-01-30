{BufferedNodeProcess} = require 'atom'
{BufferedProcess} = require 'atom'

module.exports = ->
  @process = null
  start = (cb) ->
    isPlatformWindows = document.getElementsByTagName('body')[0].classList.toString().indexOf('platform-win') > -1
    path = require 'path'
    command = path.resolve __dirname, '../node_modules/.bin/tern'
    args = ['--persistent', '--no-port-file']
    stderr = (output) -> console.error output
    stdout = (output) ->
      output = output.split(" ")
      port = parseInt output[output.length - 1]
      return if isNaN(port)
      cb port
    options =
      cwd: atom.project.getDirectories()[0].path
    exit = (code) -> console.log("tern exited with code: #{code}")
    if isPlatformWindows
      @process = new BufferedProcess {command, args, options, stdout, stderr, exit}
    else
      @process = new BufferedNodeProcess {command, args, options, stdout, stderr, exit}

  stop = ->
    @process?.kill()
    @process = null
  {start, stop}
