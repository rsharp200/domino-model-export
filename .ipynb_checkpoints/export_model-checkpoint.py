from time import sleep
import pprint
from domino_export import DominoExport

# Set up Domino Export API
domino_model_id = "603a943ecc42014cc2ddda51"
domino_export = DominoExport()

# AWS ECR Configuration
ecr_region = "us-west-2"
ecr_repository = "domino-model-exports"

# Export model
domino_model_latest = sorted(
    domino_export.domino_model_versions(domino_model_id),
    key=lambda i: i.get('metadata', {}).get('number', None),
    reverse=True
)[0]['metadata']['number']

model_export = domino_export.domino_ecr_export(ecr_region, ecr_repository, domino_model_id, domino_model_latest)

# How often, in seconds, to check the status of the model export
SLEEP_TIME_SECONDS = 10

while model_export:
    status = domino_export.domino_model_export_status(model_export["exportId"]).get("status", None)
    if status:
        print(status)

        if status not in ["complete", "failed"]:
            sleep(SLEEP_TIME_SECONDS)
        else:
            break

logs = domino_export.domino_model_export_logs(model_export["exportId"])
pprint.pprint(logs)