SHELL := /bin/zsh
DOTFILES := $(CURDIR)
VSCODE_DIR := $(HOME)/Library/Application Support/Code/User
LOCAL_BIN := $(HOME)/.local/bin

# Steel-enabled helix (mattwparas fork) — built from source, not a formula.
HELIX_SRC := $(HOME)/code/rust/helix
HELIX_FORK := https://github.com/mattwparas/helix.git
HELIX_UPSTREAM := https://github.com/helix-editor/helix.git
HELIX_BRANCH := steel-event-system
HELIX_CONFIG_DIR := $(HOME)/.config/helix
STEEL_REPO := https://github.com/mattwparas/steel.git

# Prefer the rustup toolchain if present — the helix fork pins a channel in
# rust-toolchain.toml, which the Homebrew cargo ignores.
CARGO := $(shell test -x $(HOME)/.cargo/bin/cargo && echo $(HOME)/.cargo/bin/cargo || echo cargo)
FORGE := $(HOME)/.cargo/bin/forge

.PHONY: install brew gvm omz zsh ghostty vscode fonts helix hx-steel helix-src steel-toolchain helix-build helix-cogs

install: brew gvm omz zsh ghostty vscode fonts helix

brew:
	brew bundle --file=$(DOTFILES)/Brewfile

gvm:
	@if [ ! -d "$(HOME)/.gvm" ]; then \
		echo "Installing gvm..."; \
		curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | zsh; \
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
	@$(call backup_and_link,$(DOTFILES)/vscode/settings.json,$(VSCODE_DIR)/settings.json)
	@$(call backup_and_link,$(DOTFILES)/vscode/keybindings.json,$(VSCODE_DIR)/keybindings.json)

fonts:
	cp -n $(DOTFILES)/fonts/*.ttf $(HOME)/Library/Fonts/ || true

# Links config + the `hx-steel` wrapper. Cheap, so it runs as part of `install`.
# The editor itself is built by `make hx-steel`.
helix:
	mkdir -p $(HELIX_CONFIG_DIR) $(LOCAL_BIN)
	@$(call backup_and_link,$(DOTFILES)/helix/config.toml,$(HELIX_CONFIG_DIR)/config.toml)
	@$(call backup_and_link,$(DOTFILES)/helix/init.scm,$(HELIX_CONFIG_DIR)/init.scm)
	@$(call backup_and_link,$(DOTFILES)/helix/helix.scm,$(HELIX_CONFIG_DIR)/helix.scm)
	@$(call backup_and_link,$(DOTFILES)/helix/bin/hx-steel,$(LOCAL_BIN)/hx-steel)

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
	$(CARGO) install --git $(STEEL_REPO) --rev "$$rev" \
		steel-interpreter cargo-steel-lib steel-forge steel-language-server

helix-build: helix-src
	cd $(HELIX_SRC) && $(CARGO) install --path helix-term --locked

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
	ln -sf "$(1)" "$(2)"
endef
