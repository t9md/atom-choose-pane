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

getHisotryManager = ->
  entries = [null, null]

  save: (entry) ->
    return if @getCurrentFocus() is entry
    entries.shift()
    entries.push(entry)
    # @dump("SAVING")
  getLastFocus: -> entries[0]
  getCurrentFocus: -> entries.slice(-1)[0]

  dumpEntry: (entry) ->
    name = entry?.constructor?.name
    str = switch
      when isPane(entry) then path.basename(entry.getActiveEditor()?.getPath?())
      when isPanel(entry) then 'Panel'
    "#{name}: #{str}"

  dump: (msg) ->
    unless entries.length is 2
      throw "WANNA DIE"
    console.log "-#{msg}--:", entries.map (e) => @dumpEntry(e)

module.exports =
  history: null

  activate: ->
    @history = getHisotryManager()
    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-workspace',
      'choose-pane:start': => @start()

    handleFocusPane = (event) =>
      # console.log "focus pane", event.target
      @history?.save(event.target.getModel())

    @subscribe atom.workspace.observePanes (pane) ->
      getView(pane).addEventListener('focus', handleFocusPane, false)

    @subscribe atom.workspace.onDidDestroyPane ({pane}) ->
      getView(pane).removeEventListener('focus', handleFocusPane, false)

    @subscribe atom.workspace.panelContainers.left.onDidAddPanel ({panel}) =>
      item = panel.getItem()
      return unless isInstanceOfTreeView(item)
      item.on 'focus.choose-pane', '.tree-view', (event) =>
        # console.log "focus panel", event.target
        @history.save(panel)

    @subscribe atom.workspace.panelContainers.left.onDidRemovePanel ({panel}) ->
      # console.log 'removed', panel
      item = panel.getItem()
      return unless isInstanceOfTreeView(item)
      item.off('focus.choose-pane', '.tree-view')

  deactivate: ->
    @input?.destroy()
    @subscriptions?.dispose()
    {@subscriptions, @input, @history} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)

  start: ->
    @history.dump('start')
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

  getLabelClassNameForTarget: (target) ->
    switch
      when @hasTargetFocused(target) then 'active'
      when target is @history.getLastFocus() then 'last-focused'

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
