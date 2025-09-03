SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help bootstrap install link auth shell-setup

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS=":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Clone/update repo and run full setup
	bash ./setup.sh

install: ## Install CLI packages (macOS Homebrew or Ubuntu apt)
	bash ./install-packages.sh

link: ## Copy dotfiles (helix, starship, shells) into ~/.config and $HOME
	bash ./copy-dotfiles.sh

auth: ## Configure GitHub SSH key and GCP auth if creds exist
	bash ./setup-auth.sh

shell-setup: ## Run optional shell setup via setup.sh (set RUN_SHELL_SETUP=1 inside)
	RUN_SHELL_SETUP=1 bash ./setup.sh

