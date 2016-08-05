path = require 'path'
{CompositeDisposable} = require 'atom'

createLabelElement = (labelChar, className=null) ->
  element = document.createElement("div")
  element.classList.add("choose-pane")
  element.classList.add(className) if className
  element.textContent = labelChar
  element

getView = (model) -> atom.views.getView(model)
isPane = (target) -> target?.constructor?.name is 'Pane'
isPanel = (target) -> target?.constructor?.name is 'Panel'
isFunction = (object) -> typeof(object) is 'function'
isInstanceOfTreeView = (target) -> target.constructor.name is 'TreeView'

getHisotryManager = (initialEntry) ->
  entries = [null, initialEntry]

  save: (entry) ->
    # Ignore unfocus/re-focus to same pane.
    #  e.g. focus mini editor and back to original pane..
    return if @getCurrentFocus() is entry
    entries.shift()
    entries.push(entry)

  getLastFocus: -> entries[0]
  getCurrentFocus: -> entries.slice(-1)[0]

module.exports =
  history: null

  activate: ->
    @history = getHisotryManager(atom.workspace.getActivePane())
    @subscriptions = new CompositeDisposable
    @input = new (require './input')

    @subscribe atom.commands.add 'atom-workspace',
      'choose-pane:start': => @start()
      'choose-pane:focus-last-focused': => @lastFocused()

    handleFocusPane = (event) =>
      @history?.save(event.target.getModel())

    @subscribe atom.workspace.observePanes (pane) ->
      getView(pane).addEventListener('focus', handleFocusPane, false)

    @subscribe atom.workspace.onDidDestroyPane ({pane}) ->
      getView(pane).removeEventListener('focus', handleFocusPane, false)

    @subscribe atom.workspace.panelContainers.left.onDidAddPanel ({panel}) =>
      if isInstanceOfTreeView(item = panel.getItem())
        item.on 'focus.choose-pane', '.tree-view', (event) => @history.save(panel)

    @subscribe atom.workspace.panelContainers.left.onDidRemovePanel ({panel}) ->
      if isInstanceOfTreeView(item = panel.getItem())
        item.off('focus.choose-pane', '.tree-view')

  deactivate: ->
    @input?.destroy()
    @subscriptions?.dispose()
    {@subscriptions, @input, @history} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)

  lastFocused: ->
    target = @history.getLastFocus()
    @focusTarget(target) if target?

  start: ->
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

    focusedElement = document.activeElement
    restoreFocus = -> focusedElement?.focus()

    @input.readInput().then (char) =>
      target = if char is 'last-focused'
        @history.getLastFocus()
      else
        label2Target[char.toLowerCase()]

      if target?
        @focusTarget(target)
      else
        restoreFocus()
      @removeLabelElemnts()
    .catch =>
      restoreFocus()
      @removeLabelElemnts()

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
    className = switch
      when @hasTargetFocused(target) then 'active'
      when target is @history.getLastFocus() then 'last-focused'
    labelElement = createLabelElement(labelChar, className)
    getView(target).appendChild(labelElement)
    @labelElements.push(labelElement)
