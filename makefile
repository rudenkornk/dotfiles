SHELL = /usr/bin/env bash

PROJECT_NAME := dotfiles
BUILD_DIR ?= build
PROJECTS_PATH != echo /home/$$USER/projects

CONFIG_DIRS := \
               common_utils \
               python \
               nodejs \
               bash \
               docker \
               git \
               latexindent \
               powershell \
               tmux \
               vim \
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

.PHONY: explicit_target
explicit_target:
	echo "Please specify target explicitly"

.PHONY: user_config
user_config: $(BUILD_DIR)/user_config

.PHONY: system_config
system_config: $(BUILD_DIR)/system_config

.PHONY: config
config: system_config user_config

.PHONY: gui_config
gui_config: $(BUILD_DIR)/gui_config

.PHONY: checkout_projects
checkout_projects: $(BUILD_DIR)/checkout_projects

$(BUILD_DIR)/system_config: $(CONFIG_DEPS)
	for i in $(CONFIG_DIRS); do \
		if [ -f "$$i/system.sh" ]; then \
			sudo \
			PRIMARY_USER=$$USER \
			$$i/system.sh; \
		fi; \
	done
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/user_config: $(CONFIG_DEPS)
	for i in $(CONFIG_DIRS); do \
		if [ -f "$$i/user.sh" ]; then \
			$$i/user.sh; \
		fi; \
	done
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/gui_config: $(GUI_CONFIG_DEPS)
	for i in $(GUI_CONFIG_DIRS); do \
		if [ -f "$$i/system.sh" ]; then \
			sudo \
			PRIMARY_USER=$$USER \
			$$i/system.sh; \
		fi; \
		if [ -f "$$i/user.sh" ]; then \
			$$i/user.sh; \
		fi; \
	done
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/checkout_projects: scripts/checkout_projects.sh
	PROJECTS_PATH=$(PROJECTS_PATH) \
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

IF_DOCKERD_UP := command -v docker &> /dev/null && pidof dockerd &> /dev/null

DOCKER_CONTAINER_ID != $(IF_DOCKERD_UP) && docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$
DOCKER_CONTAINER_STATE != $(IF_DOCKERD_UP) && docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$
DOCKER_CONTAINER_RUN_STATUS != [[ "$(DOCKER_CONTAINER_STATE)" != "running" ]] && echo "$(DOCKER_CONTAINER)_not_running"
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
ifneq ($(COMMAND),)
	docker exec $(DOCKER_CONTAINER_NAME) bash -c "$(COMMAND)"
else
	docker exec $(DOCKER_CONTAINER_NAME) bash -c "make $(TARGET)"
endif

