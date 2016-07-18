{CompositeDisposable} = require 'atom'

createElement = (label) ->
  element = document.createElement "div"
  element.classList.add("choose-pane")
  element.textContent = label
  element

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-workspace',
      'choose-pane:start': => @start()

  deactivate: ->
    @input?.destroy()
    @subscriptions?.dispose()
    {@subscriptions, @input} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)

  start: ->
    @labelElements = []
    label2Target = {}

    targets = [
      atom.workspace.getLeftPanels()...
      atom.workspace.getPanes()...
      atom.workspace.getRightPanels()...
    ]

    labelChars = atom.config.get('choose-pane.labelChars').split('')
    for target in targets when labelChar = labelChars.shift()
      label2Target[labelChar.toLowerCase()] = target
      @renderLabel(target, labelChar)

    @input ?= new (require './input')
    @input.readInput().then (input) =>
      if target = label2Target[input.toLowerCase()]
        @focusTarget(target)
      @removeLabelElemnts()
    .catch =>
      atom.workspace.getActivePane().activate()
      @removeLabelElemnts()

  focusTarget: (target) ->
    if typeof(target.activate) is 'function'
      # Pane
      target.activate()
    else
      # Panel
      target.getItem()?.focus?()

  removeLabelElemnts: ->
    labelElement.remove() for labelElement in @labelElements
    @labelElements = []

  renderLabel: (target, label) ->
    labelElement = createElement(label)
    atom.views.getView(target).appendChild(labelElement)
    @labelElements.push(labelElement)
