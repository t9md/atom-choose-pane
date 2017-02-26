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
      'choose-pane:next-item': => @confirm('next-item')
      'choose-pane:previous-item': => @confirm('previous-item')
      'core:confirm': => @confirm('label')
      'core:cancel': => @cancel()
      'blur': => @cancel() unless @finished

    @editor.onDidChange => @confirm('label')

    new Promise (@resolve, @reject) =>

  confirm: (action) =>
    @reject = null
    @resolve(action: action, char: @editor.getText())
    @cancel()

  cancel: ->
    @finished = true
    @reject?()
    @destroy()
