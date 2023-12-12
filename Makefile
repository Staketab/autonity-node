include .env
export

USER_HOME := $(HOME)
PRIVKEY ?= 
AMOUNT ?= 0.5
COMPOSE_ALL_FILES := -f docker-compose.yml -f docker-compose.oracle.yml -f docker-compose.node-exporter.yml
COMPOSE_OPERATOR := -f docker-compose.yml
COMPOSE_ORACLE := -f docker-compose.oracle.yml
COMPOSE_NODE_EXPORTER := -f docker-compose.node-exporter.yml
SERVICES := autonity autonity_oracle

compose_v2_not_supported = $(shell command docker compose 2> /dev/null)
ifeq (,$(compose_v2_not_supported))
  DOCKER_COMPOSE_COMMAND = docker-compose
else
  DOCKER_COMPOSE_COMMAND = docker compose
endif

# --------------------------
.PHONY: dir pipx aut autrc all up down up-oracle down-oracle log log-o clean acc get-acc acc-balance oracle-balance acc-oracle get-oracle-acc sign get-enode get-priv genOwnershipProof add-validator compute register bond unbond list import sign-onboard send test

dir:
	@mkdir -p $$(echo ${DATADIR})/signs/

pipx:
	@chmod +x ./scripts/pipx-install.sh
	@/bin/bash -c 'source $(USER_HOME)/.bashrc' && bash ./scripts/pipx-install.sh && /bin/bash -c 'source $(USER_HOME)/.bashrc'

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
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) up autonity -d

down:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) down -v

up-oracle:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) up autonity_oracle -d

down-oracle:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) down -v

log:
	sudo docker logs --follow autonity -f --tail 100

log-o:
	sudo docker logs --follow autonity_oracle -f --tail 100

clean:
	@make down
	@make down-oracle
	@chmod +x ./scripts/clean.sh
	@./scripts/clean.sh
 
acc:
	@mkdir -p $$(echo ${DATADIR})/keystore
	@aut account new --keyfile $$(echo ${DATADIR})/keystore/$(KEYNAME).key

get-acc:
	@echo $(shell aut account info | jq -r '.[].account')

acc-balance:
	@aut account balance --keyfile $$(echo ${DATADIR})/keystore/$(KEYNAME).key

oracle-balance:
	@aut account balance --keyfile $$(echo ${DATADIR})/keystore/$(ORACLE_KEYNAME).key

acc-oracle:
	@mkdir -p $$(echo ${DATADIR})/keystore
	@aut account new --keyfile $$(echo ${DATADIR})/keystore/$(ORACLE_KEYNAME).key

get-oracle-acc:
	@echo $(shell aut account info --keyfile $$(echo ${DATADIR})/keystore/$(ORACLE_KEYNAME).key | jq -r '.[].account')

sign:
	@aut account sign-message "I have read and agree to comply with the Piccadilly Circus Games Competition Terms and Conditions published on IPFS with CID QmVghJVoWkFPtMBUcCiqs7Utydgkfe19wkLunhS5t57yEu" --keyfile  $$(echo ${DATADIR})/keystore/$(KEYNAME).key --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $$(echo ${DATADIR})/signs/sign

get-enode:
	@aut node info | jq -r '.admin_enode'

get-priv:
	@chmod +x ./bin/ethkey
	@/bin/bash -c './bin/ethkey inspect --private $(ORACLE_KEYFILE)'

save-priv:
	@echo "$(PRIVKEY)" >> $(ORACLE_PRIV_KEYFILE)

genOwnershipProof:
	@sudo docker run -t -i --volume $$(echo ${DATADIR}):/autonity-chaindata --volume $(ORACLE_PRIV_KEYFILE):/oracle.key --name autonity-proof --rm ghcr.io/autonity/autonity:latest genOwnershipProof --nodekey ./autonity-chaindata/autonity/nodekey --oraclekey oracle.key $(shell aut account info | jq -r '.[].account') | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $$(echo ${DATADIR})/signs/proof

add-validator:
	@if ! grep -q 'validator=' $(USER_HOME)/.autrc; then \
		echo "validator=$$(aut validator compute-address $$(aut node info | jq -r '.admin_enode'))" >> $(USER_HOME)/.autrc; \
	fi

compute:
	@aut validator compute-address $(shell aut node info | jq -r '.admin_enode')
	@make add-validator

register:
	@aut validator register $(shell aut node info | jq -r '.admin_enode') $(shell aut account info --keyfile $$(echo ${DATADIR})/keystore/$(ORACLE_KEYNAME).key | jq -r '.[].account') $(shell cat $$(echo ${DATADIR})/signs/proof) | aut tx sign - | aut tx send - | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $$(echo ${DATADIR})/signs/register

bond:
	@aut validator bond --validator $(shell aut validator compute-address $(shell aut node info | jq -r '.admin_enode')) $(AMOUNT) | aut tx sign - | aut tx send -

unbond:
	@aut validator unbond --validator $(shell aut validator compute-address $(shell aut node info | jq -r '.admin_enode')) $(AMOUNT) | aut tx sign - | aut tx send -

list:
	@aut validator list | grep $(shell aut validator compute-address $(shell aut node info | jq -r '.admin_enode'))

import:
	@aut account import-private-key $(NODEKEY_PATH) | tee /dev/tty | awk '{print $$2}' > $$(echo ${DATADIR})/signs/import

sign-onboard:
	@aut account sign-message "validator onboarded" --keyfile $(shell cat $$(echo ${DATADIR})/signs/import) --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $$(echo ${DATADIR})/signs/sign-onboard

sign-rpc:
	@aut account sign-message "public rpc" --keyfile $(shell cat $$(echo ${DATADIR})/signs/import) --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $$(echo ${DATADIR})/signs/sign-rpc

send:
	@aut tx make --to $(RECEPIENT) --value $(AMOUNT) | aut tx sign - | aut tx send -

test:
	@echo $(shell cat $$(echo ${DATADIR})/signs/proof)
