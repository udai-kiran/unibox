.PHONY: build run shell clean push pull help

DOCKER_USERNAME := udaikiran
IMAGE_NAME := unibox
IMAGE_TAG := latest
FULL_IMAGE := $(DOCKER_USERNAME)/$(IMAGE_NAME):$(IMAGE_TAG)
USER_UID := $(shell id -u)
USER_GID := $(shell id -g)
REGISTRY := docker.io/udaikiran

help:
	@echo "Available targets:"
	@echo "  make build       - Build the Docker image with your UID/GID"
	@echo "  make run         - Run container interactively (isolated)"
	@echo "  make shell       - Start a shell in the container (isolated)"
	@echo "  make run-mount   - Run with host home mounted to /host"
	@echo "  make shell-mount - Shell with host home mounted to /host"
	@echo "  make clean       - Remove the Docker image"
	@echo "  make push        - Push image to registry (set REGISTRY variable)"
	@echo "  make pull        - Pull image from registry (set REGISTRY variable)"

build:
	docker build --build-arg USER_UID=$(USER_UID) --build-arg USER_GID=$(USER_GID) -t $(FULL_IMAGE) .

run:
	docker run --rm -it $(FULL_IMAGE)

shell:
	docker run --rm -it $(FULL_IMAGE) /bin/zsh

run-mount:
	docker run --rm -it -v $(HOME):/host $(FULL_IMAGE)

shell-mount:
	docker run --rm -it -v $(HOME):/host $(FULL_IMAGE) /bin/zsh

clean:
	docker rmi $(FULL_IMAGE)

push:
	@if [ -z "$(REGISTRY)" ]; then \
		echo "Error: REGISTRY not set. Usage: make push REGISTRY=your-registry.com/username"; \
		exit 1; \
	fi
	docker tag $(FULL_IMAGE) $(REGISTRY)/$(FULL_IMAGE)
	docker push $(REGISTRY)/$(FULL_IMAGE)

pull:
	@if [ -z "$(REGISTRY)" ]; then \
		echo "Error: REGISTRY not set. Usage: make pull REGISTRY=your-registry.com/username"; \
		exit 1; \
	fi
	docker pull $(REGISTRY)/$(FULL_IMAGE)
