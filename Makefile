SHELL := /bin/bash

APP_SERVICE_NAME := app
XDEBUG_SERVICE_NAME := xdebug
TEST_SERVICE_NAME := test

include docker-compose.env
-include .env.local

.PHONY: dcps dcupd dcdn dcstop dclogs dcshell dcxdbg dctest dccheck

default: dcps

# Get services URLs and docker-compose process status.
dcps:
	$(eval APP_ID := $(shell bin/docker-compose ps -q $(APP_SERVICE_NAME) 2> /dev/null))
	$(eval APP_PORT := $(shell docker inspect $(APP_ID) --format='{{json (index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort}}' 2> /dev/null))
	@echo $(APP_SERVICE_NAME): $(if $(APP_PORT), "http://localhost:$(APP_PORT)", "port not found.")

	-$(eval XDEBUG_ID := $(shell bin/docker-compose --profile xdebug ps -q $(XDEBUG_SERVICE_NAME) 2> /dev/null))
	-$(eval XDEBUG_PORT := $(shell docker inspect $(XDEBUG_ID) --format='{{json (index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort}}' 2> /dev/null))
	@echo $(XDEBUG_SERVICE_NAME): $(if $(XDEBUG_PORT), "http://localhost:$(XDEBUG_PORT)", "port not found.")

# New line before the ps.
	@echo
	@bin/docker-compose ps -a

# Rebuild images, remove orphans, and docker-compose up.
dcupd:
	bin/docker-compose up -d --build --remove-orphans

# Rebuild images, remove orphans, and docker-compose up.
dcdn:
	bin/docker-compose down --remove-orphans

# Stop all runner containers.
dcstop:
	bin/docker-compose stop

# Get app-name container logs.
dclogs:
	bin/docker-compose logs --tail=100 -f $(APP_SERVICE_NAME) $(XDEBUG_SERVICE_NAME)

# Get a bash inside running app-name container.
dcshell:
	bin/docker-compose run --rm --no-deps --entrypoint="" $(APP_SERVICE_NAME) bash

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
