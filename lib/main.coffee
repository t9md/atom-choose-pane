path = require 'path'
{CompositeDisposable, Disposable} = require 'atom'
Input = null

createLabel = (labelChar, className) ->
  element = document.createElement("div")
  element.classList.add("choose-pane")
  element.classList.add(className) if className
  element.textContent = labelChar
  element

removeLabels = ->
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

getHistoryManager = (initialEntry) ->
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
    @history = getHistoryManager(atom.workspace.getActivePane())
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'choose-pane:start': => @start()
      'choose-pane:focus-last-focused': => focusTarget(@history.getLastFocused())

    @observeFocusOfPane()
    @observeFocusOfTreeViewPanel()

  observeFocusOfPane: ->
    handleFocusPane = (event) =>
      @history?.save(event.target.getModel())

    @subscriptions.add atom.workspace.observePanes (pane) ->
      getView(pane).addEventListener('focus', handleFocusPane, false)

    @subscriptions.add atom.workspace.onDidDestroyPane ({pane}) ->
      getView(pane).removeEventListener('focus', handleFocusPane, false)

    @subscriptions.add new Disposable ->
      for pane in atom.workspace.getPanes()
        getView(pane).removeEventListener('focus', handleFocusPane, false)

  observeFocusOfTreeViewPanel: ->
    treeViewPanel = null
    treeViewListElement = null
    saveTreeViewPanelToHistory = => @history.save(treeViewPanel)

    @subscriptions.add atom.workspace.panelContainers.left.onDidAddPanel ({panel}) ->
      if isInstanceOfTreeView(item = panel.getItem())
        treeViewPanel = panel
        if typeof(item.list.addEventListener) is 'function'
          treeViewListElement = item.list
        else
          treeViewListElement = item.list[0]
        treeViewListElement.addEventListener('focus', saveTreeViewPanelToHistory, false)

    removeListnerFromTreeViewListElement = ->
      treeViewListElement?.removeEventListener('focus', saveTreeViewPanelToHistory, false)

    @subscriptions.add atom.workspace.panelContainers.left.onDidRemovePanel ({panel}) ->
      if panel is treeViewPanel
        removeListnerFromTreeViewListElement()

    @subscriptions.add new Disposable -> removeListnerFromTreeViewListElement()

  deactivate: ->
    @subscriptions?.dispose()
    {@subscriptions, @history} = {}

  choosePaneItem: (which) ->
    pane = atom.workspace.getActivePane()
    pane.activate()
    switch which
      when 'next' then pane.activateNextItem()
      when 'previous' then pane.activatePreviousItem()

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

      label = createLabel(labelChar, className)
      getView(target).appendChild(label)
      targetByLabel[labelChar.toLowerCase()] = target

    focusedElement = document.activeElement
    restoreFocus = -> focusedElement?.focus()

    @readInput().then ({action, char}) =>
      if action in ['next-item', 'previous-item']
        if action is 'next-item'
          @choosePaneItem('next')
        else
          @choosePaneItem('previous')
        removeLabels()
        @start()
        return

      if action is 'last-focused'
        target = lastFocusedTarget
      else
        target = targetByLabel[char.toLowerCase()]
      if target?
        focusTarget(target)
      else
        restoreFocus()
      removeLabels()
    .catch ->
      restoreFocus()
      removeLabels()

  readInput: ->
    Input ?= require './input'
    new Input().readInput()
