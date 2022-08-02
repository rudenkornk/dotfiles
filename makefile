SHELL = /usr/bin/env bash

PROJECT_NAME := dotfiles
BUILD_DIR ?= build

# It is implicitly implied that all user configs depend on all system configs
# The reason for not to set this explicitly is to be able to run user configs separately from system config
# This is helpful on systems, managed by third-party system administrator
.PHONY: config
config: config_system config_user

.PHONY: config_gui
config_gui: config_system config_gui_system config_gui_user

.PHONY: config_system
config_system: \
	clipboard_system \
	cmd_utils_system \
	common_utils_system \
	docker_system \
	fish_system \
	git_system \
	lua_system \
	neovim_system \
	powershell_system \
	python_system \
	ruby_system \
	ssh_system \
	system_utils_system \
	wsl_system \

.PHONY: config_user
config_user: \
	cmd_utils_user \
	docker_user \
	fish_user \
	git_user \
	go_user \
	latexindent_user \
	lua_user \
	neovim_user \
	nodejs_user \
	python_user \
	rust_user \
	ssh_user \
	tmux_user \

.PHONY: config_gui_system
config_gui_system: \
	chrome_system \
	keyboard_layouts_system \
	telegram_system \
	vscode_system \

.PHONY: config_gui_user
config_gui_user: \
	fonts_user \
	mouse_user \

.PHONY: checkout_projects
checkout_projects: $(BUILD_DIR)/checkout_projects

.PHONY: clipboard_system
clipboard_system: common_utils_system
	sudo scripts/config_system.sh clipboard

.PHONY: cmd_utils_system
cmd_utils_system: common_utils_system
	sudo scripts/config_system.sh cmd_utils

.PHONY: common_utils_system
common_utils_system:
	sudo scripts/config_system.sh common_utils

.PHONY: docker_system
docker_system: common_utils_system
	sudo scripts/config_system.sh docker

.PHONY: fish_system
fish_system: common_utils_system ssh_system
	sudo scripts/config_system.sh fish

.PHONY: git_system
git_system:
	sudo scripts/config_system.sh git

.PHONY: lua_system
lua_system: common_utils_system
	sudo scripts/config_system.sh lua

.PHONY: neovim_system
neovim_system: common_utils_system ruby_system
	sudo scripts/config_system.sh neovim

.PHONY: powershell_system
powershell_system: common_utils_system
	sudo scripts/config_system.sh powershell

.PHONY: python_system
python_system:
	sudo scripts/config_system.sh python

.PHONY: ruby_system
ruby_system:
	sudo scripts/config_system.sh ruby

.PHONY: ssh_system
ssh_system:
	sudo scripts/config_system.sh ssh

.PHONY: system_utils_system
system_utils_system:
	sudo scripts/config_system.sh system_utils

.PHONY: wsl_system
wsl_system:
	sudo scripts/config_system.sh wsl

.PHONY: chrome_system
chrome_system: common_utils_system
	sudo scripts/config_system.sh chrome

.PHONY: keyboard_layouts_system
keyboard_layouts_system:
	sudo scripts/config_system.sh keyboard_layouts

.PHONY: telegram_system
telegram_system: common_utils_system
	sudo scripts/config_system.sh telegram

.PHONY: vscode_system
vscode_system: common_utils_system
	sudo scripts/config_system.sh vscode

.PHONY: cmd_utils_user
cmd_utils_user:
	scripts/config_user.sh cmd_utils

.PHONY: docker_user
docker_user:
	scripts/config_user.sh docker

.PHONY: fish_user
fish_user:
	scripts/config_user.sh fish

.PHONY: git_user
git_user: nodejs_user
	scripts/config_user.sh git

.PHONY: go_user
go_user:
	scripts/config_user.sh go

.PHONY: latexindent_user
latexindent_user:
	scripts/config_user.sh latexindent

.PHONY: lua_user
lua_user:
	scripts/config_user.sh lua

