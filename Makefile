SHELL := /bin/zsh
DOTFILES := $(CURDIR)

# Everything here installs into $HOME, and Homebrew refuses to run as root, so
# `sudo make install` fails. Run as your normal user: the Homebrew installer
# asks for a sudo password itself when it needs to create /opt/homebrew.
ifeq ($(shell id -u),0)
$(error Do not run make as root. Run `make install` as your normal user; Homebrew will ask for your sudo password when it needs it)
endif

VSCODE_DIR := $(HOME)/Library/Application Support/Code/User
LOCAL_BIN := $(HOME)/.local/bin

# Steel-enabled helix (mattwparas fork) — built from source, not a formula.
HELIX_SRC := $(HOME)/code/rust/helix
HELIX_FORK := https://github.com/mattwparas/helix.git
HELIX_UPSTREAM := https://github.com/helix-editor/helix.git
HELIX_BRANCH := steel-event-system
HELIX_CONFIG_DIR := $(HOME)/.config/helix
STEEL_REPO := https://github.com/mattwparas/steel.git

# Homebrew isn't on PATH until its shellenv runs, and on a fresh machine it
# doesn't exist at all when make starts — so resolve it per recipe rather than
# once at parse time.
FIND_BREW = brew_bin=$$(command -v brew 2>/dev/null); \
	[ -n "$$brew_bin" ] || for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do \
		[ -x "$$p" ] && brew_bin="$$p" && break; \
	done

# Same bootstrap problem as brew: on a fresh machine cargo is installed partway
# through the run, so resolve it per recipe. Prefer the rustup toolchain — the
# helix fork pins a channel in rust-toolchain.toml, which the Homebrew cargo
# ignores.
FIND_CARGO = cargo_bin=""; \
	for p in $(HOME)/.cargo/bin/cargo /opt/homebrew/bin/cargo /usr/local/bin/cargo; do \
		[ -x "$$p" ] && cargo_bin="$$p" && break; \
	done; \
	[ -n "$$cargo_bin" ] || cargo_bin=$$(command -v cargo 2>/dev/null); \
	[ -n "$$cargo_bin" ] || { echo "cargo not found — is rust installed?"; exit 1; }

# cargo install always writes binaries to ~/.cargo/bin, whichever cargo is used.
FORGE := $(HOME)/.cargo/bin/forge

.PHONY: install homebrew brew gvm omz zsh ghostty vscode fonts helix hx-steel helix-src steel-toolchain helix-build helix-cogs

install: homebrew brew gvm omz zsh ghostty vscode fonts hx-steel

homebrew:
	@$(FIND_BREW); \
	if [ -z "$$brew_bin" ]; then \
		echo "Installing Homebrew (interactive: it will prompt for your sudo password)..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	else \
		echo "Homebrew already installed ($$brew_bin), skipping."; \
	fi

# Homebrew won't load formulae from third-party taps until they're trusted, and
# `brew bundle` can't do it itself — so record the trust decision here.
TRUSTED_FORMULAE := neurosnap/tap/zmx

brew: homebrew
	@$(FIND_BREW); \
	if [ -z "$$brew_bin" ]; then echo "Homebrew not found after install"; exit 1; fi; \
	eval "$$("$$brew_bin" shellenv)"; \
	brew trust --formula $(TRUSTED_FORMULAE); \
	brew bundle --file=$(DOTFILES)/Brewfile

# The installer is a bash script; piping it to zsh breaks on `==` (zsh expands
# `=word` and reports "= not found"). GVM_NO_UPDATE_PROFILE keeps it from
# appending to ~/.zshrc — zsh/zshrc already sources gvm.
gvm:
	@if [ ! -d "$(HOME)/.gvm" ]; then \
		echo "Installing gvm..."; \
		curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | GVM_NO_UPDATE_PROFILE=1 bash; \
		[ -s "$(HOME)/.gvm/scripts/gvm" ] || { echo "gvm install failed"; exit 1; }; \
	else \
		echo "gvm already installed, skipping."; \
	fi

omz:
	@if [ ! -d "$(HOME)/.oh-my-zsh" ]; then \
		echo "Installing oh-my-zsh..."; \
		ZSH= KEEP_ZSHRC=yes sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; \
	else \
		echo "oh-my-zsh already installed, skipping."; \
	fi

# Runs after gvm/omz in `install`: both append to a real ~/.zshrc, and doing that
# to a symlink would dirty the repo. zshrc already carries the lines they'd add.
zsh: omz
	@if [ ! -f "$(HOME)/.zshrc.local" ]; then \
		echo "Creating $(HOME)/.zshrc.local"; \
		printf '%s\n' \
			'# Machine-local zsh config, sourced at the end of ~/.zshrc.' \
			'#' \
			'# Not tracked by the dotfiles repo. Put anything here that should not be' \
			'# committed or shared across machines:' \
			'#' \
			'#   - Secrets. API keys and tokens, never zsh/zshrc — that repo is public.' \
			'#     Prefer plain assignment over `export` unless a child process actually' \
			'#     needs the value, so it stays out of `env`.' \
			'#' \
			'#   - Installer-generated blocks with absolute paths (conda, nvm, oMLX, ...).' \
			'#     Those installers append to ~/.zshrc, which is a symlink into the repo,' \
			'#     so move their blocks down here instead.' \
			> "$(HOME)/.zshrc.local"; \
		chmod 600 "$(HOME)/.zshrc.local"; \
	fi
	@$(call backup_and_link,$(DOTFILES)/zsh/zshrc,$(HOME)/.zshrc)
	@$(call backup_and_link,$(DOTFILES)/zsh/zshenv,$(HOME)/.zshenv)

