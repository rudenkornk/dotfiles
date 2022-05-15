SHELL = /usr/bin/env bash

PROJECT_NAME := dotfiles
BUILD_DIR ?= build
BUILD_DIR := $(BUILD_DIR)
PRIMARY_USER ?= rudenkornk
PRIMARY_USER := $(PRIMARY_USER)
PROJECTS_PATH ?= /home/$(PRIMARY_USER)/projects
PROJECTS_PATH := $(PROJECTS_PATH)

SYSTEM_CONFIGS_DIRS := \
                       docker \
                       keyboard_layouts \
                       wsl \

USER_CONFIGS_DIRS := \
                     bash \
                     fonts \
                     git \
                     latexindent \
                     mouse \
                     tmux \
                     vim \
                     xfce4 \

CONFIG_SYSTEM_DEPS := $(shell find $(SYSTEM_CONFIGS_DIRS) -type f,l) scripts/config_system.sh
CONFIG_USER_DEPS := $(shell find $(USER_CONFIGS_DIRS) -type f,l)

.PHONY: explicit_target
explicit_target:
	echo "Please specify target explicitly"

.PHONY: config
config: $(BUILD_DIR)/config_system $(BUILD_DIR)/config_user

$(BUILD_DIR)/config_system: $(CONFIG_SYSTEM_DEPS)
	sudo ./scripts/config_system.sh
	for i in $(SYSTEM_CONFIGS_DIRS); do \
		sudo \
		PRIMARY_USER=$(PRIMARY_USER) \
		$$i/config_$$i.sh; \
	done
	touch $@

$(BUILD_DIR)/config_user: $(BUILD_DIR)/config_system $(CONFIG_USER_DEPS)
	for i in $(USER_CONFIGS_DIRS); do \
		PRIMARY_USER=$(PRIMARY_USER) \
		$$i/config_$$i.sh; \
	done
	sudo ./scripts/config_user.sh
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

DOCKER_CONTAINER_ID = $(shell command -v docker &> /dev/null && docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_STATE = $(shell command -v docker &> /dev/null && docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
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

.PHONY: in_docker
in_docker: $(DOCKER_CONTAINER)_prepare
	docker exec $(DOCKER_CONTAINER_NAME) make $(DOCKER_TARGET)

