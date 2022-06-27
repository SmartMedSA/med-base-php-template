SHELL := /bin/bash

NAME = app
APP_SERVICE_NAME := app
XDEBUG_SERVICE_NAME := xdebug
TEST_SERVICE_NAME := test

REPO = $(CI_REGISTRY_IMAGE)

ifeq ($(REPO),)
    # Emulate docker-compose repo structure.
	REPO = $(shell basename $(CURDIR))_$(APP_SERVICE_NAME)
endif

ifeq ($(IMAGE_TAG),)
    IMAGE_TAG ?= latest
endif

.PHONY: build buildx check test pull push shell run start stop logs clean release

default: build

build:
	docker build \
		$(PARAMS) \
		--cache-from $(REPO):$(IMAGE_TAG) \
		-t $(REPO):$(IMAGE_TAG) \
		--pull \
		./

buildx:
	docker buildx build \
		$(PARAMS) \
		--cache-from=type=registry,ref=$(REPO):$(IMAGE_TAG) \
		-t $(REPO):$(IMAGE_TAG) \
		--push \
		./

check:
	docker run --rm \
		--name $(NAME) \
		$(PORTS) \
		$(VOLUMES) \
		--env-file .env.local --env-file .env.test $(ENV) \
		$(REPO):$(IMAGE_TAG) \
		composer run check

test:
	docker run --rm \
		--name $(NAME) \
		$(PORTS) \
		$(VOLUMES) \
		--env-file .env.local --env-file .env.test $(ENV) \
		$(REPO):$(IMAGE_TAG) \
		composer run test

pull:
	-docker pull $(REPO):$(IMAGE_TAG)

push:
	docker push $(REPO):$(IMAGE_TAG)

shell:
	docker run --rm -i -t \
		--name $(NAME) \
		$(PORTS) \
		$(VOLUMES) \
		--env-file .env.local $(ENV) \
		$(REPO):$(IMAGE_TAG) \
		/bin/bash

run:
	docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(IMAGE_TAG) $(CMD)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(IMAGE_TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	-docker rm -f $(NAME)

# Run build steps on CI.
ci.build: pull build push

# Get services URLs and docker-compose process status.
dcps:
	$(eval APP_ID := $(shell ${DOCKER_COMPOSE_CMD} ps -q $(APP_SERVICE_NAME)))
	$(eval APP_PORT := $(shell docker inspect $(APP_ID) --format='{{json (index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort}}' 2> /dev/null))
	@echo $(APP_SERVICE_NAME): $(if $(APP_PORT), "http://localhost:$(APP_PORT)", "port not found.")

	-$(eval XDEBUG_ID := $(shell ${DOCKER_COMPOSE_CMD} --profile xdebug ps -q $(XDEBUG_SERVICE_NAME)))
	-$(eval XDEBUG_PORT := $(shell docker inspect $(XDEBUG_ID) --format='{{json (index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort}}' 2> /dev/null))
	@echo $(XDEBUG_SERVICE_NAME): $(if $(XDEBUG_PORT), "http://localhost:$(XDEBUG_PORT)", "port not found.")

# New line before the ps.
	@echo
	@bin/docker-compose ps -a

# Rebuild images, remove orphans, and docker-compose up.
dcupd:
	bin/docker-compose up -d --build --remove-orphans

# Rebuild images, remove orphans, and docker-compose up.
dcdown:
	bin/docker-compose down --remove-orphans

# Stop all runner containers.
dcstop:
	bin/docker-compose stop

# Get app-name container logs.
dclogs:
	bin/docker-compose logs --tail=100 -f $(APP_SERVICE_NAME)

# Get a bash inside running app-name container.
dcshell:
	bin/docker-compose exec $(APP_SERVICE_NAME) bash

# Start app-name with xdebug enabled.
dcxdbg:
	bin/docker-compose --profile $(XDEBUG_SERVICE_NAME) up -d --build --remove-orphans
	bin/docker-compose --profile $(XDEBUG_SERVICE_NAME) logs --tail=100 -f $(XDEBUG_SERVICE_NAME)

# Start app-name test
dctest:
	bin/docker-compose --profile $(TEST_SERVICE_NAME) run --rm test composer test

dccheck:
	bin/docker-compose --profile $(TEST_SERVICE_NAME) run --rm test composer check

# Include the .d makefiles. The - at the front suppresses the errors of missing
# Include the .d makefiles.
-include makefiles.d/*
