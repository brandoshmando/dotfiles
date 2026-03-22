SHELL := /bin/zsh
DOTFILES := $(CURDIR)
VSCODE_DIR := $(HOME)/Library/Application Support/Code/User

.PHONY: install brew gvm ghostty vscode fonts

install: brew gvm ghostty vscode fonts

brew:
	brew bundle --file=$(DOTFILES)/Brewfile

gvm:
	@if [ ! -d "$(HOME)/.gvm" ]; then \
		echo "Installing gvm..."; \
		curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | zsh; \
	else \
		echo "gvm already installed, skipping."; \
	fi

ghostty:
	mkdir -p $(HOME)/.config/ghostty
	@$(call backup_and_link,$(DOTFILES)/ghostty/config.ghostty,$(HOME)/.config/ghostty/config.ghostty)

vscode:
	@$(call backup_and_link,$(DOTFILES)/vscode/settings.json,$(VSCODE_DIR)/settings.json)
	@$(call backup_and_link,$(DOTFILES)/vscode/keybindings.json,$(VSCODE_DIR)/keybindings.json)

fonts:
	cp -n $(DOTFILES)/fonts/*.ttf $(HOME)/Library/Fonts/ || true

# Backs up target if it exists and isn't already the correct symlink, then links
define backup_and_link
	if [ -e "$(2)" ] && [ "$$(readlink $(2))" != "$(1)" ]; then \
		echo "Backing up $(2) -> $(2).bak"; \
		mv "$(2)" "$(2).bak"; \
	fi; \
	ln -sf "$(1)" "$(2)"
endef
