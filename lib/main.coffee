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
    label2Pane = {}
    panes = atom.workspace.getPanes()

    for pane, i in panes
      label = i + 1
      label2Pane[label] = pane
      @showLabelToPane(pane, label)

    @input.readInput().then (input) =>
      if pane = label2Pane[Number(input)]
        pane.activate()
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
