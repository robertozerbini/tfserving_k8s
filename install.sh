#!/bin/bash

#Variables
gcloud config set compute/zone us-central1-f
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME=my-cluster
APP_NAME=tfserving
ZONE=us-central1-f
ACCOUNT=$(gcloud config list account --format "value(core.account)")
NUM_NODES=1

sed -i -- 's/<PROJECT_ID>/'"$PROJECT_ID"'/g' tfserving_deployment.yaml
sed -i -- 's/<APP_NAME>/'"$APP_NAME"'/g' tfserving_deployment.yaml

gcloud services enable container.googleapis.com

#create cluster
gcloud beta container clusters create $CLUSTER_NAME \
  --project=$PROJECT_ID \
  --cluster-version=latest \
  --machine-type=e2-medium \
  --num-nodes=$NUM_NODES \
  --region=$ZONE

#get tfserving image
docker pull tensorflow/serving

docker tag tensorflow/serving  gcr.io/$PROJECT_ID/$APP_NAME

docker push gcr.io/$PROJECT_ID/$APP_NAME

#get resnet
wget https://tfhub.dev/tensorflow/resnet_50/classification/1?tf-hub-format=compressed -O resnet.tar.gz
mkdir -p /tmp/resnet/123
tar xvfz resnet.tar.gz -C /tmp/resnet/123/

#deploy
kubectl apply -f  tfserving_volume.yaml
kubectl apply -f  tfserving_configmap.yaml
kubectl apply -f  tfserving_deployment.yaml
kubectl apply -f  tfserving_service.yaml

POD_NAME=($(kubectl get pods  --selector=app=tensorflowserving | awk 'NR>1 { printf sep $1; sep=" "}'))
#copy model
kubectl cp /tmp/resnet $POD_NAME:/models/