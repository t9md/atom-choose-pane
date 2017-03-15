# 0.6.2:
- Fix: No longer throw exception when deactivated( manually or restart Atom ) without opening tree-view.
  - The error was happened by trying to removeEventListener for the non existing treeViewListElement.

# 0.6.1:
- Fix: Now no longer throw exception in Atom v1.16.0-beta0 and above.

# 0.6.0:
- New: Command to activate next/previous tab( pane-item ) while choosing.
  - Following keymap is available while label are shown.
    - `[`: `choose-pane:previous-item`
    - `]`: `choose-pane:next-item`
- Improve: #4 label character centered using flexbox by @andyngo
- Doc: Add label style example to README.md suggested by @andyngo in #4.
- Doc: Update gif and add overview gif to README.md.

# 0.5.1:
- Fix: Uncaught TypeError: this.resolve is not a function which is triggerd `core:confirm` of command-palette #1

# 0.5.0:
- Improve the way to detect last-focused element.
- Introduce new `choose-pane:focus-last-focused`: focus last-focused without showing label.

# 0.4.0:
- Differentiate last-focused element(pane or panel)

# 0.3.0:
- Differentiate active element(pane or panel)

# 0.2.1:
- Add spec

# 0.2.0:
- Can back to last-focused element by `choose-pane:last-focused`. This new command is aailable only on choose-pane-editor.

# 0.1.2:
- Dynamically choose color for label based on syntax background.

# 0.1.0:
- Initial release
