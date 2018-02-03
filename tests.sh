#!/usr/bin/env bash

## Local settings
build_tags_file="${PWD}/build.sh~tags"

## Settings initialization
set -e

## Tests

# Test build successful
[ -f "${build_tags_file}" ]

# Get main image
image=`head --lines=1 "${build_tags_file}"`

# Test if GLPI successfully installed
docker run --rm "${image}" test -f index.php
