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

bucket=$FUNCTION_NAME-andrade0
key=v$PACKAGE_VERSION/lambda.zip

object_exists=$(aws s3api head-object --bucket $bucket --key $key || true)
if [ -z "$object_exists" ]; then
  cd nodejs
  npm i
  npm run deploy
  cd ..
  terraform apply -var="app_version=$PACKAGE_VERSION" -var="function_name=$FUNCTION_NAME" -auto-approve
  rm -rf ./code
  rm ./lambda.zip
else
  echo "version already exists, please change version in package.json"
fi




