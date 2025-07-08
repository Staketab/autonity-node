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

compose_v2_supported = $(shell command docker compose 2> /dev/null)
ifeq (,$(compose_v2_supported))
  DOCKER_COMPOSE_COMMAND = docker-compose
else
  DOCKER_COMPOSE_COMMAND = docker compose
endif

# --------------------------
.PHONY: dir pipx aut aut-upgrade autrc rpc validator all up down up-oracle log log-o clean acc get-acc acc-balance oracle-balance acc-oracle get-oracle-acc sign get-enode get-enode-offline get-priv save-priv genOwnershipProof add-validator compute register bond unbond list get-comm import sign-onboard sign-rpc send val-info test

dir:
	@mkdir -p $(DATADIR)/keystore/ $(DATADIR)/signs/

pipx:
	@chmod +x ./scripts/pipx-install.sh
	@bash ./scripts/pipx-install.sh

httpie:
	@chmod +x ./scripts/httpie-install.sh
	@./scripts/httpie-install.sh

aut:
	@chmod +x ./scripts/aut-install.sh
	@export PATH="$$HOME/.local/bin:$$PATH" && ./scripts/aut-install.sh

aut-upgrade:
	@export PATH="$$HOME/.local/bin:$$PATH" && pipx upgrade autonity-cli

autrc:
	@chmod +x ./scripts/autrc.sh
	@./scripts/autrc.sh

rpc:
	@chmod +x ./scripts/sign-rpc.sh
	@./scripts/sign-rpc.sh

validator:
	@chmod +x ./scripts/sign-validator.sh
	@./scripts/sign-validator.sh

all: dir pipx aut autrc

pull:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) pull

up:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) up -d autonity

down:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) down -v

down-a:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) down autonity

up-oracle:
	$(DOCKER_COMPOSE_COMMAND) $(COMPOSE_OPERATOR) up -d autonity_oracle

log:
	sudo docker logs --follow autonity --tail 100

log-o:
	sudo docker logs --follow autonity_oracle --tail 100

clean:
	@make down
	@chmod +x ./scripts/clean.sh
	@./scripts/clean.sh
 
acc:
	@mkdir -p $(DATADIR)/keystore
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account new --keyfile $(DATADIR)/keystore/$(KEYNAME).key

get-acc:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account info --keyfile $(DATADIR)/keystore/$(KEYNAME).key

acc-balance:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account balance $(if $(NTN),--ntn) $(if $(TOKEN),--token $(TOKEN)) --keyfile $(DATADIR)/keystore/$(KEYNAME).key

oracle-balance:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account balance $(if $(NTN),--ntn) $(if $(TOKEN),--token $(TOKEN)) --keyfile $(DATADIR)/keystore/$(ORACLE_KEYNAME).key

acc-oracle:
	@mkdir -p $(DATADIR)/keystore
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account new --keyfile $(DATADIR)/keystore/$(ORACLE_KEYNAME).key

get-oracle-acc:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account info --keyfile $(DATADIR)/keystore/$(ORACLE_KEYNAME).key

acc-sign:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account sign-message "I confirm that I own the above address and will use it to take part in on-chain tasks for the Piccadilly Circus Games Competition" --keyfile $(DATADIR)/keystore/$(KEYNAME).key --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $(DATADIR)/signs/acc-sign || { echo "Failed to generate signature"; exit 1; }

sign:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account sign-message "I have read and agree to comply with the Piccadilly Circus Games Competition Terms and Conditions published on IPFS with CID QmVghJVoWkFPtMBUcCiqs7Utydgkfe19wkLunhS5t57yEu" --keyfile $(DATADIR)/keystore/$(KEYNAME).key --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $(DATADIR)/signs/sign || { echo "Failed to generate signature"; exit 1; }

get-enode:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut node info | jq -r '.admin_enode'

