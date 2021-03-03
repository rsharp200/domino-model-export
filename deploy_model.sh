#!/bin/bash

PROJECT_ID=$1
MODEL_ID=$2
MODEL_FILE=$3
MODEL_FUNCTION=$4

function domino_model_status {
    RESPONSE=$(curl "${DOMINO_API_HOST}/models/${MODEL_ID}/versions/json?pageNumber=1&pageSize=100" -s -H "X-Domino-Api-Key: ${DOMINO_USER_API_KEY}")
    MODEL_VERSION_STATUS=$(echo "$RESPONSE" | jq ".results[] | select(.number==${MODEL_VERSION_NUMBER}) | .deploymentStatus.name"
}

echo "Publishing model..."
PAYLOAD="{\"projectId\": \"${PROJECT_ID}\", \"file\": \"${MODEL_FILE}\", \"function\": \"${MODEL_FUNCTION}\"}"

RESPONSE=$(curl ${DOMINO_API_HOST}/v1/models/${MODEL_ID}/versions -s -H "X-Domino-Api-Key: ${DOMINO_USER_API_KEY}" -H 'Content-Type: application/json' -d "${PAYLOAD}")

MODEL_VERSION_NUMBER=$(echo $RESPONSE | jq -r '.number')

echo "Waiting for model to come online..."

while true; do
    MODEL_VERSION_STATUS=""
    sleep 5
    domino_model_status

    if [[ "$MODEL_VERSION_STATUS" == "Running" ]]; then break; fi
done

echo "Model publishing is done"