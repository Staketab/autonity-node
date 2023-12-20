include .env
export

USER_HOME := $(HOME)
PRIVKEY ?= 
AMOUNT ?= 0.5
PRICE ?= 10.05
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
.PHONY: dir pipx aut autrc rpc validator all up down up-oracle log log-o clean acc get-acc acc-balance oracle-balance acc-oracle get-oracle-acc sign get-enode get-priv save-priv genOwnershipProof add-validator compute register bond unbond list get-comm import sign-onboard sign-rpc send val-info test

dir:
	@mkdir -p $$(echo ${DATADIR})/keystore/ $$(echo ${DATADIR})/signs/

pipx:
	@chmod +x ./scripts/pipx-install.sh
	@/bin/bash -c 'source $(USER_HOME)/.bashrc' && bash ./scripts/pipx-install.sh && /bin/bash -c 'source $(USER_HOME)/.bashrc'

httpie:
	@chmod +x ./scripts/httpie-install.sh
	@./scripts/httpie-install.sh

aut:
	@chmod +x ./scripts/aut-install.sh
	@./scripts/aut-install.sh

autrc:
	@chmod +x ./scripts/autrc.sh
	@./scripts/autrc.sh

rpc:
	@chmod +x ./scripts/sign-rpc.sh
	@./scripts/sign-rpc.sh

validator:
	@chmod +x ./scripts/sign-validator.sh
	@./scripts/sign-validator.sh

all:
	@make dir
	@make pipx
	@make aut
	@make autrc && /bin/bash -c 'source $(USER_HOME)/.bashrc'

up:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) up -d autonity

down:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) down -v

up-oracle:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) up -d autonity_oracle

log:
	sudo docker logs --follow autonity -f --tail 100

log-o:
	sudo docker logs --follow autonity_oracle -f --tail 100

clean:
	@make down
	@chmod +x ./scripts/clean.sh
	@./scripts/clean.sh
 
acc:
	@mkdir -p $$(echo ${DATADIR})/keystore
	@aut account new --keyfile $$(echo ${DATADIR})/keystore/$(KEYNAME).key

get-acc:
	@aut account info --keyfile $$(echo ${DATADIR})/keystore/$(KEYNAME).key

acc-balance:
	@aut account balance $(if $(NTN),--ntn) $(if $(TOKEN),--token $(TOKEN)) --keyfile $$(echo ${DATADIR})/keystore/$(KEYNAME).key

oracle-balance:
	@aut account balance $(if $(NTN),--ntn) $(if $(TOKEN),--token $(TOKEN)) --keyfile $$(echo ${DATADIR})/keystore/$(ORACLE_KEYNAME).key

acc-oracle:
	@mkdir -p $$(echo ${DATADIR})/keystore
	@aut account new --keyfile $$(echo ${DATADIR})/keystore/$(ORACLE_KEYNAME).key

get-oracle-acc:
	@aut account info --keyfile $$(echo ${DATADIR})/keystore/$(ORACLE_KEYNAME).key

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
	@if ! grep -q 'validator=' $(USER_HOME)/.autrc; then
		echo "validator=$$(aut validator compute-address $$(aut node info | jq -r '.admin_enode'))" >> $(USER_HOME)/.autrc;
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

get-comm:
	@aut protocol get-committee | grep $(shell aut validator compute-address $(shell aut node info | jq -r '.admin_enode'))
	
import:
	@aut account import-private-key $(NODEKEY_PATH) | tee /dev/tty | awk '{print $$2}' > $$(echo ${DATADIR})/signs/import

sign-onboard:
	@aut account sign-message "validator onboarded" --keyfile $(shell cat $$(echo ${DATADIR})/signs/import) --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $$(echo ${DATADIR})/signs/sign-onboard

sign-rpc:
	@aut account sign-message "public rpc" --keyfile $(shell cat $$(echo ${DATADIR})/signs/import) --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $$(echo ${DATADIR})/signs/sign-rpc

send:
	@aut tx make --to $(RECEPIENT) --value $(AMOUNT) $(if $(NTN),--ntn) $(if $(TOKEN),--token $(TOKEN)) | aut tx sign - | aut tx send -

val-info:
	@aut validator info

node-info:
	@aut node info

claim:
	@aut validator claim-rewards | aut tx sign - | aut tx send -

activate:
	@aut  validator activate | aut tx sign - | aut tx send -

api:
	@chmod +x ./scripts/api.sh
	@./scripts/api.sh

cex-balance:
	@https GET https://cax.piccadilly.autonity.org/api/balances/ API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey')

get-order:
	@https GET https://cax.piccadilly.autonity.org/api/orderbooks/ API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey')

ntn-quote:
	@https GET https://cax.piccadilly.autonity.org/api/orderbooks/NTN-USD/quote API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey')

atn-quote:
	@https GET https://cax.piccadilly.autonity.org/api/orderbooks/ATN-USD/quote API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey')

buy-ntn:
	@https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey') pair=NTN-USD side=bid price=$(PRICE)  amount=$(AMOUNT)

sell-ntn:
	@https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey') pair=NTN-USD side=ask price=$(PRICE)  amount=$(AMOUNT)

ntn-withdraw:
	@https POST https://cax.piccadilly.autonity.org/api/withdraws/ API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey') symbol=NTN  amount=$(AMOUNT)

buy-atn:
	@https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey') pair=ATN-USD side=bid price=$(PRICE)  amount=$(AMOUNT)

sell-atn:
	@https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey') pair=ATN-USD side=ask price=$(PRICE)  amount=$(AMOUNT)

atn-withdraw:
	@https POST https://cax.piccadilly.autonity.org/api/withdraws/ API-Key:$(shell cat $$(echo ${DATADIR})/api-key | jq -r '.apikey') symbol=ATN  amount=$(AMOUNT)

test:
	@echo $(shell cat $$(echo ${DATADIR})/signs/proof)
