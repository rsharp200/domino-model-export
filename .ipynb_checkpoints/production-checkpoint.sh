#!/bin/bash

set -e

ECR_REGISTRY="573040241134.dkr.ecr.us-west-2.amazonaws.com/domino-model-exports"

# Login into ECR Docker Registry
echo "Logging into the ECR Docker Registry"
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull Docker Image
docker pull 573040241134.dkr.ecr.us-west-2.amazonaws.com/domino-model-exports:domino-igor_marchenko-ModelExportPipeline-603a943ecc42014cc2ddda51-2

# Run Docker Image
DOCKER_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep ModelExportPipeline | sort | head -n 1)
docker run -p 8888:8080 -d -t $DOCKER_IMAGE