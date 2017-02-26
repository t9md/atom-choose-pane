# choose-pane [![Build Status](https://travis-ci.org/t9md/atom-choose-pane.svg?branch=master)](https://travis-ci.org/t9md/atom-choose-pane)

choose pane by label.

![](https://raw.githubusercontent.com/t9md/t9md/ef179f0e078732e9b73ef891bf163252442f1377/img/atom-choose-pane.gif)


overview

![](https://raw.githubusercontent.com/t9md/t9md/ef179f0e078732e9b73ef891bf163252442f1377/img/atom-choose-pane-overview.png)

# How to start

1. Configure keymap in your `keymap.cson`. (no default keymap except `[`, `]` to activate next/previous tab).
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

### example 1: simple demonstration

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

### example 2: dim current pane, weak green highlight for target panes

Based on suggestion by [@andyngo](https://github.com/andyngo).

![](https://raw.githubusercontent.com/t9md/t9md/3bc6ec9e25ec2cf9ecd92b51a5e07f2e1ceebfa1/img/atom-choose-pane-costom-style.png)

```less
.choose-pane {
  background-color: rgba(112, 182, 101, .1);
  &.active {
    background-color: rgba(0, 0, 0, 0.3);
    color: fade(@syntax-text-color, 50);
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
