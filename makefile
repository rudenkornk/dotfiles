SHELL = /usr/bin/env bash

############################# Arguments ############################
HOSTS ?= localhost
USER ?= $(shell id --user --name)


############################## Setup ###############################
# DO NOT MANUALLY CHANGE BUILD_DIR
# This parameter is used for in-container checks
BUILD_DIR ?= __build__
VENV := source $(BUILD_DIR)/venv/bin/activate
BOOTSTRAP := $(BUILD_DIR)/bootstrap_control_node


########################### Main targets ###########################
.PHONY: config
config: $(BOOTSTRAP)
	if [[ "$(HOSTS)" =~ "localhost" || "$(HOSTS)" =~ "127.0.0.1" ]]; then \
		# Before we set up a new password, we need to ask user for the existing one \
		sudo bash -c ''; \
	fi
	if [[ "$(HOSTS)" =~ ^dotfiles_ ]]; then \
		$(VENV) && ansible-playbook --extra-vars "container=$(HOSTS) image=$(IMAGE)" \
			--inventory inventory.yaml playbook_dotfiles_container.yaml; \
	fi
	$(VENV) && ansible-playbook --extra-vars "hosts_var=$(HOSTS)" \
		--inventory inventory.yaml playbook_bootstrap_hosts.yaml
	$(VENV) && ansible-playbook --extra-vars "hosts_var=$(HOSTS)" \
		--extra-vars "user=$(USER)" \
		--inventory inventory.yaml playbook.yaml

.PHONY: update
update: $(BOOTSTRAP)
	$(VENV) && ./scripts/support.py update

.PHONY: graph
graph: $(BOOTSTRAP)
	$(VENV) && ./scripts/support.py graph

.PHONY: format
format: $(BOOTSTRAP)
	$(VENV) && python3 -m black .
	$(VENV) && python3 -m isort --gitignore .
	(npm install --save-exact && npx prettier --ignore-path <(cat .gitignore .prettierignore) . -w) || true # ignore if not installed
	stylua . || true # ignore if not installed

.PHONY: hooks
hooks: .git/hooks/pre-commit

.git/hooks/pre-commit:
	ln --symbolic --force ../../scripts/hooks/pre-commit .git/hooks/pre-commit


############################## Checks ##############################
IMAGE ?= ubuntu:22.04
CONTAINER := dotfiles_$(subst :,_,$(IMAGE))

.PHONY: check
check: \
	check_bootstrap_control_node \
	check_host \
	lint \

.PHONY: lint
lint: $(BOOTSTRAP)
	$(VENV) && ansible-lint playbook.yaml
	$(VENV) && ansible-lint playbook_bootstrap_control_node.yaml
	$(VENV) && ansible-lint playbook_bootstrap_hosts.yaml
	$(VENV) && ansible-lint playbook_dotfiles_container.yaml
	$(VENV) && python3 -m mypy .
	$(VENV) && python3 -m pylint --jobs 0 scripts
	$(VENV) && python3 -m yamllint --strict .github
	
	dirs=($$(ls roles)); \
	roles=($$(grep --perl-regex --only-matching "\- role\: \K\w+" playbook.yaml | sort)); \
	for i in $$(seq 1 $$(($${#dirs[@]} - 1))); do \
		if [[ "$${dirs[$$i]}" != "$${roles[$$i]}" ]]; then \
			echo "playbook.yaml is missing \"$${dirs[$$i]}\" role"; \
			exit 1; \
		fi; \
	done
	
	if (git log --name-only --oneline | grep --quiet --perl-regex "(rsa|ovpn|auth|credentials.json|private.gpg)\$$"); then \
		echo "Looks like rsa key, ovpn config or auth data leaked!!!"; \
		exit 1; \
	fi

.PHONY: check_host
check_host: $(BOOTSTRAP)
	make HOSTS=$(CONTAINER) config

.PHONY: check_bootstrap_control_node
check_bootstrap_control_node: $(BUILD_DIR)/$(CONTAINER)/bootstrap_control_node

$(BUILD_DIR)/$(CONTAINER)/bootstrap_control_node: $(BOOTSTRAP)
	podman run --rm --interactive --tty \
		--mount=type=bind,source=$$(pwd),target=$$(pwd) \
		--workdir $$(pwd) $(IMAGE) \
		bash -c 'BUILD_DIR=$(BUILD_DIR)/$(CONTAINER) ./bootstrap.sh'


###################### Bootstrap control node ######################
$(BOOTSTRAP): \
	bootstrap.sh \
	playbook_bootstrap_control_node.yaml \
	requirements.txt \
	roles/manifest/vars/main.yaml \

	./bootstrap.sh
