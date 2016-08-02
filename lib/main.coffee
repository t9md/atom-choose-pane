{CompositeDisposable} = require 'atom'

createLabelElement = (labelChar, className=null) ->
  element = document.createElement("div")
  element.classList.add("choose-pane")
  element.classList.add(className) if className
  element.textContent = labelChar
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

  getLabelClassNameForTarget: (target) ->
    switch
      when @hasTargetFocused(target) then 'active'
      when @hasLastFocused(target) then 'last-focused'

  hasLastFocused: (target) ->
    return false unless @lastFocused?
    switch
      when isFunction(target.activate) then atom.views.getView(target).contains(@lastFocused)
      when isFunction(target.getItem) then target.getItem()[0].contains(@lastFocused)

  hasTargetFocused: (target) ->
    switch
      when isFunction(target.activate) then target.isFocused() # Pane
      when isFunction(target.getItem) then target.getItem().hasFocus?() # Panel

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
    className = @getLabelClassNameForTarget(target)
    labelElement = createLabelElement(labelChar, className)
    atom.views.getView(target).appendChild(labelElement)
    @labelElements.push(labelElement)
