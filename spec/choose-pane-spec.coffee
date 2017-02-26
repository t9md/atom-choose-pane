getLastChildForModel = (model) ->
  element = atom.views.getView(model)
  element.lastChild

dispatch = (element, commandName) ->
  atom.commands.dispatch(element, commandName)

getLabelElements = ->
  document.querySelectorAll("div.choose-pane")

waitsForRemoveLabels = ->
  waitsFor ->
    getLabelElements().length is 0

describe "choose-pane", ->
  [inputElement, inputEditor, editor, workspaceElement] = []
  [editor1, editor2, editor3] = []

  start = ->
    dispatch(workspaceElement, 'choose-pane:start')
    inputElement = document.activeElement
    inputEditor = inputElement.getModel()

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM workspaceElement
    activationPromise = null

    waitsForPromise -> atom.workspace.open(null).then (e) -> editor1 = e
    waitsForPromise -> atom.workspace.open(null, split: 'right').then (e) -> editor2 = e
    waitsForPromise -> atom.workspace.open(null, split: 'down').then (e) -> editor3 = e
    waitsForPromise -> atom.packages.activatePackage("tree-view")
    waitsForPromise -> atom.packages.activatePackage("choose-pane")

    runs ->
      dispatch(workspaceElement, 'tree-view:toggle')
      atom.workspace.paneForItem(editor3).activate()

  describe "chose-pane:start", ->
    [leftPanels, panes, rightPanels] = []
    _ensureLabels = (models, labels) ->
      labelElements = models.map(getLastChildForModel)
      labelElements.every (element) -> expect(element.classList.contains('choose-pane')).toBe(true)
      labelsAssigned = labelElements.map (element) -> element.textContent
      expect(labelsAssigned).toEqual(labels)

    ensureLabels = (targetsToLabels) ->
      {leftPanels, panes, rightPanels} = targetsToLabels
      _ensureLabels(atom.workspace.getLeftPanels(), leftPanels) if leftPanels?
      _ensureLabels(atom.workspace.getPanes(), panes) if panes?
      _ensureLabels(atom.workspace.getRightPanels(), rightPanels) if rightPanels?

    chooseLabel = (labelChar, fn) ->
      runs -> inputEditor.setText(labelChar)
      waitsForRemoveLabels()
      runs -> fn()

    describe "tree-view is show on left side", ->
      it "append label element to each panels and panes", ->
        runs ->
          start()
          ensureLabels(leftPanels: [';'], panes: ['A', 'B', 'C'], rightPanels: [])
          expect(getLabelElements()).toHaveLength(4)
          dispatch(inputElement, 'core:cancel')

        waitsForRemoveLabels()

      it "can directly focus chosen target", ->
        runs ->
          start()
          ensureLabels(leftPanels: [';'], panes: ['A', 'B', 'C'], rightPanels: [])
          chooseLabel ";", -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

        runs -> start(); chooseLabel "A", -> expect(document.activeElement.getModel()).toBe(editor1)
        runs -> start(); chooseLabel "B", -> expect(document.activeElement.getModel()).toBe(editor2)
        runs -> start(); chooseLabel "C", -> expect(document.activeElement.getModel()).toBe(editor3)

      it "restore focus when not matching label found", ->
        runs -> start(); chooseLabel "Z", -> expect(document.activeElement.getModel()).toBe(editor3)

      it "can back to last-focused element", ->
        runs ->
          start()
          ensureLabels(leftPanels: [';'], panes: ['A', 'B', 'C'], rightPanels: [])
          chooseLabel ";", -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

        runs -> start(); dispatch(inputElement, 'choose-pane:last-focused'); waitsForRemoveLabels()
        runs -> expect(document.activeElement.getModel()).toBe(editor3)

        runs -> start(); dispatch(inputElement, 'choose-pane:last-focused'); waitsForRemoveLabels()
        runs -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

    describe "when tree-view is shown on right side", ->
      it "append label element to each panels and panes", ->
        runs ->
          atom.config.set('tree-view.showOnRightSide', true)
          start()
          ensureLabels(leftPanels: [], panes: [';', 'A', 'B'], rightPanels: ['C'])
          expect(getLabelElements()).toHaveLength(4)
          dispatch(inputElement, 'core:cancel')
        waitsForRemoveLabels()
