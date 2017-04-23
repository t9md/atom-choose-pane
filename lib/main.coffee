{CompositeDisposable, Disposable} = require 'atom'
ChoosePane = null

getHistoryManager = ->
  initialEntry = atom.workspace.getActivePane()
  entries = [null, initialEntry]

  save: (entry) ->
    # Ignore unfocus/re-focus to same pane.
    #  e.g. focus mini editor and back to original pane..
    return if @getCurrentFocus() is entry
    entries.shift()
    entries.push(entry)

  getLastFocused: -> entries[0]
  getCurrentFocus: -> entries.slice(-1)[0]

module.exports =
  history: null

  getChoosePane: ->
    ChoosePane ?= require './choose-pane'
    @choosePane ?= new ChoosePane(@history)

  activate: ->
    @history = getHistoryManager()
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'choose-pane:start': => @getChoosePane().start()
      'choose-pane:focus-last-focused': => @getChoosePane().focusLastFocused()

    @observeFocusOfPane()
    @observeFocusOfTreeViewPanel()

  observeFocusOfPane: ->
    handleFocusPane = (event) =>
      @history?.save(event.target.getModel())

    @subscriptions.add atom.workspace.observePanes (pane) ->
      atom.views.getView(pane).addEventListener('focus', handleFocusPane, false)

    @subscriptions.add atom.workspace.onDidDestroyPane ({pane}) ->
      atom.views.getView(pane).removeEventListener('focus', handleFocusPane, false)

    @subscriptions.add new Disposable ->
      for pane in atom.workspace.getPanes()
        atom.views.getView(pane).removeEventListener('focus', handleFocusPane, false)

  observeFocusOfTreeViewPanel: ->
    treeViewPanel = null
    treeViewListElement = null
    saveTreeViewPanelToHistory = => @history.save(treeViewPanel)

    @subscriptions.add atom.workspace.panelContainers.left.onDidAddPanel ({panel}) ->
      item = panel.getItem()
      if item.constructor.name is 'TreeView'
        treeViewPanel = panel
        if typeof(item.list.addEventListener) is 'function'
          treeViewListElement = item.list
        else
          treeViewListElement = item.list[0]
        treeViewListElement.addEventListener('focus', saveTreeViewPanelToHistory, false)

    removeListnerFromTreeViewListElement = ->
      treeViewListElement?.removeEventListener('focus', saveTreeViewPanelToHistory, false)

    @subscriptions.add atom.workspace.panelContainers.left.onDidRemovePanel ({panel}) ->
      if panel is treeViewPanel
        removeListnerFromTreeViewListElement()

    @subscriptions.add new Disposable ->
      removeListnerFromTreeViewListElement()

  deactivate: ->
    @subscriptions?.dispose()
    @choosePane = null
    {@subscriptions, @history} = {}
