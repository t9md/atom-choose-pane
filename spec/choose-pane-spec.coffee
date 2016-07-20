openFile = (filePath, options={}, fn=null) ->
  waitsForPromise ->
    atom.workspace.open(filePath, options).then (e) ->
      fn?(e)

getLabelElementsForModel = (model) ->
  element = atom.views.getView(model)
  element.getElementsByClassName('choose-pane')

getLastChildFromModel = (model) ->
  element = atom.views.getView(model)
  element.lastChild

describe "choose-pane", ->
  [main, editor, workspaceElement, elementFile1, elementFile2, elementFile3] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM workspaceElement
    activationPromise = null

    openFile "file-1", {}, (e) -> elementFile1 = atom.views.getView(e)
    openFile "file-2", split: 'right', (e) -> elementFile2 = atom.views.getView(e)
    openFile "file-3", split: 'down', (e) -> elementFile3 = atom.views.getView(e)

    waitsForPromise ->
      atom.packages.activatePackage("tree-view")

    runs ->
      activationPromise = atom.packages.activatePackage("choose-pane").then (pack) ->
        main = pack.mainModule
      atom.commands.dispatch(workspaceElement, 'choose-pane:start')

    waitsForPromise ->
      activationPromise

    runs ->
      atom.commands.dispatch(main.input.editorElement, 'core:cancel')
      atom.commands.dispatch(workspaceElement, 'tree-view:toggle')

    waitsFor ->
      main.labelElements is null

  describe "chose-pane:start", ->
    [leftPanels, panes, rightPanels, targets] = []
    ensureLabels = (models, {labels}) ->
      labelElements = models.map(getLastChildFromModel)
      labelElements.every (element) -> expect(element.className).toBe('choose-pane')
      labelsAssigned = labelElements.map (element) -> element.textContent
      expect(labelsAssigned).toEqual(labels)

    updateTargets = ->
      leftPanels = atom.workspace.getLeftPanels()
      panes = atom.workspace.getPanes()
      rightPanels = atom.workspace.getRightPanels()
      targets = [leftPanels..., panes..., rightPanels...]

    chooseLabel = (labelChar, fn) ->
      runs -> main.input.editor.setText(labelChar)
      waitsFor -> main.labelElements is null
      runs -> fn()

    start = ->
      atom.commands.dispatch(workspaceElement, 'choose-pane:start')

    describe "tree-view is show on left side", ->

      it "append label element to each panels and panes", ->
        runs ->
          start()
          updateTargets()
          ensureLabels(leftPanels, labels: [';'])
          ensureLabels(panes, labels: ['A', 'B', 'C'])
          ensureLabels(rightPanels, labels: [])
          expect(main.labelElements).toHaveLength(4)
          atom.commands.dispatch(main.input.editorElement, 'core:cancel')

        waitsFor -> main.labelElements is null
        runs -> targets.forEach (model) -> expect(getLabelElementsForModel(model)).toHaveLength(0)

      it "can directly focus chosen target", ->
        expect(document.activeElement).toBe(elementFile3)

        runs ->
          start()
          updateTargets()
          ensureLabels(leftPanels, labels: [';'])
          ensureLabels(panes, labels: ['A', 'B', 'C'])
          ensureLabels(rightPanels, labels: [])
          chooseLabel ";", -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

        runs -> start(); chooseLabel "A", -> expect(document.activeElement).toBe(elementFile1)
        runs -> start(); chooseLabel "B", -> expect(document.activeElement).toBe(elementFile2)
        runs -> start(); chooseLabel "C", -> expect(document.activeElement).toBe(elementFile3)

      it "restore focus when not matching label found", ->
        expect(document.activeElement).toBe(elementFile3)
        runs -> start(); chooseLabel "Z", -> expect(document.activeElement).toBe(elementFile3)

      it "can back to last-focused element", ->
        expect(document.activeElement).toBe(elementFile3)

        runs ->
          start()
          updateTargets()
          ensureLabels(leftPanels, labels: [';'])
          ensureLabels(panes, labels: ['A', 'B', 'C'])
          ensureLabels(rightPanels, labels: [])
          chooseLabel ";", -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

        runs -> start(); atom.commands.dispatch(main.input.editorElement, 'choose-pane:last-focused')
        waitsFor -> main.labelElements is null
        runs -> expect(document.activeElement).toBe(elementFile3)

        runs -> start(); atom.commands.dispatch(main.input.editorElement, 'choose-pane:last-focused')
        waitsFor -> main.labelElements is null
        runs -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

    describe "when tree-view is shown on right side", ->
      it "append label element to each panels and panes", ->
        runs ->
          atom.config.set('tree-view.showOnRightSide', true)
          updateTargets()
          atom.commands.dispatch(workspaceElement, 'choose-pane:start')
          ensureLabels(leftPanels, labels: [])
          ensureLabels(panes, labels: [';', 'A', 'B'])
          ensureLabels(rightPanels, labels: ['C'])
          expect(main.labelElements).toHaveLength(4)
          atom.commands.dispatch(main.input.editorElement, 'core:cancel')

        waitsFor -> main.labelElements is null
        runs -> targets.forEach (model) -> expect(getLabelElementsForModel(model)).toHaveLength(0)
