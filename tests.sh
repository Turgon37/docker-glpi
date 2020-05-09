#!/usr/bin/env bash

## Global settings
# image name
DOCKER_IMAGE="${DOCKER_REPO:-glpi}"

## Initialization
set -e

if [[ -n ${IMAGE_VARIANT} ]]; then
  image_building_name="${DOCKER_IMAGE}:building_${IMAGE_VARIANT}"
  echo "-> set image variant '${IMAGE_VARIANT}' for build"
else
  image_building_name="${DOCKER_IMAGE}:building"
fi
docker_run_options='--detach'
# string that proove that container is up
container_up_string='GET /fpm-ping'
echo "-> use image name '${image_building_name}' for tests"


## Prepare
if [[ -z $(command -v container-structure-test 2>/dev/null) ]]; then
  echo "Retrieving structure-test binary...."
  if [[ -n "${TRAVIS_OS_NAME}" && "$TRAVIS_OS_NAME" != 'linux' ]]; then
    echo "container-structure-test only released for Linux at this time."
    echo "To run on OSX, clone the repository and build using 'make'."
    exit 1
  else
    curl -sSLO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 \
    && chmod +x container-structure-test-linux-amd64 \
    && mv container-structure-test-linux-amd64 container-structure-test
  fi
fi

# Download tools shim.
if [[ ! -f _tools.sh ]]; then
  curl -L -o "${PWD}/_tools.sh" https://gist.github.com/Turgon37/2ba8685893807e3637ea3879ef9d2062/raw
fi
# shellcheck disable=SC1090
source "${PWD}/_tools.sh"


## Test

# shell scripts tests
# shellcheck disable=SC2038
find . -name '*.sh' | xargs shellcheck docker-entrypoint.d/*

# Image tests
./container-structure-test \
    test --image "${image_building_name}" --config ./tests.yml

## Ensure that required php extensions are installed
extensions=$(docker run --rm "${image_building_name}" php -m)
for ext in apcu \
           ctype \
           curl \
           dom \
           gd \
           imap \
           json \
           ldap \
           mysqli \
           openssl \
           opcache \
           soap \
           xml \
           xmlreader \
           xmlrpc \
           zlib; do
  if ! echo "${extensions}" | grep -qi $ext; then
    echo "missing PHP extension '$ext'" 1>&2
    exit 1
  fi
done


#2 Test plugins installation with tar.bz2
echo '-> 2 Test plugins installation with tar.bz2'
image_name=glpi_2
docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.3%2B1.1/fusioninventory-9.3.1.1.tar.bz2' "${image_building_name}"
wait_for_string_in_container_logs "${image_name}" "${container_up_string}"
# test
if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"


#3 Test plugins installation with tar.gz
echo '-> 3 Test plugins installation with tar.gz'
image_name=glpi_3
docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.3%2B1.2/fusioninventory-9.3+1.2.tar.gz' "${image_building_name}"
wait_for_string_in_container_logs "${image_name}" "${container_up_string}"
# test
if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"


#5 Test web access
echo '-> 5 Test web access'
image_name=glpi_5
docker run $docker_run_options --name "${image_name}" --publish 8000:80 "${image_building_name}"
wait_for_string_in_container_logs "${image_name}" 'nginx entered RUNNING state'
sleep 5
# test
if ! curl -v http://localhost:8000 2>&1 | grep --quiet 'install/install.php'; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"


#6 Test plugins installation with zip
echo '-> 6 Test plugins installation with zip'
image_name=glpi_6
docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=timezones|https://github.com/tomolimo/timezones/releases/download/2.4.1/timezones-2.4.1.zip' "${image_building_name}"
wait_for_string_in_container_logs "${image_name}" "${container_up_string}"
# test
if ! docker exec "${image_name}" test -d plugins/timezones; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"