ghostty:
	mkdir -p $(HOME)/.config/ghostty/themes
	@$(call backup_and_link,$(DOTFILES)/ghostty/config.ghostty,$(HOME)/.config/ghostty/config.ghostty)
	@$(call backup_and_link,$(DOTFILES)/ghostty/themes/Helix Monokai,$(HOME)/.config/ghostty/themes/Helix Monokai)

vscode:
	mkdir -p "$(VSCODE_DIR)"
	@$(call backup_and_link,$(DOTFILES)/vscode/settings.json,$(VSCODE_DIR)/settings.json)
	@$(call backup_and_link,$(DOTFILES)/vscode/keybindings.json,$(VSCODE_DIR)/keybindings.json)

fonts:
	mkdir -p $(HOME)/Library/Fonts
	cp -n $(DOTFILES)/fonts/*.ttf $(HOME)/Library/Fonts/ || true

# Links config + the `hx-steel` wrapper. Cheap, so it runs as part of `install`.
# The editor itself is built by `make hx-steel`.
helix:
	mkdir -p $(HELIX_CONFIG_DIR) $(LOCAL_BIN)
	@$(call backup_and_link,$(DOTFILES)/helix/config.toml,$(HELIX_CONFIG_DIR)/config.toml)
	@$(call backup_and_link,$(DOTFILES)/helix/init.scm,$(HELIX_CONFIG_DIR)/init.scm)
	@$(call backup_and_link,$(DOTFILES)/helix/helix.scm,$(HELIX_CONFIG_DIR)/helix.scm)
	@$(call backup_and_link,$(DOTFILES)/helix/bin/hx-steel,$(LOCAL_BIN)/hx-steel)
	@[ -x "$(HOME)/.cargo/bin/hx" ] || echo "  note: the editor itself is not built — run 'make hx-steel'"

# Full editor install: source, steel toolchain, the hx binary, and the plugins.
# Compiles a large Rust workspace — expect this to take a while.
hx-steel: helix-src steel-toolchain helix-build helix-cogs helix

helix-src:
	@if [ ! -d "$(HELIX_SRC)/.git" ]; then \
		echo "Cloning $(HELIX_FORK) ($(HELIX_BRANCH)) -> $(HELIX_SRC)"; \
		mkdir -p "$$(dirname $(HELIX_SRC))"; \
		git clone --origin mattwparas --branch $(HELIX_BRANCH) $(HELIX_FORK) "$(HELIX_SRC)"; \
		git -C "$(HELIX_SRC)" remote add origin $(HELIX_UPSTREAM); \
	else \
		echo "$(HELIX_SRC) already cloned, skipping."; \
	fi

# The steel CLI tools must match the steel-core the editor embeds, so take the
# revision straight out of the fork's lockfile rather than pinning it here.
steel-toolchain: helix-src
	@rev=$$(awk '/^name = "steel-core"/{f=1} f && /^source = /{n=split($$0,a,"#"); print substr(a[n],1,length(a[n])-1); exit}' "$(HELIX_SRC)/Cargo.lock"); \
	if [ -z "$$rev" ]; then echo "Could not read steel-core rev from $(HELIX_SRC)/Cargo.lock"; exit 1; fi; \
	echo "Installing steel toolchain at $$rev"; \
	$(FIND_CARGO); \
	"$$cargo_bin" install --git $(STEEL_REPO) --rev "$$rev" \
		steel-interpreter cargo-steel-lib steel-forge steel-language-server

helix-build: helix-src
	@$(FIND_CARGO); \
	cd $(HELIX_SRC) && "$$cargo_bin" install --path helix-term --locked

# Steel packages loaded by init.scm. The `helix` cog is generated by the editor
# itself on first run, so it isn't installed here.
helix-cogs: steel-toolchain
	$(FORGE) pkg install --git https://github.com/brandoshmando/hx-claude-ide.git
	$(FORGE) pkg install --git https://github.com/mattwparas/steel-pty

# Backs up target if it exists and isn't already the correct symlink, then links
define backup_and_link
	if [ -e "$(2)" ] && [ "$$(readlink "$(2)")" != "$(1)" ]; then \
		echo "Backing up $(2) -> $(2).bak"; \
		mv "$(2)" "$(2).bak"; \
	fi; \
	echo "  link $(2)"; \
	ln -sf "$(1)" "$(2)"
endef
