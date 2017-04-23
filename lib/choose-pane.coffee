Input = null

isPane = (target) -> target?.constructor?.name is 'Pane'
isPanel = (target) -> target?.constructor?.name is 'Panel'

isFocused = (target) ->
  return switch
    when isPane(target) then target.isFocused()
    when isPanel(target) then target.getItem().hasFocus?()

removeLabels = ->
  for element in document.querySelectorAll("div.choose-pane")
    element.remove()

focusTarget = (target) ->
  return switch
    when isPane(target) then target.activate()
    when isPanel(target) then target.getItem().focus?()

createLabel = (labelChar, className) ->
  element = document.createElement("div")
  element.classList.add("choose-pane")
  element.classList.add(className) if className
  element.textContent = labelChar
  element

module.exports =
class ChoosePane
  constructor: (@history) ->

  choosePaneItem: (which) ->
    pane = atom.workspace.getActivePane()
    pane.activate()
    switch which
      when 'next'
        pane.activateNextItem()
      when 'previous'
        pane.activatePreviousItem()

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
      atom.views.getView(target).appendChild(label)
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

  focusLastFocused: ->
    focusTarget(@history.getLastFocused())

  readInput: ->
    Input ?= require './input'
    new Input().readInput()
