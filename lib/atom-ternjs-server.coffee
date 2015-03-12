module.exports =
class Server

  process: null

  start: (callback) ->
    path = require 'path'
    command = path.resolve __dirname, '../node_modules/.bin/tern'
    args = ['--persistent', '--no-port-file', '--verbose']
    options =
      cwd: atom.project.getDirectories()[0].path
    stdout = (output) ->
      output = output.split(' ')
      port = parseInt(output[output.length - 1])
      return if isNaN(port)
      callback port

    if @isPlatformWindows()
      {BufferedProcess} = require 'atom'
      @process = new BufferedProcess {command, args, options, stdout, @stderr, @exit}
    else
      {BufferedNodeProcess} = require 'atom'
      @process = new BufferedNodeProcess {command, args, options, stdout, @stderr, @exit}

  stop: ->
    @process?.kill()
    @process = null

  stderr: (output) ->
    content = "atom-ternjs<br />" + output
    atom.notifications.addError(content, dismissable: true)

  exit: (code) ->
    content = "tern exited with code: #{code}.<br />Restart the server via Packages -> Atom Ternjs -> Restart server"
    atom.notifications.addError(content, dismissable: true)

  isPlatformWindows: ->
    document.getElementsByTagName('body')[0].classList.toString().indexOf('platform-win') > -1
