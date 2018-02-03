#!/usr/bin/env bash

# GLOBAL SETTINGS
# docker hub username
DOCKER_USERNAME="${DOCKER_USERNAME:-turgon37}"
# image name
DOCKER_IMAGE="${DOCKER_USERNAME}/${DOCKER_IMAGE:-glpi}"

# If empty version, fetch the latest from repository
if [ -z "$GLPI_VERSION" ]; then
  GLPI_VERSION=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases | jq --raw-output '.[] | .tag_name' | sort --reverse | grep --max-count=1 --invert-match RC)
fi
echo "-> selected GLPi version ${GLPI_VERSION}"

image_version=`cat VERSION`
echo "-> building ${DOCKER_IMAGE} with image version: ${image_version}"

docker build --build-arg IMAGE_VERSION="$image_version" \
             --build-arg GLPI_VERSION="$GLPI_VERSION" \
             --tag ${DOCKER_IMAGE}:${GLPI_VERSION} \
             --file Dockerfile \
             .
