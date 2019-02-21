#/bin/bash

set -x

REPO_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# use project and region from your current setup
export PROJECT=$(gcloud config get-value core/project)
export REGION=$(gcloud config get-value compute/region)

# Store the service account email address and your current project ID in environment variable
export SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:spinnaker-account" \
    --format='value(email)')

# delete the helm chart
helm delete --purge spin || 'echo helm chart deletion failed'
kubectl delete ns spin && sleep 10

# release spinnaker static ip
#gcloud compute addresses delete spinnaker-ip --region $REGION --quiet
#gcloud compute addresses delete spinnaker-api-ip --region $REGION --quiet

# remove policy binding spinnaker SA <--> Storage.admin
gcloud projects remove-iam-policy-binding \
    $PROJECT --role roles/storage.admin --member serviceAccount:$SA_EMAIL

# delete Spinnaker SA
gcloud iam service-accounts delete ${SA_EMAIL} --quiet

# remove spinnaker helm config
rm "${REPO_HOME}/helm/spinnaker-config.yaml"

# delete the GCS bucket 
export BUCKET=$PROJECT-spinnaker-config
gsutil rm -r gs://$BUCKET
