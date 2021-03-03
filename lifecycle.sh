#!/bin/bash

export DOMINO_API_HOST="https://demo.dominodatalab.com"
export DOMINO_USER_API_KEY="50266f49641af73f99a174c4d66e002560bda79b227216c8262795bd48942fc1"
export DOMINO_PROJECT_NAME="ModelExportPipeline"
export DOMINO_PROJECT_OWNER="igor_marchenko"

export PROJECT_ID="603a915f5269971ee08c1e40"
export MODEL_ID="603a943ecc42014cc2ddda51"
export MODEL_FILE="predict.py"
export MODEL_FUNCTION="predict"

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
    echo $RESPONSE
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
domino_job_run "test_model.sh" "[Lifecycle.sh] Test Model"

# Step 4: Publish model to ECR
echo "Pushing model API endpoint to AWS Elastic Container Registry..."
domino_job_run "export_model.sh $MODEL_ID" "[Lifecycle.sh] Publish Model to ECR"

# Step 5: Run model on production server
echo "Running model on production EC2 server..."
#bash production.sh