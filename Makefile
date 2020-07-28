# kind-voltha testing Makefile
#
# SPDX-FileCopyrightText: © 2020 Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

SHELL = bash -eu -o pipefail

.DEFAULT_GOAL := help
.PHONY: test shellcheck yamllint lint-json help

test: shellcheck lint-json yamllint ## run all tests

SHELL_FILES := voltha
shellcheck: ## check shell scripts with shellcheck
	shellcheck --version
	shellcheck $(SHELL_FILES)

YAML_FILES ?= $(shell find . -type f \( -name '*.yaml' -o -name '*.yml' \) -print )
yamllint: ## lint check YAML files with yamllint
	yamllint --version
	yamllint \
    -d "{extends: default, rules: {line-length: {max: 99}}}" \
    -s $(YAML_FILES)

JSON_FILES ?= $(shell find . -type f -name '*.json' -print )
lint-json: ## lint check JSON files by loading them with python
	for jsonfile in $(JSON_FILES); do \
		echo "Validating json file: $$jsonfile" ;\
		python -m json.tool $$jsonfile > /dev/null ;\
	done

help: ## Print help for each Makefile target
	@echo kind-voltha Makefile targets
	@echo
	@grep '^[[:alnum:]_-]*:.* ##' $(MAKEFILE_LIST) \
    | sort | awk 'BEGIN {FS=":.* ## "}; {printf "%-25s %s\n", $$1, $$2};'
