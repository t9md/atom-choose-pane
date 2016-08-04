{CompositeDisposable} = require 'atom'

createLabelElement = (labelChar, className=null) ->
  element = document.createElement("div")
  element.classList.add("choose-pane")
  element.classList.add(className) if className
  element.textContent = labelChar
  element

getView = (model) -> atom.views.getView(model)
isPane = (target) -> target.constructor.name is 'Pane'
isPanel = (target) -> target.constructor.name is 'Panel'
isFunction = (object) -> typeof(object) is 'function'

getHisotryManager = ->
  entries = [null, null]

  push: (entry) ->
    entries.shift()
    entries.push(entry)
  get: -> entries[0]
  dump: -> entries

module.exports =
  history: null

  activate: ->
    @history = getHisotryManager()
    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-workspace',
      'choose-pane:start': => @start()

    @subscribe atom.workspace.observeActivePane (pane) =>
      @history.push(pane) unless @isLocked()

  locked: false
  lock: -> @locked = true
  unLock: -> @locked = false
  isLocked: -> @locked

  deactivate: ->
    @input?.destroy()
    @subscriptions?.dispose()
    {@subscriptions, @input, @history} = {}

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
        @history.get()
      else
        label2Target[char.toLowerCase()]

      if target?
        @lock()
        @focusTarget(target)
        @history.push(target)
        @unLock()
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
    lastFocused = @history.get()
    return false unless lastFocused?
    if target.constructor is lastFocused.constructor
      target is lastFocused
    else
      false

  hasTargetFocused: (target) ->
    switch
      when isPane(target) then target.isFocused()
      when isPanel(target) then target.getItem().hasFocus?()

  focusTarget: (target) ->
    switch
      when isPane(target) then target.activate()
      when isPanel(target) then target.getItem().focus?()

  removeLabelElemnts: ->
    labelElement.remove() for labelElement in @labelElements
    @labelElements = null

  renderLabel: (target, labelChar) ->
    @labelElements ?= []
    className = @getLabelClassNameForTarget(target)
    labelElement = createLabelElement(labelChar, className)
    getView(target).appendChild(labelElement)
    @labelElements.push(labelElement)
