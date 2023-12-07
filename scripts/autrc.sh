#!/bin/bash

ENV_FILE="./.env"
AUTRC_FILE="#HOME/.autrc"

if [ -f "$ENV_FILE" ]; then
    export $(grep HTTP_PORT $ENV_FILE)

    if [ -z ${HTTP_PORT+x} ]; then
        echo "HTTP_PORT variable is not defined in $ENV_FILE."
    else
        echo "[aut]" > $AUTRC_FILE
        echo "rpc_endpoint=http://127.0.0.1:${HTTP_PORT}" >> $AUTRC_FILE
        echo "File $AUTRC_FILE created."
    fi
else
    echo "File $ENV_FILE not found."
fi
