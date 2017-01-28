path = require 'path'
{CompositeDisposable} = require 'atom'

createLabelElement = (labelChar, className=null) ->
  element = document.createElement("div")
  element.classList.add("choose-pane")
  element.classList.add(className) if className
  element.textContent = labelChar
  element

removeLabelElemnts = ->
  for element in document.querySelectorAll("div.choose-pane")
    element.remove()

getView = (model) -> atom.views.getView(model)
isPane = (target) -> target?.constructor?.name is 'Pane'
isPanel = (target) -> target?.constructor?.name is 'Panel'
isFunction = (object) -> typeof(object) is 'function'
isInstanceOfTreeView = (target) -> target.constructor.name is 'TreeView'

isFocused = (target) ->
  return switch
    when isPane(target) then target.isFocused()
    when isPanel(target) then target.getItem().hasFocus?()

focusTarget = (target) ->
  return switch
    when isPane(target) then target.activate()
    when isPanel(target) then target.getItem().focus?()

getHisotryManager = (initialEntry) ->
  entries = [null, initialEntry]

  save: (entry) ->
    # Ignore unfocus/re-focus to same pane.
    #  e.g. focus mini editor and back to original pane..
    return if @getCurrentFocus() is entry
    entries.shift()
    entries.push(entry)

  getLastFocused: -> entries[0]
  getCurrentFocus: -> entries.slice(-1)[0]

module.exports =
  history: null

  activate: ->
    @history = getHisotryManager(atom.workspace.getActivePane())
    @subscriptions = new CompositeDisposable
    @input = new (require './input')

    @subscriptions.add atom.commands.add 'atom-workspace',
      'choose-pane:start': => @start()
      'choose-pane:focus-last-focused': => focusTarget(@history.getLastFocused())

    handleFocusPane = (event) =>
      @history?.save(event.target.getModel())

    @subscriptions.add atom.workspace.observePanes (pane) ->
      getView(pane).addEventListener('focus', handleFocusPane, false)

    @subscriptions.add atom.workspace.onDidDestroyPane ({pane}) ->
      getView(pane).removeEventListener('focus', handleFocusPane, false)

    @subscriptions.add atom.workspace.panelContainers.left.onDidAddPanel ({panel}) =>
      if isInstanceOfTreeView(item = panel.getItem())
        item.on 'focus.choose-pane', '.tree-view', (event) => @history.save(panel)

    @subscriptions.add atom.workspace.panelContainers.left.onDidRemovePanel ({panel}) ->
      if isInstanceOfTreeView(item = panel.getItem())
        item.off('focus.choose-pane', '.tree-view')

  deactivate: ->
    @input?.destroy()
    @subscriptions?.dispose()
    {@subscriptions, @input, @history} = {}

  start: ->
    targets = [
      atom.workspace.getLeftPanels()...
      atom.workspace.getPanes()...
      atom.workspace.getRightPanels()...
    ]

    labelChars = atom.config.get('choose-pane.labelChars').split('')
    targetByLabel = {}
    lastFocusedTarget = @history.getLastFocused()

    for target in targets when labelChar = labelChars.shift()
      className = switch
        when isFocused(target) then 'active'
        when target is lastFocusedTarget then 'last-focused'

      getView(target).appendChild(createLabelElement(labelChar, className))
      targetByLabel[labelChar.toLowerCase()] = target

    # Special label used for focus-last-focused
    targetByLabel['last-focused'] = lastFocusedTarget

    focusedElement = document.activeElement
    restoreFocus = -> focusedElement?.focus()

    @input.readInput().then (char) =>
      if target = targetByLabel[char.toLowerCase()]
        focusTarget(target)
      else
        restoreFocus()
      removeLabelElemnts()
    .catch =>
      restoreFocus()
      removeLabelElemnts()
