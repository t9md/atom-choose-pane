{Disposable, CompositeDisposable} = require 'atom'

class Input extends HTMLElement
  createdCallback: ->
    @innerHTML = """
    <div class='choose-pane-editor-container'>
      <atom-text-editor mini id="choose-pane-editor"></atom-text-editor>
    </div>
    """
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

  destroy: ->
    @editor.destroy()
    @panel?.destroy()
    {@editor, @panel, @editorElement} = {}
    @remove()

  handleEvents: ->
    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel': => @cancel()
      'blur': => @cancel() unless @finished

  readInput: ->
    unless @editorElement
      @editorElement = document.getElementById("choose-pane-editor")
      @editor = @editorElement.getModel()
      @editor.onDidChange =>
        @confirm() unless @finished

    @finished = false
    @panel.show()
    @editorElement.focus()
    @commandSubscriptions = @handleEvents()

    new Promise (resolve, reject) =>
      @resolve = resolve
      @reject = reject

  confirm: ->
    @reject = null
    @resolve(@editor.getText())
    @cancel()

  cancel: ->
    @commandSubscriptions?.dispose()
    @reject?()
    @resolve = null
    @reject = null
    @finished = true
    @editor.setText ''
    @panel?.hide()

module.exports = document.registerElement 'choose-pane-input',
  extends: 'div'
  prototype: Input.prototype
