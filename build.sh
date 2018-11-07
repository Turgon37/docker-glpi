#!/usr/bin/env bash

## Global settings
# docker hub username
DOCKER_USERNAME="${DOCKER_USERNAME:-wolvverine}"
# image name
DOCKER_IMAGE="${DOCKER_USERNAME}/${DOCKER_IMAGE:-glpi}"
# "production" branch
MASTER_BRANCH=${MASTER_BRANCH:-master}

## Local settings
build_tags_file="${PWD}/build.sh~tags"
docker_tag_prefix=

## Settings initialization
set -e
set -v

# If empty version, fetch the latest from repository
if [ -z "$GLPI_VERSION" ]; then
#TODO - sort version
  GLPI_VERSION=`curl -s https://api.github.com/repos/glpi-project/glpi/releases | jq --raw-output '.[] | .tag_name' | sort --reverse | grep --max-count=1 --invert-match RC`
  if [ -z "$DOCKER_IMAGE_TAGS" ]; then
    DOCKER_IMAGE_TAGS="${DOCKER_IMAGE_TAGS} latest"
  fi
fi
echo "-> selected GLPi version ${GLPI_VERSION}"

# If empty version, fetch the latest from repository
if [ -z "$VCS_REF" ]; then
  VCS_REF=`git rev-parse --short HEAD`
fi
echo "-> current vcs reference ${VCS_REF}"

# Set the docker image tag prefix
if [ "${VCS_BRANCH}" != "${MASTER_BRANCH}" ]; then
  docker_tag_prefix="${VCS_BRANCH}-"
fi
echo "-> working with tags prefix ${docker_tag_prefix}"

echo "-> working with tags ${DOCKER_IMAGE_TAGS}"

image_version=`cat VERSION`
echo "-> building ${DOCKER_IMAGE} with image version: ${image_version}"

## Build image
docker build --build-arg VCS_REF="${VCS_REF}" \
             --build-arg IMAGE_VERSION="$image_version" \
             --build-arg GLPI_VERSION="$GLPI_VERSION" \
             --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
             --tag "${DOCKER_IMAGE}:${docker_tag_prefix}${GLPI_VERSION}" \
             --file Dockerfile \
             .

## Image taaging
echo "${DOCKER_IMAGE}:${docker_tag_prefix}${GLPI_VERSION}" > ${build_tags_file}

# Tag images
for tag in $DOCKER_IMAGE_TAGS; do
  if [ -n "$tag" ]; then
    docker tag "${DOCKER_IMAGE}:${docker_tag_prefix}${GLPI_VERSION}" "${DOCKER_IMAGE}:${docker_tag_prefix}${tag}"
    echo "${DOCKER_IMAGE}:${docker_tag_prefix}${tag}" >> ${build_tags_file}
  fi
done

echo "-> produced following image names"
cat "${build_tags_file}"
