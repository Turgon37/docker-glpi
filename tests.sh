#!/usr/bin/env bash


## Initialization
set -e

image_building_name=`cat ${PWD}/_image_build`
docker_run_options='--detach'


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

# Download tools shim.
if [[ ! -f _tools.sh ]]; then
  curl -L -o ${PWD}/_tools.sh https://gist.github.com/Turgon37/2ba8685893807e3637ea3879ef9d2062/raw
fi
source ${PWD}/_tools.sh


## Test
container-structure-test \
    test --image "${image_building_name}" --config ./tests.yml


#2 Test plugins installation with tar.bz2
echo '-> 2 Test plugins installation with tar.bz2'
image_name=glpi_2
docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.3%2B1.1/fusioninventory-9.3.1.1.tar.bz2' "${image_building_name}"
wait_for_string_in_container_logs "${image_name}" 'Starting up...'
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
wait_for_string_in_container_logs "${image_name}" 'Starting up...'
# test
if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"


#4 Test plugins installation with old variable
echo '-> 4 Test plugins installation with old variable'
image_name=glpi_4
docker run $docker_run_options --name "${image_name}" --env='GLPI_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9  .3%2B1.2/fusioninventory-9.3+1.2.tar.gz' "${image_building_name}"
wait_for_string_in_container_logs "${image_name}" 'Starting up...'
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
