SHELL = /usr/bin/env bash

############################# Arguments ############################
HOSTS ?= localhost
REMOTE_USER ?= $(shell id --user --name)
VERIFY_UNCHANGED ?= false
REDUCED_CHECK ?= false


############################## Setup ###############################
ARTIFACTS_DIR := __artifacts__
VENV := source $(ARTIFACTS_DIR)/$(shell hostname)/venv/bin/activate
BOOTSTRAP := $(ARTIFACTS_DIR)/$(shell hostname)/bootstrap_control_node_$(shell id --user --name)


########################### Main targets ###########################
.PHONY: config
config: $(BOOTSTRAP)
	$(VENV) && \
		HOSTS=$(HOSTS) \
		IMAGE=$(IMAGE) \
		REMOTE_USER=$(REMOTE_USER) \
		VERIFY_UNCHANGED=$(VERIFY_UNCHANGED) \
		REDUCED_CHECK=$(REDUCED_CHECK) \
		./config.sh

.PHONY: bootstrap_hosts
bootstrap_hosts: $(BOOTSTRAP)
	$(VENV) && \
		HOSTS=$(HOSTS) \
		IMAGE=$(IMAGE) \
		REMOTE_USER=$(REMOTE_USER) \
		VERIFY_UNCHANGED=$(VERIFY_UNCHANGED) \
		REDUCED_CHECK=$(REDUCED_CHECK) \
		BOOTSTRAP_ONLY=true \
		./config.sh

.PHONY: bootstrap_control_node
bootstrap_control_node: $(BOOTSTRAP)

.PHONY: update
update: $(BOOTSTRAP)
	$(VENV) && ./scripts/main.py update

.PHONY: graph
graph: $(BOOTSTRAP)
	$(VENV) && ./scripts/main.py graph

.PHONY: format
format: $(BOOTSTRAP)
	$(VENV) && python3 -m black .
	$(VENV) && python3 -m isort --gitignore .
	(npm install --save-exact && npx prettier --ignore-path <(cat .gitignore .prettierignore) . -w) || true # ignore if not installed
	stylua . || true # ignore if not installed

.PHONY: hooks
hooks: .git/hooks/pre-commit

.git/hooks/pre-commit:
	ln --symbolic --force ../../scripts/src/data/hooks/pre-commit .git/hooks/pre-commit


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
	$(VENV) && ansible-lint playbook_ansible_collections.yaml
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
check_bootstrap_control_node: $(ARTIFACTS_DIR)/$(CONTAINER)/bootstrap_control_node

$(ARTIFACTS_DIR)/$(CONTAINER)/bootstrap_control_node: $(BOOTSTRAP)
	podman run --rm --interactive --tty \
		--mount=type=bind,source=$$(pwd),target=$$(pwd) \
		--workdir $$(pwd) $(IMAGE) \
		bash -c 'ARTIFACTS_DIR=$(ARTIFACTS_DIR)/$(CONTAINER) ./bootstrap.sh'


###################### Bootstrap control node ######################
$(BOOTSTRAP): \
	bootstrap.sh \
	playbook_ansible_collections.yaml \
	requirements.txt \
	roles/manifest/vars/main.yaml \

	ARTIFACTS_DIR=$(ARTIFACTS_DIR) ./bootstrap.sh
