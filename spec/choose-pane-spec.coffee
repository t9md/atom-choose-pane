openFile = (filePath, options={}, fn=null) ->
  waitsForPromise ->
    atom.workspace.open(filePath, options).then (e) ->
      fn?(e)

getLabelElementsForModel = (model) ->
  element = atom.views.getView(model)
  element.getElementsByClassName('choose-pane')

getLastChildForModel = (model) ->
  element = atom.views.getView(model)
  element.lastChild

dispatch = (element, commandName) ->
  atom.commands.dispatch(element, commandName)

describe "choose-pane", ->
  [main, inputElement, editor, workspaceElement, elementFile1, elementFile2, elementFile3] = []
  [editor1, editor2, editor3] = []
  [waitsForFinish] = []

  getLabelElements = ->
    document.querySelectorAll("div.choose-pane")

  waitsForFinish = ->
    waitsFor ->
      getLabelElements().length is 0

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM workspaceElement
    activationPromise = null

    openFile "file-1", {}, (e) ->
      editor1 = e
      elementFile1 = atom.views.getView(e)
    openFile "file-2", split: 'right', (e) ->
      editor2 = e
      elementFile2 = atom.views.getView(e)
    openFile "file-3", split: 'down', (e) ->
      editor3 = e
      elementFile3 = atom.views.getView(e)

    waitsForPromise ->
      atom.packages.activatePackage("tree-view")

    runs ->
      activationPromise = atom.packages.activatePackage("choose-pane").then (pack) ->
        main = pack.mainModule
        inputElement = main.input.editorElement
      dispatch(workspaceElement, 'choose-pane:start')

    waitsForPromise ->
      activationPromise

    runs ->
      dispatch(inputElement, 'core:cancel')
      dispatch(workspaceElement, 'tree-view:toggle')
    waitsForFinish()

  describe "chose-pane:start", ->
    [leftPanels, panes, rightPanels] = []
    _ensureLabels = (models, labels) ->
      labelElements = models.map(getLastChildForModel)
      labelElements.every (element) -> expect(element.className).toBe('choose-pane')
      labelsAssigned = labelElements.map (element) -> element.textContent
      expect(labelsAssigned).toEqual(labels)

    ensureLabels = (targetsToLabels) ->
      {leftPanels, panes, rightPanels} = targetsToLabels
      _ensureLabels(atom.workspace.getLeftPanels(), leftPanels) if leftPanels?
      _ensureLabels(atom.workspace.getPanes(), panes) if panes?
      _ensureLabels(atom.workspace.getRightPanels(), rightPanels) if rightPanels?

    forEachTarget = (fn) ->
      [ atom.workspace.getLeftPanels()...
        atom.workspace.getPanes()...
        atom.workspace.getRightPanels()...
      ].forEach(fn)

    chooseLabel = (labelChar, fn) ->
      runs -> main.input.editor.setText(labelChar)
      waitsForFinish()
      runs -> fn()

    start = ->
      dispatch(workspaceElement, 'choose-pane:start')

    describe "tree-view is show on left side", ->

      it "append label element to each panels and panes", ->
        runs ->
          start()
          ensureLabels(leftPanels: [';'], panes: ['A', 'B', 'C'], rightPanels: [])
          expect(getLabelElements()).toHaveLength(4)
          dispatch(inputElement, 'core:cancel')

        waitsForFinish()

      it "can directly focus chosen target", ->
        expect(document.activeElement.getModel()).toBe(editor3)

        runs ->
          start()
          ensureLabels(leftPanels: [';'], panes: ['A', 'B', 'C'], rightPanels: [])
          chooseLabel ";", -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

        runs -> start(); chooseLabel "A", -> expect(document.activeElement.getModel()).toBe(editor1)
        runs -> start(); chooseLabel "B", -> expect(document.activeElement.getModel()).toBe(editor2)
        runs -> start(); chooseLabel "C", -> expect(document.activeElement.getModel()).toBe(editor3)

      it "restore focus when not matching label found", ->
        expect(document.activeElement.getModel()).toBe(editor3)
        runs -> start(); chooseLabel "Z", -> expect(document.activeElement.getModel()).toBe(editor3)

      it "can back to last-focused element", ->
        expect(document.activeElement.getModel()).toBe(editor3)

        runs ->
          start()
          ensureLabels(leftPanels: [';'], panes: ['A', 'B', 'C'], rightPanels: [])
          chooseLabel ";", -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

        runs -> start(); dispatch(inputElement, 'choose-pane:last-focused'); waitsForFinish()
        runs -> expect(document.activeElement.getModel()).toBe(editor3)

        runs -> start(); dispatch(inputElement, 'choose-pane:last-focused'); waitsForFinish()
        runs -> expect(document.activeElement.classList.contains('tree-view')).toBe(true)

    describe "when tree-view is shown on right side", ->
      it "append label element to each panels and panes", ->
        runs ->
          atom.config.set('tree-view.showOnRightSide', true)
          dispatch(workspaceElement, 'choose-pane:start')
          ensureLabels(leftPanels: [], panes: [';', 'A', 'B'], rightPanels: ['C'])
          expect(getLabelElements()).toHaveLength(4)
          dispatch(inputElement, 'core:cancel')
        waitsForFinish()

        runs -> forEachTarget (model) -> expect(getLabelElementsForModel(model)).toHaveLength(0)
