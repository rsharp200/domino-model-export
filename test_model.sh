#!/bin/bash

set -e

MODEL_ID=$1

TEST=$(curl ${DOMINO_API_HOST}/models/${MODEL_ID}/latest/model -s -H 'Content-Type: application/json' -d '{ "data": { "dropperc": 1000, "mins": 941, "consecmonths": 29, "income": 35000 } }' -u $DOMINO_API_USER_KEY | grep "request_id" | wc -l)

if [[ $TEST -gt 0 ]]; then
    echo "TEST: PASS"
    exit 0
else
    echo "TEST: FAIL"
    exit 1
fi
