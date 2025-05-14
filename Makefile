# Makefile for building and running testserver for hugo

SHELL=bash

HUGO_IMAGE="hugomods/hugo:0.145.0"

PORT="8080"
BASEURL="http://localhost:${PORT}/"

NEW_FILENAME=""
NEW_FILEPATH="posts/$(shell date +%Y)/$(shell date +%m)/$(shell date +%d)-${NEW_FILENAME}/index.md"

.PHONY: usage
usage:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  build           - Build the Hugo site"
	@echo "  run             - Run the Hugo server"
	@echo "  shell           - Start a shell in the Hugo container"
	@echo "  new             - Create a new Hugo content file"
	@echo "     NEW_FILENAME - Name of the new file to create (required)"

.PHONY: shell
shell:
	docker run -it --rm \
		-v ${PWD}:/src \
		${HUGO_IMAGE} \
		ash

.PHONY: build
build:
	docker run -it --rm \
		-v ${PWD}:/src \
		${HUGO_IMAGE} \
		hugo build

.PHONY: run
run:
	docker run -it --rm \
		-v ${PWD}:/src \
		-p ${PORT}:${PORT} \
		${HUGO_IMAGE} \
		hugo server -p ${PORT} --baseURL ${BASEURL} --disableFastRender

.PHONY: new
new:
	@if [[ -z "${NEW_FILENAME}" ]]; then \
		echo "Please set NEW_FILENAME to the name of the new file"; \
		exit 1; \
	fi
	@echo "${NEW_FILEPATH}"
	docker run -it --rm \
		-v ${PWD}:/src \
		${HUGO_IMAGE} \
		hugo new ${NEW_FILEPATH}
