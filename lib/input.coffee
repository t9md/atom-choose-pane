module.exports =
class Input
  constructor: ->
    @container = document.createElement('div')
    @container.className = 'choose-pane-editor-container'
    @editor = atom.workspace.buildTextEditor(mini: true)
    @editorElement = @editor.element
    @editorElement.id = 'choose-pane-editor'
    @container.appendChild(@editorElement)

  destroy: ->
    return if @destroyed
    @destroyed = true
    @editor.destroy()
    @panel.destroy()

  readInput: ->
    @panel = atom.workspace.addBottomPanel(item: @container, visible: true)
    @editorElement.focus()

    atom.commands.add @editorElement,
      'choose-pane:last-focused': => @confirm('last-focused')
      'core:confirm': => @confirm()
      'core:cancel': => @cancel()
      'blur': => @cancel() unless @finished

    @editor.onDidChange => @confirm()

    new Promise (@resolve, @reject) =>

  confirm: (message=null) =>
    console.log message
    @reject = null
    @resolve(message ? @editor.getText())
    @cancel()

  cancel: ->
    @finished = true
    @reject?()
    @destroy()
