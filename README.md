# choose-pane [![Build Status](https://travis-ci.org/t9md/atom-choose-pane.svg?branch=master)](https://travis-ci.org/t9md/atom-choose-pane)

choose pane by label.

![](https://raw.githubusercontent.com/t9md/t9md/0331a56774cd283aab2548708d740cd0f9f8e59c/img/atom-choose-pane.gif)

# How to start

1. Configure keymap in your `keymap.cson`. (no default keymap)
2. Invoke `choose-pane:start` from that keymap.
3. Label is shown on panels and panes
4. Choose label where you want to focus

[NOTE]:
- Current active pane is highlighted by different color.
- You can quickly back to last-focused pane by `choose-pane:last-focused` in choosing mode. This last-focused pane denoted by underlined label.

# Commands

### scope: `atom-workspace`
- `choose-pane:start`: Start label choosing.
- `choose-pane:focus-last-focused`: Focus last focused pane or panel without showing label.

### scope: `atom-text-editor#choose-pane-editor`
- `choose-pane:last-focused`: Choose last-focused(underlined) label.

# Style customization

You can customize label style in `style.less`.

```less
.choose-pane {
  color: white;
  &.active {
    color: green;
  }
  &.last-focused {
    text-decoration: line-through;
  }
}
```

# Keymap example

- for normal user

```coffeescript
'atom-workspace:not([mini])':
  'ctrl-;': 'choose-pane:start'
  'cmd-k ;': 'choose-pane:focus-last-focused'

# Back to last focused.
'atom-text-editor#choose-pane-editor':
  'ctrl-;': 'choose-pane:last-focused'
```

- Mine(I'm vim-mode-plus user)

```coffeescript
'atom-text-editor.vim-mode-plus:not(.insert-mode)':
  '-': 'choose-pane:start'
  'm m': 'choose-pane:focus-last-focused'

'.markdown-preview':
  '-': 'choose-pane:start'
  'm m': 'choose-pane:focus-last-focused'

# For tree-view
'.tree-view':
  '-': 'choose-pane:start'
  'm m': 'choose-pane:focus-last-focused'

# Map '-', so that I can focus last-focused element by typing `-` twice.
'atom-text-editor#choose-pane-editor':
  '-': 'choose-pane:last-focused'
```

# Label customization

From setting view, change `labelChars`.  
**Label is always matched case insensitively**.