get-enode-offline:
	@echo "Generating validator node keys and enode offline using Docker..."
	@mkdir -p $(DATADIR)/autonity
	@sudo docker run -t -i --volume $(DATADIR):/autonity-chaindata --name autonity-keygen --rm $(TAG) genAutonityKeys --writeaddress /autonity-chaindata/autonity
	@echo "Keys generated successfully. Extracting enode..."
	@if [ -f "$(DATADIR)/autonity/address" ]; then \
		VALIDATOR_ADDRESS=$$(cat $(DATADIR)/autonity/address); \
		echo "Validator address: $$VALIDATOR_ADDRESS"; \
		echo "enode://$$VALIDATOR_ADDRESS@$(YOUR_IP):30303"; \
		echo "enode://$$VALIDATOR_ADDRESS@$(YOUR_IP):30303" > $(DATADIR)/signs/enode-offline; \
	else \
		echo "❌ Failed to generate validator address"; \
		exit 1; \
	fi

get-priv:
	@chmod +x ./bin/ethkey
	@/bin/bash -c './bin/ethkey inspect --json --private $(ORACLE_KEYFILE)'

save-priv:
	@echo "$(PRIVKEY)" >> $(ORACLE_PRIV_KEYFILE)

genOwnershipProof:
	@sudo docker run -t -i --volume $(DATADIR):/autonity-chaindata --volume $(ORACLE_PRIV_KEYFILE):/oracle.key --name autonity-proof --rm $(TAG) genOwnershipProof --autonitykeys ./autonity-chaindata/autonity/autonitykeys --oraclekey oracle.key $(shell export PATH="$$HOME/.local/bin:$$PATH" && aut account info | jq -r '.[].account')

add-validator:
	@sed -i '/^validator=/d' $(USER_HOME)/.autrc
	@echo "validator=$$(export PATH="$$HOME/.local/bin:$$PATH" && aut validator compute-address $$(aut node info | jq -r '.admin_enode'))" >> $(USER_HOME)/.autrc

compute:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator compute-address $(shell export PATH="$$HOME/.local/bin:$$PATH" && aut node info | jq -r '.admin_enode')
	@make add-validator

register:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator register $(shell export PATH="$$HOME/.local/bin:$$PATH" && aut node info | jq -r '.admin_enode') $(shell export PATH="$$HOME/.local/bin:$$PATH" && aut account info --keyfile $(DATADIR)/keystore/$(ORACLE_KEYNAME).key | jq -r '.[].account') $(shell jq -r '.ConsensusPublicKey' $(DATADIR)/signs/consensus-key) $(shell cat $(DATADIR)/signs/proof) | aut tx sign - | aut tx send - | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $(DATADIR)/signs/register || { echo "Failed to register validator"; exit 1; }

bond:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator bond --validator $(shell export PATH="$$HOME/.local/bin:$$PATH" && aut validator compute-address $(shell aut node info | jq -r '.admin_enode')) $(AMOUNT) | aut tx sign - | aut tx send -

unbond:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator unbond --validator $(shell export PATH="$$HOME/.local/bin:$$PATH" && aut validator compute-address $(shell aut node info | jq -r '.admin_enode')) $(AMOUNT) | aut tx sign - | aut tx send -

get-ckey:
	@chmod +x ./bin/ethkey
	@/bin/bash -c './bin/ethkey autinspect $(NODEKEY_PATH) --json' | tee $(DATADIR)/signs/consensus-key

ckey-test:
	@echo $(shell jq -r '.ConsensusPublicKey' $(DATADIR)/signs/consensus-key)

list:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator list | grep $(shell export PATH="$$HOME/.local/bin:$$PATH" && aut validator compute-address $(shell aut node info | jq -r '.admin_enode'))

get-comm:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut protocol get-committee | grep $(shell export PATH="$$HOME/.local/bin:$$PATH" && aut validator compute-address $(shell aut node info | jq -r '.admin_enode'))
	
get-val-list:
	export PATH="$$HOME/.local/bin:$$PATH" && aut protocol get-committee \
	| jq -r '.[] | [(.voting_power|tonumber / pow(10;18)), .address] | @csv' \
	| column -t -s"," | tr -d '"' | sort -k1 -n -r | nl

