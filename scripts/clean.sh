#!/bin/bash

. .env
# sudo rm -rf ${DATADIR}/autonity
find ${DATADIR}/autonity -mindepth 1 ! -name 'autonitykeys' -exec rm -rf {} +

echo "Clean completed."
