# choose-pane

choose pane by label.

![](https://raw.githubusercontent.com/t9md/t9md/5ca8d2ad710ce24e1ecbc3777b5bf03432dc3ef9/img/atom-choose-pane.gif)

# How to start

1. Configure keymap in your `keymap.cson`. (no default keymap)
2. Invoke `choose-pane:start` from that keymap.
3. Label is shown on panels and panes
4. Choose label where you want to focus

# Style customization

You can customize label style in `style.less`.

```less
.choose-pane {
  color: red;
}
```

# Keymap example

- for normal user

```coffeescript
'atom-workspace:not([mini])':
  'ctrl-;': 'choose-pane:start'
```

- Mine(I'm vim-mode-plus user)

```coffeescript
'atom-text-editor.vim-mode-plus:not(.insert-mode)':
  '-': 'choose-pane:start'

# For tree-view
'.tree-view':
  '-': 'choose-pane:start'
```

# Label customization

From setting view, change `labelChars`.  
**Label is always matched case insensitively**.
