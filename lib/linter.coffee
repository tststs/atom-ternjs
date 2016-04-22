class LinterTern

  name: 'Tern'
  grammarScopes: ['source.js']
  scope: 'file'
  lintOnFly: true
  manager: null

  constructor: (manager) ->
    @manager = manager
    return unless @manager

  lint: (textEditor) ->
    return new Promise (resolve, reject) =>
      return resolve [] unless @manager.config?.config?.plugins.lint?.active
      return resolve [] unless @manager.server

      messages = []

      buffer = textEditor.getBuffer()
      URI = atom.project.relativizePath(textEditor.getURI())[1]

      text = textEditor.getText()
      @manager.client?.update(textEditor).then (data) =>
        @manager.client.lint(URI, text).then (data) =>
          return resolve [] unless data?.messages
          for message in data.messages
            positionFrom = buffer.positionForCharacterIndex(message.from)
            positionTo = buffer.positionForCharacterIndex(message.to)
            messages.push
              text: message.message,
              type: message.severity,
              filePath: buffer.file.path
              range: [
                [positionFrom.row, positionFrom.column],
                [positionTo.row, positionTo.column]
              ]
          return resolve messages

module.exports = LinterTern