.PHONY: neovim_user
neovim_user: python_user nodejs_user go_user rust_user
	scripts/config_user.sh neovim

.PHONY: nodejs_user
nodejs_user:
	scripts/config_user.sh nodejs

.PHONY: python_user
python_user:
	scripts/config_user.sh python

.PHONY: rust_user
rust_user:
	scripts/config_user.sh rust

.PHONY: ssh_user
ssh_user:
	scripts/config_user.sh ssh

.PHONY: tmux_user
tmux_user: python_user
	scripts/config_user.sh tmux

.PHONY: fonts_user
fonts_user:
	scripts/config_user.sh fonts

.PHONY: mouse_user
mouse_user:
	scripts/config_user.sh mouse

$(BUILD_DIR)/checkout_projects: scripts/checkout_projects.sh
	./scripts/checkout_projects.sh
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: check
check: \
	check_git_status \

.PHONY: check_git_status
check_git_status:
	[[ -z $$(git status --porcelain) ]] || exit 1


.PHONY: clean
clean:


###################### docker support ######################
TARGET ?= config
COMMAND ?=
DOCKER_KEEP_CI_USER_SUDO := true
DOCKER_IMAGE_TAG := rudenkornk/docker_ci:1.1.0
DOCKER_CONTAINER_NAME := $(PROJECT_NAME)_container
DOCKER_CONTAINER := $(BUILD_DIR)/$(DOCKER_CONTAINER_NAME)
DOCKER_COMMAND != [[ ! -z "$(COMMAND)" ]] && echo "$(COMMAND)" || echo "make $(TARGET)"

IF_DOCKERD_UP := command -v docker &> /dev/null && pidof dockerd &> /dev/null

DOCKER_CONTAINER_ID != $(IF_DOCKERD_UP) && docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$
DOCKER_CONTAINER_STATE != $(IF_DOCKERD_UP) && docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$
DOCKER_CONTAINER_RUN_STATUS != [[ "$(DOCKER_CONTAINER_STATE)" != "running" ]] && echo "$(DOCKER_CONTAINER)_not_running"
WSL_ARGS != [[ -S $$WSL_INTEROP ]] && echo "--mount type=bind,source=$$WSL_INTEROP,target=$$WSL_INTEROP --env WSL_INTEROP=$$WSL_INTEROP"

.PHONY: $(DOCKER_CONTAINER)_not_running
$(DOCKER_CONTAINER): $(DOCKER_CONTAINER_RUN_STATUS)
ifneq ($(DOCKER_CONTAINER_ID),)
	docker container rename $(DOCKER_CONTAINER_NAME) $(DOCKER_CONTAINER_NAME)_$(DOCKER_CONTAINER_ID)
endif
	docker run --interactive --tty --detach \
		--user ci_user \
		--env BUILD_DIR="$(BUILD_DIR)" \
		--env KEEP_CI_USER_SUDO="$(DOCKER_KEEP_CI_USER_SUDO)" \
		--env CI_UID="$$(id --user)" --env CI_GID="$$(id --group)" \
		--env "TERM=xterm-256color" \
		--name $(DOCKER_CONTAINER_NAME) \
		--mount type=bind,source="$$(pwd)",target=/home/repo \
		$(WSL_ARGS) \
		$(DOCKER_IMAGE_TAG)
	sleep 1
	mkdir --parents $(BUILD_DIR) && touch $@

$(DOCKER_CONTAINER)_prepare: $(DOCKER_CONTAINER)
	docker exec $(DOCKER_CONTAINER_NAME) bash -c \
		" \
		sudo apt-get update && \
		sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
			make \
		"
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: container
container: $(DOCKER_CONTAINER)_prepare

.PHONY: in_docker
in_docker: $(DOCKER_CONTAINER)_prepare
	docker exec $(DOCKER_CONTAINER_NAME) bash -c "$(DOCKER_COMMAND)"

