const {it, fit, ffit, fffit, emitterEventPromise, beforeEach, afterEach} = require("./async-spec-helpers")

function dispatch(element, commandName) {
  atom.commands.dispatch(element, commandName)
}

function waitsForRemoveLabels() {
  waitsFor(() => document.querySelectorAll("div.choose-pane").length === 0)
}

describe("choose-pane", function() {
  let inputElement, inputEditor, editor, workspaceElement
  let editor1, editor2, editor3

  function start() {
    dispatch(atom.workspace.getElement(), "choose-pane:start")
    waitsFor(() => document.getElementById("choose-pane-editor") != null)
    runs(() => {
      inputElement = document.getElementById("choose-pane-editor")
      inputEditor = inputElement.getModel()
    })
  }

  beforeEach(async () => {
    jasmine.attachToDOM(atom.workspace.getElement())
    editor1 = await atom.workspace.open(null)
    editor2 = await atom.workspace.open(null, {split: "right"})
    editor3 = await atom.workspace.open(null, {split: "down"})
    await atom.packages.activatePackage("tree-view")
    await atom.packages.activatePackage("choose-pane")

    dispatch(atom.workspace.getElement(), "tree-view:toggle")
    atom.workspace.paneForItem(editor3).activate()
  })

  describe("chose-pane:start", () => {
    function ensureLabelsForPanes(labels, panes) {
      const labelElements = panes.map(pane => pane.element.lastChild)
      labelElements.every(element => expect(element.classList.contains("choose-pane")).toBe(true))
      const labelsAssigned = labelElements.map(element => element.textContent)
      return expect(labelsAssigned).toEqual(labels)
    }

    const ensureLabels = function(labelMap) {
      const {leftDock, rightDock, bottomDock, center} = labelMap
      if (leftDock) ensureLabelsForPanes(leftDock, atom.workspace.getLeftDock().getPanes())
      if (rightDock) ensureLabelsForPanes(rightDock, atom.workspace.getRightDock().getPanes())
      if (bottomDock) ensureLabelsForPanes(bottomDock, atom.workspace.getBottomDock().getPanes())
      if (center) ensureLabelsForPanes(center, atom.workspace.getCenter().getPanes())
    }

    function chooseLabel(labelChar, fn) {
      runs(() => inputEditor.setText(labelChar))
      waitsForRemoveLabels()
      runs(() => fn())
    }

    describe("tree-view is show on left side", () => {
      it("append label element to each panels and panes", () => {
        runs(() => start())
        runs(() => {
          ensureLabels({leftDock: [";"], center: ["A", "B", "C"]})
          dispatch(inputElement, "core:cancel")
          waitsForRemoveLabels()
        })
      })

      it("can directly focus chosen target", () => {
        runs(() => start())
        runs(() => {
          ensureLabels({leftDock: [";"], center: ["A", "B", "C"]})
          chooseLabel(";", () => expect(document.activeElement.classList.contains("tree-view")).toBe(true))
        })
        runs(() => start())
        runs(() => chooseLabel("A", () => expect(atom.workspace.getActiveTextEditor()).toBe(editor1)))
        runs(() => start())
        runs(() => chooseLabel("B", () => expect(atom.workspace.getActiveTextEditor()).toBe(editor2)))
        runs(() => start())
        runs(() => chooseLabel("C", () => expect(atom.workspace.getActiveTextEditor()).toBe(editor3)))
      })

      it("restore focus when not matching label found", () => {
        runs(() => start())
        runs(() => chooseLabel("Z", () => expect(atom.workspace.getActiveTextEditor()).toBe(editor3)))
      })

      it("can back to last-focused element", () => {
        runs(() => start())
        runs(() => {
          ensureLabels({leftDock: [";"], center: ["A", "B", "C"]})
          chooseLabel(";", () => expect(document.activeElement.classList.contains("tree-view")).toBe(true))
        })

        runs(() => start())
        runs(() => {
          dispatch(inputElement, "choose-pane:last-focused")
          waitsForRemoveLabels()
        })
        runs(() => expect(atom.workspace.getActiveTextEditor()).toBe(editor3))
        runs(() => start())
        runs(() => {
          dispatch(inputElement, "choose-pane:last-focused")
          waitsForRemoveLabels()
        })
        runs(() => expect(document.activeElement.classList.contains("tree-view")).toBe(true))
      })
    })
  })
})
