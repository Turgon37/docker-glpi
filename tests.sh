#!/usr/bin/env bash

## Local settings
build_tags_file="${PWD}/build.sh~tags"
docker_run_options='--detach'
docker_wait_for_logs_default_attempt=5

## Define tools
# Wait for a container to be up by checking regularly its logs for a pattern
# param1 : the container name
# param2 : the string to search for in logs
function wait_for_string_in_container_logs() {
  [ -n "${1}" -a -n "${2}" ]
  attempt=0
  while [ $attempt -le $docker_wait_for_logs_default_attempt ]; do
    attempt=$(( $attempt + 1 ))
    echo "-> Waiting for container "${1}" to be up (attempt: ${attempt})..."
    if docker logs "$1" | grep --quiet 'Starting up...'; then
      echo "-> Container ${1} is up"
      break
    fi
    sleep 4
  done
}

# Stop and remove properly a container
# param1 : the container name
function stop_and_remove_container() {
  [ -n "${1}" ]
  docker stop "${1}" > /dev/null
  docker rm --volumes "${1}" > /dev/null
  echo "-> Container ${1} is stopped and removed"
}

## Settings initialization
set -e
set -x

## Tests

#1 Test build successful
echo '-> 1 Test build successful'
[ -f "${build_tags_file}" ]

# Get main image
echo '-> Get main image'
image=`head --lines=1 "${build_tags_file}"`

#2 Test if GLPI successfully installed
echo '-> 2 Test if GLPI successfully installed'
image_name=glpi_2
docker run --rm $docker_run_options --name "${image_name}" "${image}" test -f index.php

#3 Test plugins installation with tar.bz2
echo '-> 3 Test plugins installation with tar.bz2'
image_name=glpi_3
docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.2%2B1.0/glpi-fusioninventory-9.2.1.0.tar.bz2' "${image}"
wait_for_string_in_container_logs "${image_name}" 'Starting up...'
if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"


#4 Test plugins installation with tar.gz
echo '-> 4 Test plugins installation with tar.gz'
image_name=glpi_4
docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.1%2B1.1/fusioninventory-for-glpi_9.1.1.1.tar.gz' "${image}"
wait_for_string_in_container_logs "${image_name}" 'Starting up...'
#test
if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"


#5 Test plugins installation with old variable
echo '-> 5 Test plugins installation with old variable'
image_name=glpi_5
docker run $docker_run_options --name "${image_name}" --env='GLPI_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.1%2B1.1/fusioninventory-for-glpi_9.1.1.1.tar.gz' "${image}"
wait_for_string_in_container_logs "${image_name}" 'Starting up...'
#test
if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"


#6 Test web access
echo '-> 6 Test web access'
image_name=glpi_6
docker run $docker_run_options --name "${image_name}" --publish 8000:80 "${image}"
wait_for_string_in_container_logs "${image_name}" 'nginx entered RUNNING state'
#test
if ! curl -v http://localhost:8000 | grep --quiet 'install/install.php'; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"
