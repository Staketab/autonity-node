include .env
export

USER_HOME := $(HOME)
COMPOSE_ALL_FILES := -f docker-compose.yml -f docker-compose.oracle.yml -f docker-compose.node-exporter.yml
COMPOSE_OPERATOR := -f docker-compose.yml
COMPOSE_ORACLE := -f docker-compose.oracle.yml
COMPOSE_NODE_EXPORTER := -f docker-compose.node-exporter.yml
SERVICES := autonity oracle node-exporter

compose_v2_not_supported = $(shell command docker compose 2> /dev/null)
ifeq (,$(compose_v2_not_supported))
  DOCKER_COMPOSE_COMMAND = docker-compose
else
  DOCKER_COMPOSE_COMMAND = docker compose
endif

# --------------------------
.PHONY: 

dir:
	mkdir -p $$(echo ${DATADIR})

pipx:
	@chmod +x ./scripts/pipx-install.sh
	/bin/bash -c 'source $(USER_HOME)/.bashrc' && bash ./scripts/pipx-install.sh && /bin/bash -c 'source $(USER_HOME)/.bashrc'

aut:
	@chmod +x ./scripts/aut-install.sh
	@./scripts/aut-install.sh

autrc:
	@chmod +x ./scripts/autrc.sh
	@./scripts/autrc.sh

all:
	@make dir
	@make pipx
	@make aut
	@make autrc

up:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) up -d

down:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) down -v

up-oracle:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_ORACLE) up -d

down-oracle:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_ORACLE) down -v

logs:
	sudo docker logs --follow autonity -f --tail 1000

log:
	$(DOCKER_COMPOSE_COMMAND) logs -f $(SERVICES)

clean:
	@make down
	@make down-oracle
	@chmod +x ./scripts/clean.sh
	@./scripts/clean.sh