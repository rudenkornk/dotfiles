SHELL = /usr/bin/env bash

BUILD_DIR ?= build
BUILD_DIR := $(BUILD_DIR)
BUILD_PATH := $(shell realpath $(BUILD_DIR))
PRIMARY_USER ?= rudenkornk
PRIMARY_USER := $(PRIMARY_USER)
PROJECTS_PATH ?= /home/$(PRIMARY_USER)/projects
PROJECTS_PATH := $(PROJECTS_PATH)
KEEP_CI_USER_SUDO := true
DOCKER_TARGET ?= config
DOCKER_TARGET := $(DOCKER_TARGET)
DOCKER_IMAGE_TAG ?= rudenkornk/docker_ci:1.0.0
DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_TAG)
DOCKER_CONTAINER_NAME ?= docker_ci_container
DOCKER_CONTAINER_NAME := $(DOCKER_CONTAINER_NAME)
DOCKER_CONTAINER := $(BUILD_DIR)/$(DOCKER_CONTAINER_NAME)

CONFIG_SYSTEM_DEPS := scripts/config_system.sh \
                      keyboard_layouts/rnk \
                      keyboard_layouts/evdev.xml \
                      wsl.conf \

CONFIG_USER_DEPS := scripts/config_user.sh \
                    $(shell find vim -type f,l) \
                    bashrc \
                    inputrc \
                    gitconfig \
                    tmux.conf \
                    keyboard_layouts/rnk-russian-qwerty.vim \
                    docker_config.json \


.PHONY: explicit_target
explicit_target:
	echo "Please specify target explicitly"

.PHONY: config
config: config_system config_user

.PHONY: config_system
config_system: $(BUILD_DIR)/config_system

$(BUILD_DIR)/config_system: $(CONFIG_SYSTEM_DEPS)
	sudo \
	BUILD_PATH="$(BUILD_PATH)" \
	PRIMARY_USER=$(PRIMARY_USER) \
	./scripts/config_system.sh
	touch $@

.PHONY: config_user
config_user: $(BUILD_DIR)/config_user

$(BUILD_DIR)/config_user: config_system $(CONFIG_USER_DEPS)
	BUILD_PATH="$(BUILD_PATH)" \
	PRIMARY_USER=$(PRIMARY_USER) \
	./scripts/config_user.sh
	touch $@

.PHONY: checkout_projects
checkout_projects: $(BUILD_DIR)/checkout_projects

$(BUILD_DIR)/checkout_projects: scripts/checkout_projects.sh
	BUILD_PATH="$(BUILD_PATH)" \
	PRIMARY_USER=$(PRIMARY_USER) \
	PROJECTS_PATH=$(PROJECTS_PATH) \
	./scripts/checkout_projects.sh
	touch $@

.PHONY: check
check: config

.PHONY: clean
clean:
	rm --force "$(BUILD_DIR)"/*.zip
	rm --force "$(BUILD_DIR)"/*.gz


###################### docker support ######################
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
		sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
			make \
		"
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: in_docker
in_docker: $(DOCKER_CONTAINER)_prepare
	docker exec $(DOCKER_CONTAINER_NAME) make $(DOCKER_TARGET)

