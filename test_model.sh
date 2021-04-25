#!/bin/bash

set -e

DOMINO_HOST="https://demo.dominodatalab.com"
AUTH_CREDENTIALS="qpo02njUOaIvOASFvmdIlv7rPiBrxRH6V6iBV1EokIocPtb8wod11V20wmTHWMTh:qpo02njUOaIvOASFvmdIlv7rPiBrxRH6V6iBV1EokIocPtb8wod11V20wmTHWMTh"

MODEL_ID=$1

TEST=$(curl ${DOMINO_HOST}/models/${MODEL_ID}/latest/model -s -H 'Content-Type: application/json' -d '{ "data": { "dropperc": 1000, "mins": 941, "consecmonths": 29, "income": 35000 } }' -u $AUTH_CREDENTIALS | grep "request_id" | wc -l)

if [[ $TEST -gt 0 ]]; then
    echo "TEST: PASS"
    exit 0
else
    echo "TEST: FAIL"
    exit 1
fi
