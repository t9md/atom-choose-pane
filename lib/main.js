const {CompositeDisposable} = require("atom")

let choosePane
module.exports = {
  activate() {
    const getView = item => atom.views.getView(item)
    const store = {lastFocused: null, focused: atom.workspace.getActivePane()}

    this.subscriptions = new CompositeDisposable(
      atom.commands.add("atom-workspace", {
        "choose-pane:start": () => {
          if (!choosePane) choosePane = require("./choose-pane")
          choosePane(store)
        },
        "choose-pane:focus-last-focused": () => store.lastFocused && store.lastFocused.activate(),
      }),
      atom.workspace.onDidChangeActivePane(pane => {
        if (store.focused !== pane) {
          store.lastFocused = store.focused
          store.focused = pane
        }
      })
    )
  },

  deactivate() {
    this.subscriptions.dispose()
  },
}
