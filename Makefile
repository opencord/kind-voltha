# kind-voltha testing Makefile
#
# SPDX-FileCopyrightText: © 2020 Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

SHELL = bash -eu -o pipefail

.DEFAULT_GOAL := help
.PHONY: test shellcheck yamllint jsonlint help

test: ## run all tests
	@echo "No tests enabled yet"

SHELL_FILES := voltha $(wildcard releases/*) $(wildcard scripts/*)
shellcheck: ## check shell scripts with shellcheck
	shellcheck --version
	echo shellcheck $(SHELL_FILES)

YAML_FILES ?= $(shell find . -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.cfg' \) -print )
yamllint: ## lint check YAML files with yamllint
	yamllint --version
	yamllint \
    -d "{extends: default, rules: {line-length: {max: 99}}}" \
    -s $(YAML_FILES)

JSON_FILES ?= $(shell find . -type f -name '*.json' -print )
jsonlint: ## lint check JSON files with yamllint
	echo "Not supported yet, would check these files: $(JSON_FILES)"

help: ## Print help for each target
	@echo kind-voltha Makefile targets
	@echo
	@grep '^[[:alpha:]_-]*:.* ##' $(MAKEFILE_LIST) \
    | sort | awk 'BEGIN {FS=":.* ## "}; {printf "%-25s %s\n", $$1, $$2};'
