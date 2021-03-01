#!/bin/bash

DOMINO_HOST="https://demo.dominodatalab.com"
AUTH_CREDENTIALS="uYZUb5q10eNfLmnXepFdW1MscL9kKTX5wK5bf2vrnhw9xjMql236UNnMBBa1CcLO:uYZUb5q10eNfLmnXepFdW1MscL9kKTX5wK5bf2vrnhw9xjMql236UNnMBBa1CcLO"

MODEL_ID="603a943ecc42014cc2ddda51"

TEST_EXPECT="0.9983654867248395"
curl ${DOMINO_HOST}/models/${MODEL_ID}/latest/model -s -H 'Content-Type: application/json' -d '{ "data": { "dropperc": 1000, "mins": 941, "consecmonths": 29, "income": 35000 } }' -u $AUTH_CREDENTIALS | jq -r '.result[0]' | tee /tmp/result.txt

if [[ "$(cat /tmp/result.txt)" == "$TEST_EXPECT" ]]; then
	echo "TEST: PASS"
else
	echo "TEST: FAIL"
fi
