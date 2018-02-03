#!/usr/bin/env bash

## Local settings
build_tags_file="${PWD}/build.sh~tags"

## Init conditions


## Deploy
# Authenticate to docker hub
echo "$DOCKERHUB_REGISTRY_PASSWORD" | docker login --username="$DOCKERHUB_REGISTRY_USERNAME" --password-stdin

# push each built images
for image in `cat "${build_tags_file}"`; do
  echo "-> push ${image}"
  #docker push $image
done

# Unauthenticate to docker hub
docker logout
