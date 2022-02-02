/bin/bash

gcloud config set compute/zone us-central1-f
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME=my-cluster
APP_NAME=tfserving
ZONE=us-central1-f
ACCOUNT=$(gcloud config list account --format "value(core.account)")
NUM_NODES=1

gcloud services enable container.googleapis.com


gcloud beta container clusters create $CLUSTER_NAME \
  --project=$PROJECT_ID \
  --cluster-version=latest \
  --machine-type=e2-medium \
  --num-nodes=$NUM_NODES \
  --region=$ZONE

docker pull tensorflow/serving

docker tag tensorflow/serving  gcr.io/$PROJECT_ID/$APP_NAME

docker push gcr.io/$PROJECT_ID/$APP_NAME
