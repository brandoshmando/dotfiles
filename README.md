# dotfiles

Config and install scripts for setting up my environment on a new macOS machine.

```sh
git clone https://github.com/brandoshmando/dotfiles.git ~/code/misc/dotfiles
cd ~/code/misc/dotfiles
make install
```

It works on a bare machine — `homebrew` bootstraps Homebrew if it isn't there
yet, and every target creates the directories it writes into.

**Don't use `sudo`.** Homebrew refuses to install as root, and everything else
here writes into `$HOME`. Run `make install` as yourself; the Homebrew installer
prompts for your sudo password on its own when it needs to create
`/opt/homebrew`. The Makefile aborts if it detects it's running as root.

`make install` is safe to re-run. Every target links rather than copies, so
editing a file in this repo takes effect immediately. If a real file is already
sitting where a symlink should go, it's moved aside to `<name>.bak` first.

## Targets

| Target | What it does |
| --- | --- |
| `install` | `homebrew` + `brew` + `gvm` + `omz` + `zsh` + `ghostty` + `vscode` + `fonts` + `helix`. The default. |
| `homebrew` | Installs Homebrew itself if missing. Prompts for a sudo password; do not run under `sudo`. |
| `brew` | Trusts the third-party formulae, then `brew bundle` against the [Brewfile](Brewfile). |
| `gvm` | Installs [gvm](https://github.com/moovweb/gvm) for Go version management. Skipped if `~/.gvm` exists. |
| `omz` | Installs [oh-my-zsh](https://ohmyz.sh) unattended. Skipped if `~/.oh-my-zsh` exists. |
| `zsh` | Links `.zshrc` / `.zshenv` and creates `~/.zshrc.local` if absent. |
| `ghostty` | Links the Ghostty config and the `Helix Monokai` theme. |
| `vscode` | Links `settings.json` and `keybindings.json`. |
| `fonts` | Copies the Roboto Mono variants into `~/Library/Fonts`. |
| `helix` | Links the Helix config and the `hx-steel` wrapper. |
| `hx-steel` | Builds the Steel-enabled Helix from source. Not part of `install` — see below. |

## Layout

```
zsh/       zshrc, zshenv                  -> ~/.zshrc, ~/.zshenv
ghostty/   config.ghostty + themes/       -> ~/.config/ghostty/
helix/     config.toml, *.scm, bin/       -> ~/.config/helix/, ~/.local/bin/
vscode/    settings, keybindings          -> ~/Library/Application Support/Code/User/
fonts/     Roboto Mono ttfs               -> ~/Library/Fonts/
```

## Shell

`zsh/zshrc` is the tracked shell config: oh-my-zsh bootstrap, toolchain hooks
(Homebrew, gvm, `~/.local/bin` on PATH). Every hook is guarded with an existence
check, so a partial install still leaves you with a working shell.

Two things deliberately stay out of it and live in **`~/.zshrc.local`**, which is
sourced last and is never tracked:

- **Credentials.** This repo is public, so API keys and tokens never go in
  `zsh/zshrc`. Prefer plain assignment over `export` unless a child process
  actually needs the value, so it stays out of `env`.
- **Installer-generated blocks** with absolute paths. Those tools re-append
  their own blocks on a new machine, so tracking them would just produce
  duplicates.

`make zsh` creates `~/.zshrc.local` if it doesn't exist — an empty file with a
comment explaining what belongs in it, mode `600`. Fill it in per machine.

Note the target ordering in `install`: `gvm` and `omz` both append to a real
`~/.zshrc`, so they run *before* `zsh` swaps it for a symlink into this repo.
`zshrc` already carries the lines they would add.

## Helix

The editor is [Helix](https://helix-editor.com) built from
[mattwparas' fork](https://github.com/mattwparas/helix) (`steel-event-system`
branch), which embeds [Steel](https://github.com/mattwparas/steel) as a plugin
runtime. It's a source build, not a formula, so it's kept out of `make install`:

```sh
make hx-steel   # clones, builds, installs plugins. Takes a while.
```

That runs four steps in order:

1. `helix-src` — clones the fork to `~/code/rust/helix` (override with `HELIX_SRC`).
2. `steel-toolchain` — installs `steel`, `forge`, `cargo-steel-lib`, and
   `steel-language-server`. The revision is read out of the fork's `Cargo.lock`
   rather than pinned here, so the CLI tools can't drift from the `steel-core`
   the editor embeds.
3. `helix-build` — `cargo install --path helix-term --locked`, producing
   `~/.cargo/bin/hx`.
4. `helix-cogs` — installs the Steel packages `init.scm` loads, via `forge`:
   [hx-claude-ide](https://github.com/brandoshmando/hx-claude-ide) (makes Claude
   Code aware of the active file and selection) and
   [steel-pty](https://github.com/mattwparas/steel-pty). The `helix` cog isn't
   installed here — the editor generates it itself on first run.

### Why `hx-steel` and not `hx`

`cargo install` puts the binary at `~/.cargo/bin/hx` but leaves the runtime
(grammars, queries, themes) behind in the checkout. `helix/bin/hx-steel` is a
two-line wrapper that points `HELIX_RUNTIME` at it, linked into `~/.local/bin`.
Run `hx-steel`, not `hx`.

### Notes

- Requires a Rust toolchain. The fork pins a channel in `rust-toolchain.toml`,
  which only rustup honors — the Homebrew `cargo` will ignore it and build with
  whatever it ships. The Makefile prefers `~/.cargo/bin/cargo` when present.
- `hx-claude-ide` is macOS/Linux only.
- Config lives in `helix/`: `config.toml` for editor settings, `init.scm` for
  Steel startup, `helix.scm` for user-defined commands.
