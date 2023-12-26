#!/bin/bash

. .env

if [ -f ${DATADIR}/message ]; then
    echo "Message file exist..."
    cd ${DATADIR}
    MESSAGE=$(cat ${DATADIR}/message)
    echo -n $MESSAGE | https https://cax.piccadilly.autonity.org/api/apikeys api-sig:@message.sig > ${DATADIR}/api-key
    cd
    cat ${DATADIR}/api-key | jq '.apikey'
else
    MESSAGE=$(jq -nc --arg nonce "$(date +%s%N)" '$ARGS.named')
    echo $MESSAGE > ${DATADIR}/message
    aut account sign-message $MESSAGE ${DATADIR}/message.sig
    cd ${DATADIR}
    echo -n $MESSAGE | https https://cax.piccadilly.autonity.org/api/apikeys api-sig:@message.sig > ${DATADIR}/api-key
    cd
cat ${DATADIR}/api-key | jq '.apikey'
fi
