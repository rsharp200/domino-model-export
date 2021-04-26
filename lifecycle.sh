#!/bin/bash

set -e

export DOMINO_API_HOST="<Set to your Domino URL>"
export DOMINO_USER_API_KEY="<Set to your user API key>"
export DOMINO_PROJECT_NAME="<Set to your Project name>"
export DOMINO_PROJECT_OWNER="<Set to Domino username>"

export PROJECT_ID="<Set to your project's ID>"
export MODEL_ID="<Set to your model API ID>" #This is as we are publishing a new version of an already existing model API
export MODEL_FILE="<Set to the file which contains the model code>"
export MODEL_FUNCTION="<Set to the function you want the API to invoke>"

# Checkis if the Domino job is running
# Expects RUN_ID argument
function domino_job_status {
    RESPONSE=$(curl ${DOMINO_API_HOST}/v1/projects/${DOMINO_PROJECT_OWNER}/${DOMINO_PROJECT_NAME}/runs/${1} -s -H "X-Domino-Api-Key: ${DOMINO_USER_API_KEY}")
    DOMINO_RUN_STATUS=$(echo "$RESPONSE" | jq -r '.status')
}

# Runs a Domino batch job using an API call and waits for the job to finish
# Expects COMMAND argument to run in Domino batch job
function domino_job_run {
    DOMINO_RUN_ID=0
    DOMINO_RUN_STATUS=""
    COMMAND=$(echo "[\"$(echo "${1}" | sed 's/ /", "/g')\"]")

    echo "Running on Domino (${DOMINO_PROJECT_OWNER}/${DOMINO_PROJECT_NAME}): $1"
    PAYLOAD="{\"command\": $COMMAND, \"title\": \"${2}\", \"isDirect\": false}"
    RESPONSE=$(curl ${DOMINO_API_HOST}/v1/projects/${DOMINO_PROJECT_OWNER}/${DOMINO_PROJECT_NAME}/runs -s -H "X-Domino-Api-Key: ${DOMINO_USER_API_KEY}" -H 'Content-Type: application/json' -d "${PAYLOAD}")
    DOMINO_RUN_ID=$(echo "$RESPONSE" | jq -r '.runId')

    echo "Run $DOMINO_RUN_ID has started. Waiting for the run to complete."

    while true; do
        sleep 5
        domino_job_status $DOMINO_RUN_ID
        
        if [[ "$DOMINO_RUN_STATUS" == "Succeeded" ]]; then break; fi
        if [[ "$DOMINO_RUN_STATUS" == "Failed" ]]; then
            echo "Run $DOMINO_RUN_ID has failed. Please see the run logs."
            echo "Stopping the remainder of this job from running"
            exit 1
        fi
    done
    
    echo "Run $DOMINO_RUN_ID has completed"
}

# Step 1: Retrain model
echo "Retraining model..."
domino_job_run "train_model.py" "[Lifecycle.sh] Retraining Model"

# Step 2: Deploy Model as Domino Model API
echo "Deploying model as a Domino Model API..."
domino_job_run "deploy_model.sh $PROJECT_ID $MODEL_ID $MODEL_FILE $MODEL_FUNCTION" "[Lifecycle.sh] Deploying Model to Domino"

# Step 3: Test Model API Endpoint to validate results
echo "Testing Domino Model API Endpoint..."
domino_job_run "test_model.sh $MODEL_ID" "[Lifecycle.sh] Test Model"

# Step 4: Publish model to ECR
echo "Pushing model API endpoint to AWS Elastic Container Registry..."
domino_job_run "export_model.sh $MODEL_ID" "[Lifecycle.sh] Publish Model to ECR"

# Step 5: Run model on production server
echo "Running model on production EC2 server..."
#bash production.sh
