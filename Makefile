SHELL = /usr/bin/env bash

PROJECT_NAME := dotfiles
BUILD_DIR ?= build
BUILD_DIR := $(BUILD_DIR)
PRIMARY_USER ?= rudenkornk
PRIMARY_USER := $(PRIMARY_USER)
PROJECTS_PATH ?= /home/$(PRIMARY_USER)/projects
PROJECTS_PATH := $(PROJECTS_PATH)

CONFIG_DIRS := \
               common_utils \
               python \
               bash \
               docker \
               fonts \
               git \
               keyboard_layouts \
               latexindent \
               mouse \
               powershell \
               tmux \
               vim \
               wsl \
               xfce4 \

CONFIG_DEPS := $(shell find $(CONFIG_DIRS) -type f,l)

.PHONY: explicit_target
explicit_target:
	echo "Please specify target explicitly"

.PHONY: config
config: $(BUILD_DIR)/config

$(BUILD_DIR)/config: $(CONFIG_DEPS)
	for i in $(CONFIG_DIRS); do \
		if [ -f "$$i/system.sh" ]; then \
			sudo \
			PRIMARY_USER=$(PRIMARY_USER) \
			$$i/system.sh; \
		fi; \
		if [ -f "$$i/user.sh" ]; then \
			$$i/user.sh; \
		fi; \
	done
	touch $@

.PHONY: checkout_projects
checkout_projects: $(BUILD_DIR)/checkout_projects

$(BUILD_DIR)/checkout_projects: scripts/checkout_projects.sh
	PROJECTS_PATH=$(PROJECTS_PATH) \
	./scripts/checkout_projects.sh
	touch $@

.PHONY: check
check: config

.PHONY: clean
clean:


###################### docker support ######################
KEEP_CI_USER_SUDO := true
DOCKER_TARGET ?= config
DOCKER_TARGET := $(DOCKER_TARGET)
DOCKER_IMAGE_TAG ?= rudenkornk/docker_ci:1.0.0
DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_TAG)
DOCKER_CONTAINER_NAME ?= $(PROJECT_NAME)_container
DOCKER_CONTAINER_NAME := $(DOCKER_CONTAINER_NAME)
DOCKER_CONTAINER := $(BUILD_DIR)/$(DOCKER_CONTAINER_NAME)

IF_DOCKERD_UP := command -v docker &> /dev/null && pidof dockerd &> /dev/null

DOCKER_CONTAINER_ID = $(shell $(IF_DOCKERD_UP) && docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_STATE = $(shell $(IF_DOCKERD_UP) && docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_RUN_STATUS = $(shell [[ "$(DOCKER_CONTAINER_STATE)" != "running" ]] && echo "$(DOCKER_CONTAINER)_not_running")
.PHONY: $(DOCKER_CONTAINER)_not_running
$(DOCKER_CONTAINER): $(DOCKER_CONTAINER_RUN_STATUS)
ifneq ($(DOCKER_CONTAINER_ID),)
	docker container rename $(DOCKER_CONTAINER_NAME) $(DOCKER_CONTAINER_NAME)_$(DOCKER_CONTAINER_ID)
endif
	docker run --interactive --tty --detach \
		--user ci_user \
		--env BUILD_DIR="$(BUILD_DIR)" \
		--env PRIMARY_USER="ci_user" \
		--env KEEP_CI_USER_SUDO="$(KEEP_CI_USER_SUDO)" \
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

.PHONY: $(DOCKER_CONTAINER_NAME)
$(DOCKER_CONTAINER_NAME): $(DOCKER_CONTAINER)

.PHONY: in_docker
in_docker: $(DOCKER_CONTAINER)_prepare
	docker exec $(DOCKER_CONTAINER_NAME) make $(DOCKER_TARGET)

