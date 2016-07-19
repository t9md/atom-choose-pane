{CompositeDisposable} = require 'atom'

createElement = (label) ->
  element = document.createElement "div"
  element.classList.add("choose-pane")
  element.textContent = label
  element

isFunction = (object) ->
  typeof(object) is 'function'

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-workspace',
      'choose-pane:start': => @start()

  deactivate: ->
    @input?.destroy()
    @subscriptions?.dispose()
    {@subscriptions, @input, @lastFocused} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)

  start: ->
    focusedElement = document.activeElement
    restoreFocus = ->
      focusedElement?.focus()

    targets = [
      atom.workspace.getLeftPanels()...
      atom.workspace.getPanes()...
      atom.workspace.getRightPanels()...
    ]

    label2Target = {}
    labelChars = atom.config.get('choose-pane.labelChars').split('')
    for target in targets when labelChar = labelChars.shift()
      label2Target[labelChar.toLowerCase()] = target
      @renderLabel(target, labelChar)

    @input ?= new (require './input')
    @input.readInput().then (char) =>
      target = if char is 'last-focused'
        @lastFocused
      else
        label2Target[char.toLowerCase()]

      if target?
        @focusTarget(target)
        @lastFocused = focusedElement
      else
        restoreFocus()
      @removeLabelElemnts()
    .catch =>
      restoreFocus()
      @removeLabelElemnts()

  focusTarget: (target) ->
    switch
      when isFunction(target.activate) then target.activate() # Pane
      when isFunction(target.getItem) then target.getItem().focus?() # Panel
      else target?.focus() # Raw element

  removeLabelElemnts: ->
    labelElement.remove() for labelElement in @labelElements
    @labelElements = null

  renderLabel: (target, labelChar) ->
    @labelElements ?= []
    labelElement = createElement(labelChar)
    atom.views.getView(target).appendChild(labelElement)
    @labelElements.push(labelElement)
