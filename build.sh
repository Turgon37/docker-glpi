#!/usr/bin/env -S bash -x

## Global settings
# image name
DOCKER_IMAGE="${DOCKER_REPO:-glpi}"
# use dockefile
DOCKERFILE_PATH="Dockerfile_${IMAGE_VARIANT}"

## Initialization
set -e

# If empty version, fetch the latest from repository
if [ -z "$GLPI_VERSION" ]; then
  GLPI_VERSION=`curl --fail -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep --perl-regexp --only-matching '(?<=tag_name": ")[a-z0-9.-]+'`
  if [ $? -ne 0 ]; then
    echo 'Error during fetch last glpi version'
    exit 1
  fi
  test -n "$GLPI_VERSION"
fi
echo "-> selected GLPI version '${GLPI_VERSION}'"

# If empty commit, fetch the current from local git rpo
if [ -n "${SOURCE_COMMIT}" ]; then
  VCS_REF="${SOURCE_COMMIT}"
elif [ -n "${TRAVIS_COMMIT}" ]; then
  VCS_REF="${TRAVIS_COMMIT}"
else
  VCS_REF="`git rev-parse --short HEAD`"
fi
test -n "${VCS_REF}"
echo "-> current vcs reference '${VCS_REF}'"

# Get the current image static version
image_version=`cat VERSION`
echo "-> use image version '${image_version}'"

# Compute variant from dockerfile name
if ! [ -f ${DOCKERFILE_PATH} ]; then
  echo 'You must select a valid dockerfile with DOCKERFILE_PATH' 1>&2
  exit 1
fi
if [ -n ${IMAGE_VARIANT} ]; then
  image_building_name="${DOCKER_IMAGE}:building_${IMAGE_VARIANT}"
  echo "-> set image variant '${IMAGE_VARIANT}' for build"
else
  image_building_name="${DOCKER_IMAGE}:building"
fi
echo "-> use image name '${image_building_name}' for build"

## Build image
echo "=> building '${image_building_name}' with image version '${image_version}'"
docker build --build-arg "GLPI_VERSION=${GLPI_VERSION}" \
             --label "org.label-schema.build-date=`date -u +'%Y-%m-%dT%H:%M:%SZ'`" \
             --label 'org.label-schema.name=glpi' \
             --label 'org.label-schema.description=GLPI web application' \
             --label 'org.label-schema.url=https://github.com/Turgon37/docker-glpi' \
             --label "org.label-schema.vcs-ref=${VCS_REF}" \
             --label 'org.label-schema.vcs-url=https://github.com/Turgon37/docker-glpi' \
             --label 'org.label-schema.vendor=Pierre GINDRAUD' \
             --label "org.label-schema.version=${image_version}" \
             --label 'org.label-schema.schema-version=1.0' \
             --label "application.glpi.version=${GLPI_VERSION}" \
             --tag "${image_building_name}" \
             --file "${DOCKERFILE_PATH}" \
             .
