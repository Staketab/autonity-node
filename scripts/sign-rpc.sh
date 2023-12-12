#!/bin/bash

. .env

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"

echo -e "${GREEN}Creating a directory for the keystore...${NORMAL}"
mkdir -p ${DATADIR}/keystore

echo -e "${YELLOW}Importing the nodekey...${NORMAL}"
aut account import-private-key ${NODEKEY_PATH} | tee /dev/tty | awk '{print $2}' > ${DATADIR}/signs/import

echo -e "${YELLOW}Signing the message 'public rpc'...${NORMAL}"
aut account sign-message "public rpc" --keyfile ${DATADIR}/signs/import} --password ${KEYPASS} | tee /dev/tty | grep -o '0x[0-9a-fA-F]*' > ${DATADIR}/signs/sign-rpc

if [ -s "${DATADIR}/signs/sign-rpc" ]; then
    echo -e "${GREEN}Process completed successfully.${NORMAL}"
else
    echo -e "${RED}Something went wrong: The sign-rpc file is empty.${NORMAL}"
fi
