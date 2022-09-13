#!/bin/bash

set -e

MODEL_ID="6320c021de659c33feb8efe5"
MODEL_API_TOKEN="P4q84ATwNialWVxHeXRwO42VfOzQSx0OQFXLBMYKrqnUgcitaW8EZsS27LanNZgj"

TEST=$(curl ${DOMINO_API_HOST}/models/${MODEL_ID}/latest/model -s -H 'Content-Type: application/json' -d '{ "data": { "dropperc": 1000, "mins": 941, "consecmonths": 29, "income": 35000 } }' | grep "request_id" | wc -l)

if [[ $TEST -gt 0 ]]; then
    echo "TEST: PASS"
    exit 0
else
    echo "TEST: FAIL"
    exit 1
fi
