{CompositeDisposable} = require 'atom'

Input = require './input'

createElement = (label) ->
  element = document.createElement "div"
  element.classList.add("choose-pane")
  element.textContent = label
  element

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable
    @input = new Input

    @subscribe atom.commands.add 'atom-workspace',
      'choose-pane:start': => @start()

  start: ->
    @labelElements = []
    label2Target = {}

    leftPanels = atom.workspace.getLeftPanels()
    panes = atom.workspace.getPanes()
    rightPanels = atom.workspace.getRightPanels()
    targets = [leftPanels..., panes..., rightPanels...]

    labelChars = atom.config.get('choose-pane.labelChars').split('')

    for target in targets when labelChar = labelChars.shift()
      label2Target[labelChar.toLowerCase()] = target
      @showLabelToPane(target, labelChar)

    @input.readInput().then (input) =>
      if target = label2Target[input.toLowerCase()]
        if typeof(target.activate) is 'function'
          # Pane
          target.activate()
        else
          # Panel
          target.getItem()?.focus?()
      @removeLabelElemnts()
    .catch =>
      atom.workspace.getActivePane().activate()
      @removeLabelElemnts()

  removeLabelElemnts: ->
    labelElement.remove() for labelElement in @labelElements

  showLabelToPane: (pane, label) ->
    labelElement = createElement(label)
    atom.views.getView(pane).appendChild(labelElement)
    @labelElements.push(labelElement)

  subscribe: (arg) ->
    @subscriptions.add(arg)

  deactivate: ->
    @subscriptions?.dispose()
    {@subscriptions} = {}
