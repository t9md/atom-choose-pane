# choose-pane [![Build Status](https://travis-ci.org/t9md/atom-choose-pane.svg?branch=master)](https://travis-ci.org/t9md/atom-choose-pane)

choose pane by label.

![](https://raw.githubusercontent.com/t9md/t9md/0331a56774cd283aab2548708d740cd0f9f8e59c/img/atom-choose-pane.gif)

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

# Back to last focused.
'atom-text-editor#choose-pane-editor':
  'ctrl-;': 'choose-pane:last-focused'
```

- Mine(I'm vim-mode-plus user)

```coffeescript
'atom-text-editor.vim-mode-plus:not(.insert-mode)':
  '-': 'choose-pane:start'

# For tree-view
'.tree-view':
  '-': 'choose-pane:start'

# Map '-', so that I can focus last-focused element by typing `-` twice.
'atom-text-editor#choose-pane-editor':
  '-': 'choose-pane:last-focused'
```

# Label customization

From setting view, change `labelChars`.  
**Label is always matched case insensitively**.
