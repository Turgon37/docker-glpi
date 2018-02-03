#!/bin/sh

set -e

basedir="${GLPI_ROOT}"

## Install plugins

# Install a plugin
# param1: the name of the plugin (directory)
# param2: the url to download the plugin from
function installPlugin() {
  plugin="${1}"
  url="${2}"
  file="$(basename "$url")"

  # continue if plugin already installed
  if [ -d "$plugin" ]; then
    echo "..plugin ${plugin} already installed"
    continue
  fi
  # Download plugin source if not exists
  if [ ! -f "${file}" ]; then
    echo "..downloading plugin '${plugin}' from '${url}'"
    curl -o "${file}" -L "${url}"
  fi

  # extract the archive according to the extension
  echo "..extracting plugin '${file}'"
  case "$file" in
    *.tar.gz)
      tar xzf "${file}"
      ;;
    *.tar.bz2)
      tar xjf "${file}"
      ;;
    *)
      echo "..#ERROR# unknown extension for ${file}. Please open an issue or make a PR to https://github.com/Turgon37/docker-glpi" 1>&2
      false
      ;;
  esac
  if [ $? -ne 0 ]; then
    echo "..#ERROR# failed to extract plugin ${plugin}" 1>&2
    continue
  fi

  # remove source and set file permissions
  rm -f "${file}"
  chown -R www-data:www-data "${plugin}"
  chmod -R g=rX,o=--- "${plugin}"
}


echo "Installing plugins... in ${GLPI_PATHS_PLUGINS}"
cd "${GLPI_PATHS_PLUGINS}" > /dev/null

# Use the new syntax
if [ ! -z "${GLPI_INSTALL_PLUGINS}" ]; then
  OLDIFS=$IFS
  IFS=','
  for item in ${GLPI_INSTALL_PLUGINS}; do
    IFS=$OLDIFS
    name="${item%|*}"
    url="${item#*|}"
    installPlugin "${name}" "${url}"
  done
fi

# Old deprecated plugins settings
if [ ! -z "${GLPI_PLUGINS}" ]; then
  echo "..#WARNING# GLPI_PLUGINS is deprecated use the new GLPI_INSTALL_PLUGINS instead" 1>&2
  for item in ${GLPI_PLUGINS}; do
    name="${item%|*}"
    url="${item#*|}"
    installPlugin "${name}" "${url}"
  done
fi
cd -


## Remove installer
echo "Removing installer if needed..."
# used to remove the installer after first installation
if [ "x${GLPI_REMOVE_INSTALLER}" = 'xyes' ]; then
  rm -f "${basedir}/install/install.php"
fi


## Files permissions
echo "Set files permissions..."
# address issue https://github.com/Turgon37/docker-glpi/issues/2
if [ "x${GLPI_CHMOD_PATHS_FILES}" = 'xyes' ]; then
  chown -R www-data:www-data "${basedir}/files"
  chmod -R u=rwX,g=rX,o=--- "${basedir}/files"
fi


## Start
echo "Starting up..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
