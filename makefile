SHELL = /usr/bin/env bash

PROJECT_NAME := dotfiles
BUILD_DIR ?= build

CONFIG_DIRS := \
               common_utils \
               go \
               nodejs \
               python \
               ruby \
               clipboard \
               cmd_utils \
               docker \
               fish \
               git \
               latexindent \
               neovim \
               powershell \
               tmux \
               wsl \

GUI_CONFIG_DIRS := \
                   chrome \
                   fonts \
                   keyboard_layouts \
                   mouse \
                   onehalf \
                   telegram \
                   vscode \

CONFIG_DEPS != find $(CONFIG_DIRS) -type f,l
GUI_CONFIG_DEPS != find $(GUI_CONFIG_DIRS) -type f,l

.PHONY: config
config: system_config user_config

.PHONY: user_config
user_config: $(BUILD_DIR)/user_config

.PHONY: system_config
system_config: $(BUILD_DIR)/system_config

.PHONY: gui_config
gui_config: gui_system_config gui_user_config

.PHONY: gui_user_config
gui_user_config: $(BUILD_DIR)/gui_user_config

.PHONY: gui_system_config
gui_system_config: $(BUILD_DIR)/gui_system_config

.PHONY: checkout_projects
checkout_projects: $(BUILD_DIR)/checkout_projects

$(BUILD_DIR)/system_config: $(CONFIG_DEPS)
	for i in $(CONFIG_DIRS); do \
		scripts/caption.sh "CONFIGURING SYSTEM FOR $${i^^}"; \
		if [ -f "$$i/system.sh" ]; then \
			sudo WSL_INTEROP=$$WSL_INTEROP \
			PRIMARY_USER=$$(id --user --name) \
			$$i/system.sh || \
			{ scripts/caption.sh "ERROR CONFIGURING SYSTEM FOR $${i^^}!"; exit 1; }; \
		fi; \
	done
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/user_config: $(CONFIG_DEPS)
	for i in $(CONFIG_DIRS); do \
		scripts/caption.sh "CONFIGURING USER FOR $${i^^}"; \
		if [ -f "$$i/user.sh" ]; then \
			$$i/user.sh || \
			{ scripts/caption.sh "ERROR CONFIGURING USER FOR $${i^^}!"; exit 1; }; \
		fi; \
	done
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/gui_system_config: $(GUI_CONFIG_DEPS)
	for i in $(GUI_CONFIG_DIRS); do \
		scripts/caption.sh "CONFIGURING SYSTEM FOR $${i^^}"; \
		if [ -f "$$i/system.sh" ]; then \
			sudo WSL_INTEROP=$$WSL_INTEROP \
			PRIMARY_USER=$$(id --user --name) \
			$$i/system.sh || \
			{ scripts/caption.sh "ERROR CONFIGURING SYSTEM FOR $${i^^}!"; exit 1; }; \
		fi; \
	done
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/gui_user_config: $(GUI_CONFIG_DEPS)
	for i in $(GUI_CONFIG_DIRS); do \
		scripts/caption.sh "CONFIGURING USER FOR $${i^^}"; \
		if [ -f "$$i/user.sh" ]; then \
			$$i/user.sh || \
			{ scripts/caption.sh "ERROR CONFIGURING USER FOR $${i^^}!"; exit 1; }; \
		fi; \
	done
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/checkout_projects: scripts/checkout_projects.sh
	./scripts/checkout_projects.sh
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: check
check: config

.PHONY: clean
clean:


###################### docker support ######################
TARGET ?= config
COMMAND ?=
DOCKER_KEEP_CI_USER_SUDO := true
DOCKER_IMAGE_TAG := rudenkornk/docker_ci:1.0.0
DOCKER_CONTAINER_NAME := $(PROJECT_NAME)_container
DOCKER_CONTAINER := $(BUILD_DIR)/$(DOCKER_CONTAINER_NAME)
DOCKER_COMMAND != [[ ! -z "$(COMMAND)" ]] && echo "$(COMMAND)" || echo "make $(TARGET)"

IF_DOCKERD_UP := command -v docker &> /dev/null && pidof dockerd &> /dev/null

DOCKER_CONTAINER_ID != $(IF_DOCKERD_UP) && docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$
DOCKER_CONTAINER_STATE != $(IF_DOCKERD_UP) && docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$
DOCKER_CONTAINER_RUN_STATUS != [[ "$(DOCKER_CONTAINER_STATE)" != "running" ]] && echo "$(DOCKER_CONTAINER)_not_running"
WSL_MOUNT != [[ -S $$WSL_INTEROP ]] && echo "--mount type=bind,source=$$WSL_INTEROP,target=$$WSL_INTEROP"

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
		$(WSL_MOUNT) \
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

