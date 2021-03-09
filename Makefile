modules ?= $(shell cd modules && ls -d */ 2>/dev/null | sed s,/,,)
makeable_modules ?= $(shell cd modules && ls -d */Makefile 2>/dev/null | sed s,/Makefile,,)

all: install

build-modules: install-root
	@$(foreach m,$(makeable_modules),make -C modules/$(m)/ build;)

generate:
	@yarn --silent genjs

install: install-root install-modules
install-modules: install-root
	@$(foreach m,$(makeable_modules),make -C modules/$(m)/ install;)
install-root:
	@terraform get

module-build:
	@make -C modules/$(m)/ build
module-install:
	@make -C modules/$(m)/ install
module-test:
	@make -C modules/$(m)/ test

pr:
	@hub pull-request -b $(b)

test-modules: install-root
	@$(foreach m,$(makeable_modules),make -C modules/$(m)/ test;)

.PHONY: all \
		build-modules \
		generate \
		install install-modules install-root \
		module-build module-install module-test \
		pr \
		test-modules