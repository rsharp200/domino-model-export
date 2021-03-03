#!/bin/bash

PAYLOAD="{\"projectId\": \"${PROJECT_ID}\", \"file\": \"${MODEL_FILE}\", \"function\": \"${MODEL_FUNCTION}\"}"

curl ${DOMINO_API_HOST}/v1/models/${MODEL_ID}/versions -s -H "X-Domino-Api-Key: ${DOMINO_USER_API_KEY}" -H 'Content-Type: application/json' -d "${PAYLOAD}"
