class Input extends HTMLElement
  createdCallback: ->
    @innerHTML = """
    <div class='choose-pane-editor-container'>
      <atom-text-editor mini id="choose-pane-editor"></atom-text-editor>
    </div>
    """
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

  attachedCallback: ->
    @editorElement = document.getElementById("choose-pane-editor")
    @editor = @editorElement.getModel()
    @editor.onDidChange =>
      @confirm() unless @finished
    this

  destroy: ->
    @editor?.destroy()
    @panel.destroy()
    {@panel, @editor, @editorElement} = {}
    @remove()

  handleEvents: ->
    atom.commands.add @editorElement,
      'choose-pane:last-focused': => @confirm('last-focused')
      'core:confirm': => @confirm()
      'core:cancel': => @cancel()
      'blur': => @cancel() unless @finished

  readInput: ->
    @finished = false
    @panel.show()
    @editorElement.focus()
    @commandSubscription = @handleEvents()

    new Promise (@resolve, @reject) =>

  confirm: (message=null) ->
    @reject = null
    @resolve(message ? @editor.getText())
    @cancel()

  cancel: ->
    @commandSubscription?.dispose()
    @reject?()
    {@resolve, @reject} = {}
    @finished = true
    @editor.setText('')
    @panel.hide()

module.exports = document.registerElement 'choose-pane-input',
  extends: 'div'
  prototype: Input.prototype
