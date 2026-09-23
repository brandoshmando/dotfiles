;; hx-claude-ide — Claude Code editor awareness.
;; Loads the native dylib (installed at STEEL_HOME/native/libclaude_ide.dylib),
;; which registers the selection / document-open hooks and provides the
;; lifecycle fns. Then start the WebSocket + lockfile server so `claude` can
;; attach via `/ide`.
;; This requires the forge-installed cog at $STEEL_HOME/cogs/claude-ide, which
;; is a frozen clone. To hack on the plugin, point the require at mod.scm in
;; your working checkout instead so edits take effect on restart.
(require "claude-ide/mod.scm")
(claude-ide/start)
(require "steel-pty/term.scm")
