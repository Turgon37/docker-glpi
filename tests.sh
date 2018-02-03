#!/usr/bin/env bash

## Local settings
build_tags_file="${PWD}/build.sh~tags"
docker_run_options='--detach --rm'

## Settings initialization
set -e
set -x

## Tests

#1 Test build successful
[ -f "${build_tags_file}" ]

# Get main image
image=`head --lines=1 "${build_tags_file}"`

#2 Test if GLPI successfully installed
image_name=glpi_2
docker run $docker_run_options --name "${image_name}" "${image}" test -f index.php

#3 Test plugins installation with tar.bz2
image_name=glpi_3
docker run $docker_run_options --name "${image_name}" --env='GLPI_INSTALL_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.2%2B1.0/glpi-fusioninventory-9.2.1.0.tar.bz2' "${image}"
if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
  docker logs "${image_name}"
  false
fi
docker stop "${image_name}"

#4 Test plugins installation with tar.gz
image_name=glpi_4
docker run $docker_run_options --name "${image_name}" --env='GLPI_PLUGINS=fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.1%2B1.1/fusioninventory-for-glpi_9.1.1.1.tar.gz' "${image}"
if ! docker exec "${image_name}" test -d plugins/fusioninventory; then
  docker logs "${image_name}"
  false
fi
docker stop "${image_name}"

#5 Test web access
image_name=glpi_5
docker run $docker_run_options --name "${image_name}" --publish 8000:80 "${image}"
if ! curl -v http://localhost:8000 | grep --quiet 'install/install.php'; then
  docker logs "${image_name}"
  false
fi
docker stop "${image_name}"
