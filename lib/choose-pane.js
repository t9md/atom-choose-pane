function removeLabels() {
  for (const node of document.querySelectorAll("div.choose-pane")) {
    node.remove()
  }
}

function createLabel(labelChar, className) {
  const element = document.createElement("div")
  element.classList.add("choose-pane")
  if (className) {
    element.classList.add(className)
  }
  element.textContent = labelChar
  return element
}

function readInput() {
  const editor = atom.workspace.buildTextEditor({mini: true})
  editor.element.id = "choose-pane-editor"

  const container = document.createElement("div")
  container.className = "choose-pane-editor-container"
  container.appendChild(editor.element)

  // So that I can skip jasmine.attachToDOM in test.
  const parentNode = atom.workspace.getElement()
  parentNode.appendChild(editor.element)

  editor.element.focus()

  let confirmed = false
  const confirm = action => {
    if (confirmed) return

    confirmed = true
    const char = editor.getText()
    parentNode.removeChild(editor.element)
    editor.destroy()

    resolve({action, char})
  }

  atom.commands.add(editor.element, {
    "choose-pane:last-focused": () => confirm("last-focused"),
    "choose-pane:next-item": () => confirm("next-item"),
    "choose-pane:previous-item": () => confirm("previous-item"),
    "core:confirm": () => confirm("label"),
    "core:cancel": () => confirm("cancel"),
    blur: () => confirm("cancel"),
  })

  editor.onDidChange(() => {
    const text = editor.getText()
    if (text) confirm("label")
  })

  let resolve
  return new Promise(_resolve => (resolve = _resolve))
}

module.exports = async function choosePane(store) {
  const labelChars = atom.config.get("choose-pane.labelChars").split("")
  const paneByLabel = {}

  const activePane = atom.workspace.getActivePane()

  const getPanes = container => {
    return container.isVisible() ? container.getPanes() : []
  }

  const allPanes = [
    ...getPanes(atom.workspace.getLeftDock()),
    ...atom.workspace.getCenter().getPanes(),
    ...getPanes(atom.workspace.getRightDock()),
    ...getPanes(atom.workspace.getBottomDock()),
  ]
  for (const pane of allPanes) {
    const labelChar = labelChars.shift()
    if (labelChar) {
      const className = pane === activePane ? "active" : pane === store.lastFocused ? "last-focused" : null
      atom.views.getView(pane).appendChild(createLabel(labelChar, className))
      paneByLabel[labelChar.toLowerCase()] = pane
    }
  }

  const {action, char} = await readInput()
  if (action === "next-item") {
    atom.workspace.getActivePane().activateNextItem()
    removeLabels()
    choosePane(store)
  } else if (action === "previous-item") {
    atom.workspace.getActivePane().activatePreviousItem()
    removeLabels()
    choosePane(store)
  } else {
    const pane = action === "last-focused" ? store.lastFocused : paneByLabel[char.toLowerCase()]
    if (action === "last-focused") {
      // console.log(pane.getActiveItem())
      // console.log(pane, pane.isAlive());
    }
    if (pane) {
      pane.activate()
    } else {
      atom.workspace.getActivePane().activate()
    }
    removeLabels()
  }
}
