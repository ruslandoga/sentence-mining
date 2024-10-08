.PHONY: help build push

IMAGE_NAME := sentence-mining
REGISTRY := ghcr.io/ruslandoga
DATE_TAG := $(shell date +%Y%m%d)
COMMIT_TAG := $(shell git rev-parse --short HEAD)
BRANCH_TAG := $(shell git rev-parse --abbrev-ref HEAD)

help:
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## build contianer image
	docker build . -t $(IMAGE_NAME)

push: build ## push container image to ghcr.io/ruslandoga/sentence-mining
	@echo "Tagging and pushing $(IMAGE_NAME) to $(REGISTRY)..."
	docker tag $(IMAGE_NAME) $(REGISTRY)/$(IMAGE_NAME):$(DATE_TAG)
	docker tag $(IMAGE_NAME) $(REGISTRY)/$(IMAGE_NAME):$(COMMIT_TAG)
	docker tag $(IMAGE_NAME) $(REGISTRY)/$(IMAGE_NAME):$(BRANCH_TAG)
	docker tag $(IMAGE_NAME) $(REGISTRY)/$(IMAGE_NAME):latest
	docker push $(REGISTRY)/$(IMAGE_NAME):$(DATE_TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(COMMIT_TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(BRANCH_TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):latest
	@echo "Successfully pushed all tags for $(IMAGE_NAME) to $(REGISTRY)."
