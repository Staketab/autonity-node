#!/bin/bash

. .env

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"

echo -e "${GREEN}Creating directories for the keystore and signs...${NORMAL}"
mkdir -p ${DATADIR}/keystore ${DATADIR}/signs

echo -e "${YELLOW}Extracting Private Key from keyfile...${NORMAL}"
chmod +x ./bin/ethkey
./bin/ethkey inspect --private ${ORACLE_KEYFILE}

echo -e "${YELLOW}Please enter the Private Key generated in the previous step:${NORMAL}"
read -s -p "Enter Private Key: " PRIVKEY
echo ""

echo -e "${YELLOW}Creating a file to store the Private Key...${NORMAL}"
echo "${PRIVKEY}" >> ${ORACLE_PRIV_KEYFILE}

echo -e "${YELLOW}Generating Ownership Proof...${NORMAL}"
sudo docker run -t -i --volume ${DATADIR}:/autonity-chaindata --volume ${ORACLE_PRIV_KEYFILE}:/oracle.key --name autonity-proof --rm ghcr.io/autonity/autonity:latest genOwnershipProof --nodekey ./autonity-chaindata/autonity/nodekey --oraclekey oracle.key $(aut account info | jq -r '.[].account') | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > ${DATADIR}/signs/proof

echo -e "${YELLOW}Appending validator configuration to .autrc file...${NORMAL}"
if ! grep -q 'validator=' ${HOME}/.autrc; then
    echo "validator=$(aut validator compute-address $(aut node info | jq -r '.admin_enode'))" >> ${HOME}/.autrc
fi

echo -e "${YELLOW}Registering as a validator...${NORMAL}"
aut validator register $(aut node info | jq -r '.admin_enode') $(aut account info --keyfile ${DATADIR}/keystore/${ORACLE_KEYNAME}.key | jq -r '.[].account') $(cat ${DATADIR}/signs/proof) | aut tx sign - | aut tx send - | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > ${DATADIR}/signs/register

echo -e "${YELLOW}Signing the message 'validator onboarded'...${NORMAL}"
echo -e "${YELLOW}--------------------------------------------${NORMAL}"
aut account sign-message "validator onboarded" --keyfile $(cat ${DATADIR}/signs/import) --password ${KEYPASS} | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > ${DATADIR}/signs/sign-onboard
echo -e "${YELLOW}--------------------------------------------${NORMAL}"