import:
	@echo $(shell head -c 64 $(NODEKEY_PATH)) > $(DATADIR)/node.priv
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account import-private-key $(DATADIR)/node.priv | tee /dev/tty | awk '{print $$2}' > $(DATADIR)/signs/import || { echo "Failed to import private key"; exit 1; }

sign-onboard:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account sign-message "validator onboarded" --keyfile $(shell cat $(DATADIR)/signs/import) --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $(DATADIR)/signs/sign-onboard || { echo "Failed to generate onboard signature"; exit 1; }

sign-rpc:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut account sign-message "public rpc" --keyfile $(shell cat $(DATADIR)/signs/import) --password $(KEYPASS) | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > $(DATADIR)/signs/sign-rpc || { echo "Failed to generate RPC signature"; exit 1; }

send:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut tx make --to $(RECIPIENT) --value $(AMOUNT) $(if $(NTN),--ntn) $(if $(TOKEN),--token $(TOKEN)) | aut tx sign - | aut tx send -

val-info:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator info

val-pause:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator pause | aut tx sign - | aut tx send -

val-activate:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator activate | aut tx sign - | aut tx send -

node-info:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut node info

claim:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut validator claim-rewards | aut tx sign - | aut tx send -

api:
	@chmod +x ./scripts/api.sh
	@./scripts/api.sh

usdc-transfer:
	@export PATH="$$HOME/.local/bin:$$PATH" && aut token transfer --token 0x3a60C03a86eEAe30501ce1af04a6C04Cf0188700 0x11F62c273dD23dbe4D1713C5629fc35713Aa5a94 $(AMOUNT) | aut tx sign - | aut tx send -

cex-balance:
	@https GET https://cax.piccadilly.autonity.org/api/balances/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey')

get-orderbooks:
	@https GET https://cax.piccadilly.autonity.org/api/orderbooks/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey')

ntn-quote:
	@https GET https://cax.piccadilly.autonity.org/api/orderbooks/NTN-USDC/quote API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey')

atn-quote:
	@https GET https://cax.piccadilly.autonity.org/api/orderbooks/ATN-USDC/quote API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey')

buy-ntn:
	@https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey') pair=NTN-USDC side=bid price=$(PRICE)  amount=$(AMOUNT)

sell-ntn:
	@https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey') pair=NTN-USDC side=ask price=$(PRICE)  amount=$(AMOUNT)

ntn-withdraw:
	@https POST https://cax.piccadilly.autonity.org/api/withdraws/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey') symbol=NTN  amount=$(AMOUNT)

buy-atn:
	@https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey') pair=ATN-USDC side=bid price=$(PRICE)  amount=$(AMOUNT)

sell-atn:
	@https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey') pair=ATN-USDC side=ask price=$(PRICE)  amount=$(AMOUNT)

atn-withdraw:
	@https POST https://cax.piccadilly.autonity.org/api/withdraws/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey') symbol=ATN  amount=$(AMOUNT)

get-orders:
	@https GET https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey') | jq '.[] | select(.status=="open")'

get-orders-all:
	@https GET https://cax.piccadilly.autonity.org/api/orders/ API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey')

get-order-id:
	@https GET https://cax.piccadilly.autonity.org/api/orders/$(ID) API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey')

delete-order-id:
	@https DELETE https://cax.piccadilly.autonity.org/api/orders/$(ID) API-Key:$(shell cat $(DATADIR)/api-key | jq -r '.apikey')

test:
	@echo $(shell cat $(DATADIR)/signs/proof)

version:
	@sudo docker run -t -i --volume $(DATADIR):/autonity-chaindata --name autonity-version --rm $(TAG) version

oracle-version:
	@sudo docker run -t -i --volume $(DATADIR):/autonity-chaindata --name autonity-oracle-version --rm $(ORACLE_TAG) version