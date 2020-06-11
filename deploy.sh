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

cd nodejs
npm i
npm run deploy
cd ..
terraform apply -var="app_version=$PACKAGE_VERSION" -var="function_name=$FUNCTION_NAME" -auto-approve
rm ./nodejs/dist/dist.zip






