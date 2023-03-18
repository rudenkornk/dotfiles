SHELL = /usr/bin/env bash

############################# Arguments ############################
GPG ?=
HOSTS ?= localhost
USER ?= $(shell id --user --name)


############################## Setup ###############################
# DO NOT MANUALLY CHANGE BUILD_DIR
# This parameter is used for in-container checks
BUILD_DIR ?= __build__
VENV := source $(BUILD_DIR)/venv/bin/activate


########################### Main targets ###########################
.PHONY: config
config: $(BUILD_DIR)/bootstrap_control_node
	if [[ "$(HOSTS)" =~ "localhost" || "$(HOSTS)" =~ "127.0.0.1" ]]; then \
		# Before we set up a new password, we need to ask user for the existing one \
		sudo bash -c ''; \
	fi
	if [[ "$(HOSTS)" =~ ^dotfiles_ ]]; then \
		$(VENV) && ansible-playbook --extra-vars "ubuntu_tag=$(UBUNTU_TAG)" \
			--inventory inventory.yaml playbook_dotfiles_container.yaml; \
	fi
	$(VENV) && ansible-playbook --extra-vars "__hosts__=$(HOSTS)         user=$(USER)" \
		--inventory inventory.yaml playbook_bootstrap_hosts.yaml
	$(VENV) && ansible-playbook --extra-vars "__hosts__=$(HOSTS) ansible_user=$(USER)" \
		--extra-vars "gpg_key=$(GPG)" \
		--inventory inventory.yaml playbook.yaml

.PHONY: update
update: $(BUILD_DIR)/bootstrap_control_node
	$(VENV) && ./support.py update

.PHONY: graph
graph: $(BUILD_DIR)/bootstrap_control_node
	$(VENV) && ./support.py graph

.PHONY: format
format: $(BUILD_DIR)/bootstrap_control_node
	$(VENV) && python3 -m black .
	$(VENV) && python3 -m isort --gitignore .


############################## Checks ##############################
UBUNTU_TAG ?= 22.04

.PHONY: check
check: \
	check_bootstrap_control_node \
	check_host \
	lint \

.PHONY: lint
lint: $(BUILD_DIR)/bootstrap_control_node
	$(VENV) && ansible-lint playbook.yaml
	$(VENV) && ansible-lint playbook_bootstrap_control_node.yaml
	$(VENV) && ansible-lint playbook_bootstrap_hosts.yaml
	$(VENV) && ansible-lint playbook_dotfiles_container.yaml
	$(VENV) && python3 -m mypy .
	$(VENV) && python3 -m pylint --jobs 0 .
	$(VENV) && python3 -m black --diff --check .
	$(VENV) && python3 -m isort --gitignore --diff --check .
	$(VENV) && python3 -m yamllint --strict .github
	
	dirs=($$(ls roles)); \
	roles=($$(grep --perl-regex --only-matching "\- role\: \K\w+" playbook.yaml | sort)); \
	for i in $$(seq 1 $$(($${#dirs[@]} - 1))); do \
		if [[ "$${dirs[$$i]}" != "$${roles[$$i]}" ]]; then \
			echo "playbook.yaml is missing \"$${dirs[$$i]}\" role"; \
			exit 1; \
		fi; \
	done
	
	if (git log --name-only --oneline | grep --quiet --perl-regex "(rsa|ovpn|auth)\$$"); then \
		echo "Looks like rsa key, ovpn config or auth data leaked!!!"; \
		exit 1; \
	fi

.PHONY: check_host
check_host: $(BUILD_DIR)/bootstrap_control_node
	make HOSTS=dotfiles_$(UBUNTU_TAG) config

.PHONY: check_bootstrap_control_node
check_bootstrap_control_node: $(BUILD_DIR)/$(UBUNTU_TAG)/bootstrap_control_node

$(BUILD_DIR)/$(UBUNTU_TAG)/bootstrap_control_node: $(BUILD_DIR)/bootstrap_control_node
	podman run --rm --interactive --tty \
		--mount=type=bind,source=$$(pwd),target=$$(pwd) \
		--workdir $$(pwd) ubuntu:$(UBUNTU_TAG) bash -c \
			' \
			apt-get update && apt-get install make --yes --no-install-recommends && \
			make BUILD_DIR=$(BUILD_DIR)/$(UBUNTU_TAG) $(BUILD_DIR)/$(UBUNTU_TAG)/bootstrap_control_node \
			'


###################### Bootstrap control node ######################
.PHONY: $(BUILD_DIR)/not_ready

$(BUILD_DIR)/bootstrap_control_node: $(BUILD_DIR)/ansible playbook_bootstrap_control_node.yaml roles/manifest/vars/main.yaml
	sudo bash -c ''
	$(VENV) && ansible-playbook --inventory inventory.yaml playbook_bootstrap_control_node.yaml
	mkdir --parents $(BUILD_DIR) && touch $@

ANSIBLE_INSTALLED != ($(VENV) &> /dev/null && command -v ansible &> /dev/null) || echo "$(BUILD_DIR)/not_ready"
$(BUILD_DIR)/ansible: $(BUILD_DIR)/venv requirements.txt $(ANSIBLE_INSTALLED)
	$(VENV) && pip3 install -r requirements.txt
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/venv: $(BUILD_DIR)/python
	python3 -m venv $(BUILD_DIR)/venv

PYTHON_INSTALLED != (command -v python3 &> /dev/null && command -v pip3 &> /dev/null) || echo "$(BUILD_DIR)/not_ready"
$(BUILD_DIR)/python: $(BUILD_DIR)/sudo $(PYTHON_INSTALLED)
	if [[ -n "$(PYTHON_INSTALLED)" ]]; then \
		sudo apt-get update && \
		DEBIAN_FRONTEND=noninteractive sudo apt-get install --yes --no-install-recommends \
			python3-venv \
			python3-pip \
			; \
	fi
	mkdir --parents $(BUILD_DIR) && touch $@

SUDO_INSTALLED != command -v sudo &> /dev/null || echo "$(BUILD_DIR)/not_ready"
$(BUILD_DIR)/sudo: $(SUDO_INSTALLED)
	if [[ -n "$(SUDO_INSTALLED)" ]]; then \
		apt-get update && \
		DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
			sudo; \
	fi
	mkdir --parents $(BUILD_DIR) && touch $@
