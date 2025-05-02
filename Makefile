# Makefile for building and running testserver for hugo

HUGO_IMAGE="hugomods/hugo:0.145.0"

PORT="8080"
BASEURL="http://localhost:${PORT}/"

.PHONY: usage
usage:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  build   - Build the Hugo site"
	@echo "  run     - Run the Hugo server"
	@echo "  shell   - Start a shell in the Hugo container"

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
