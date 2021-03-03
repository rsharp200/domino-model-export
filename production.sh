#!/bin/bash

set -e

ECR_REGISTRY="573040241134.dkr.ecr.us-west-2.amazonaws.com/domino-model-exports"

# Login into ECR Docker Registry
echo "Logging into the ECR Docker Registry"
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull Docker Image
docker pull 573040241134.dkr.ecr.us-west-2.amazonaws.com/domino-model-exports:domino-igor_marchenko-ModelExportPipeline-603a943ecc42014cc2ddda51-2