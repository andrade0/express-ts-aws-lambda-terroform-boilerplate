#!/bin/bash

PACKAGE_VERSION=$(cat nodejs/package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')

FUNCTION_NAME=$(cat nodejs/package.json \
  | grep name \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",]//g' \
  | tr -d '[[:space:]]')

bucket=andrade0-bucket
key=v$PACKAGE_VERSION/lambda.zip

object_exists=$(aws s3api head-object --bucket $bucket --key $key || true)
if [ -z "$object_exists" ]; then
  rm -rf ./code
  rm ./lambda.zip
  mkdir ./code
  cp -r nodejs code/nodejs
  zip -r ./lambda.zip code/*
  aws s3 cp ./lambda.zip s3://$bucket/$key
  ./terraform apply -var="app_version=$PACKAGE_VERSION" -auto-approve
  rm -rf ./code
  rm ./lambda.zip
else
  echo "version already exists, please change version in package.json"
fi




