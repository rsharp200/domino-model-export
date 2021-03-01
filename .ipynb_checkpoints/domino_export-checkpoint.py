import os
import boto3
import json
import requests

class DominoExport():
    def __init__(
        self,
        domino_api_host = os.environ["DOMINO_API_HOST"].strip(),
        domino_api_key = os.environ["DOMINO_USER_API_KEY"].strip(),
        domino_user_name = os.environ["DOMINO_PROJECT_OWNER"].strip(),
        domino_project_name = os.environ["DOMINO_PROJECT_NAME"].strip()
    ):
        self.domino_api_host = domino_api_host
        self.domino_api_key = domino_api_key
        self.domino_user_name = domino_user_name
        self.domino_project_name = domino_project_name
    
    

    # Generate ECR login details for Domino's API
    def generate_ecr_push_details(self, ecr_region, repository, tag):
        from base64 import b64decode

        ecrAccount = boto3.client("sts", region_name=ecr_region).get_caller_identity().get("Account")
        ecrToken = boto3.client("ecr", region_name=ecr_region).get_authorization_token(registryIds=[ecrAccount])
        ecrRegistry = ecrToken["authorizationData"][0]["proxyEndpoint"].lstrip("https://").lstrip("http://")
        ecrAuth = b64decode(ecrToken["authorizationData"][0]["authorizationToken"]).decode("utf-8").split(":")

        pushData = {
            "registryUrl": ecrRegistry,
            "repository": repository,
            "tag": tag,
            "username": ecrAuth[0],
            "password": ecrAuth[1]
        }

        return pushData

    # Domino API Request Base Method to simplify making Domino API calls
    def domino_request(self, urlPath, requestType, json = None):
        url = "{DOMINO_HOST}{URL_PATH}".format(
            DOMINO_HOST = self.domino_api_host,
            URL_PATH = urlPath
        )

        session = requests.Session()
        session.headers.update({
            "X-Domino-Api-Key": self.domino_api_key,
            "Content-Type": "application/json",
            "Accept": "application/json"
        })
        response = None
        if requestType == "GET":
            response = session.get(url)
        elif requestType == "POST":
            response = session.post(url, json = json)

        response.raise_for_status()

        return response

    # Domino API Wrapper for /v4/models/<MODEL_ID>/<MODEL_VERSION_ID>/exportImageToRegistry
    # This API request exports a Domino model to ECR
    def domino_ecr_export(self, ecr_region, ecr_repository, modelID, modelVersion):
        modelVersionID = next(iter([modelVersionInfo.get("_id", None) for modelVersionInfo in self.domino_model_versions(modelID) if modelVersionInfo.get("metadata", {}).get("number", None) == modelVersion]), None)
        exportStatus = None

        if modelVersionID:
            urlPath = "/v4/models/{MODEL_ID}/{MODEL_VERSION_ID}/exportImageToRegistry".format(
                MODEL_ID = modelID,
                MODEL_VERSION_ID = modelVersionID
            )

            exportTag = "domino-{USERNAME}-{PROJECT_NAME}-{MODEL_ID}-{MODEL_VERSION}".format(
                USERNAME = self.domino_user_name,
                PROJECT_NAME = self.domino_project_name,
                MODEL_ID = modelID,
                MODEL_VERSION = modelVersion
            )

            jsonData = self.generate_ecr_push_details(ecr_region, ecr_repository, exportTag)

            exportStatus = json.loads(self.domino_request(urlPath, "POST", jsonData).text)
            exportStatus["tag"] = exportTag
            exportStatus["url"] = "https://{REGISTRY_URL}/{REPOSITORY}:{TAG}".format(
                REGISTRY_URL = jsonData["registryUrl"],
                REPOSITORY = jsonData["repository"],
                TAG = jsonData["tag"]
            )

        return exportStatus
    
    # Domino API Wrapper for /v4/models/<MODEL_ID>/<MODEL_VERSION_ID>/exportImageForSagemaker
    # This API request exports a Domino model to ECR as a SageMaker compatible format
    def domino_sagemaker_export(self, ecr_region, ecr_repository, modelID, modelVersion):
        modelVersionID = next(iter([modelVersionInfo.get("_id", None) for modelVersionInfo in self.domino_model_versions(modelID) if modelVersionInfo.get("metadata", {}).get("number", None) == modelVersion]), None)
        exportStatus = None

        if modelVersionID:
            urlPath = "/v4/models/{MODEL_ID}/{MODEL_VERSION_ID}/exportImageForSagemaker".format(
                MODEL_ID = modelID,
                MODEL_VERSION_ID = modelVersionID
            )

            exportTag = "domino-{USERNAME}-{PROJECT_NAME}-{MODEL_ID}-{MODEL_VERSION}".format(
                USERNAME = self.domino_user_name,
                PROJECT_NAME = self.domino_project_name,
                MODEL_ID = modelID,
                MODEL_VERSION = modelVersion
            )

            jsonData = self.generate_ecr_push_details(ecr_region, ecr_repository, exportTag)

            exportStatus = json.loads(self.domino_request(urlPath, "POST", jsonData).text)
            exportStatus["tag"] = exportTag
            exportStatus["url"] = "https://{REGISTRY_URL}/{REPOSITORY}:{TAG}".format(
                REGISTRY_URL = jsonData["registryUrl"],
                REPOSITORY = jsonData["repository"],
                TAG = jsonData["tag"]
            )

        return exportStatus

    ## The following API calls are not required to publish a Domino model to ECR, but are going to be useful to list all of the running models for this Domino project

    # Domino API Wrapper for /v1/projects/<USERNAME>/<PROJECT_NAME>/models
    # This API Request returns all of the models associated with a particular Domino project
    def domino_project_models(self):
        urlPath = "/v1/projects/{USERNAME}/{PROJECT_NAME}/models".format(
            USERNAME = self.domino_user_name,
            PROJECT_NAME = self.domino_project_name
        )

        return json.loads(self.self.domino_request(urlPath, "GET").text).get("data", [])

    # Domino API Wrapper for /v1/models/<MODEL_ID>/versions
    # This API requests returns all of the Domino model versions for a particular model
    def domino_model_versions(self, modelID):
        urlPath = "/v1/models/{MODEL_ID}/versions".format(
            MODEL_ID = modelID
        )

        return json.loads(self.domino_request(urlPath, "GET").text).get("data", [])

    # Domino API Wrapper for /v4/models/<EXPORT_ID>/getExportLogs
    # This API requests get the logs for a Domino model export
    def domino_model_export_logs(self, exportID):
        urlPath = "/v4/models/{EXPORT_ID}/getExportLogs".format(
            EXPORT_ID = exportID
        )

        return json.loads(json.loads(self.domino_request(urlPath, "GET").text).get("logs", None))

    # Domino API Wrapper for /v4/models/<EXPORT_ID>/getExportImageStatus
    # This API request gets that status of a Domino model export
    def domino_model_export_status(self, exportID):
        urlPath = "/v4/models/{EXPORT_ID}/getExportImageStatus".format(
            EXPORT_ID = exportID
        )

        return json.loads(self.domino_request(urlPath, "GET").text)