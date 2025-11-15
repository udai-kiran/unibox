.PHONY: build run shell clean push pull help

IMAGE_NAME := unibox
IMAGE_TAG := latest
FULL_IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

help:
	@echo "Available targets:"
	@echo "  make build       - Build the Docker image"
	@echo "  make run         - Run container interactively"
	@echo "  make shell       - Start a shell in the container"
	@echo "  make clean       - Remove the Docker image"
	@echo "  make push        - Push image to registry (set REGISTRY variable)"
	@echo "  make pull        - Pull image from registry (set REGISTRY variable)"

build:
	docker build -t $(FULL_IMAGE) .

run:
	docker run --rm -it $(FULL_IMAGE)

shell:
	docker run --rm -it -v $(PWD):/workspace $(FULL_IMAGE) /bin/bash

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
