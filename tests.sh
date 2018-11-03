#!/usr/bin/env bash


## Initialization
set -e

image_building_name=`cat ${PWD}/_image_build`


## Prepare
if [[ -z $(which container-structure-test 2>/dev/null) ]]; then
  echo "Retrieving structure-test binary...."
  if [[ "$TRAVIS_OS_NAME" != 'linux' ]]; then
    echo "container-structure-test only released for Linux at this time."
    echo "To run on OSX, clone the repository and build using 'make'."
    exit 1
  else
    curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 \
    && chmod +x container-structure-test-linux-amd64 \
    && sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
  fi
fi


## Test
container-structure-test \
    test --image "${image_building_name}" --config ./tests.yml



##3 Test plugins installation with tar.bz2
#echo '-> 3 Test plugins installation with tar.bz2'
#image_name=glpi_3
#docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.2%2B1.0/glpi-fusioninventory-9.2.1.0.tar.bz2' "${image}"
#wait_for_string_in_container_logs "${image_name}" 'Starting up...'
#if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
#  docker logs "${image_name}"
#  false
#fi
#stop_and_remove_container "${image_name}"
#
#
##4 Test plugins installation with tar.gz
#echo '-> 4 Test plugins installation with tar.gz'
#image_name=glpi_4
#docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.1%2B1.1/fusioninventory-for-glpi_9.1.1.1.tar.gz' "${image}"
#wait_for_string_in_container_logs "${image_name}" 'Starting up...'
##test
#if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
#  docker logs "${image_name}"
#  false
#fi
#stop_and_remove_container "${image_name}"
#
#
##5 Test plugins installation with old variable
#echo '-> 5 Test plugins installation with old variable'
#image_name=glpi_5
#docker run $docker_run_options --name "${image_name}" --env='GLPI_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.1%2B1.1/fusioninventory-for-glpi_9.1.1.1.tar.gz' "${image}"
#wait_for_string_in_container_logs "${image_name}" 'Starting up...'
##test
#if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
#  docker logs "${image_name}"
#  false
#fi
#stop_and_remove_container "${image_name}"
#
#
##6 Test web access
#echo '-> 6 Test web access'
#image_name=glpi_6
#docker run $docker_run_options --name "${image_name}" --publish 8000:80 "${image}"
#wait_for_string_in_container_logs "${image_name}" 'nginx entered RUNNING state'
#sleep 4
##test
#if ! curl -v http://localhost:8000 2>&1 | grep --quiet 'install/install.php'; then
#  docker logs "${image_name}"
#  false
#fi
#stop_and_remove_container "${image_name}"
