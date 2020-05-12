#!/bin/bash

PACKAGE_VERSION=$(cat package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')

FUNCTION_NAME=$(cat package.json \
  | grep name \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')

bucket=andrade0-bucket
key=v$PACKAGE_VERSION/nodejs.zip

object_exists=$(aws s3api head-object --bucket $bucket --key $key || true)
if [ -z "$object_exists" ]; then
  zip ./nodejs.zip main.js package.json node_modules/* app/*
  aws s3 cp ./nodejs.zip s3://$bucket/$key
  ./terraform apply -var="app_version=$PACKAGE_VERSION" -auto-approve
else
  echo "version already exists, please change version in package.json"
fi




