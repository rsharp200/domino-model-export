import os
import requests
import boto3
import json
import pandas as pd
from datetime import datetime
from time import sleep
import pprint

import domino_export

# Set up Domino API Credentials
dominoAPIHost = os.environ["DOMINO_API_HOST"].strip()
dominoAPIKey = os.environ["DOMINO_USER_API_KEY"].strip()
dominoUserName = os.environ["DOMINO_PROJECT_OWNER"].strip()
dominoProjectName = os.environ["DOMINO_PROJECT_NAME"].strip()

# AWS ECR Configuration
ecr_region = "us-west-2"
ecrRepository = "domino-model-exports"

