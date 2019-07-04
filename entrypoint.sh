#!/bin/sh

set -e

basedir="${GLPI_PATHS_ROOT}"

## Configure timezone
function setTimezone() {
  if [ -n "${TZ}" ]; then
    echo "Configuring timezone to ${TZ}..."
    if [ ! -f "/usr/share/zoneinfo/${TZ}" ]; then
      echo "...#ERROR# failed to link timezone data from /usr/share/zoneinfo/${TZ}" 1>&2
      exit 1
    fi
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
  fi
}

## Install plugins

# Install a plugin
# $1 : the name of the plugin (directory)
# $2 : the url to download the plugin from
function installPlugin() {
  local plugin="${1}"
  local url="${2}"
  local file="$(basename "$url")"
  local plugin_root_dir="${GLPI_PATHS_PLUGINS}/${plugin}"
  local plugin_tmp_file="/tmp/${file}"

  # continue if plugin already installed
  if [ -d "${plugin_root_dir}" ]; then
    echo "..plugin ${plugin} already installed"
    return 0
  fi
  # Download plugin source if not exists
  if [ ! -f "${plugin_tmp_file}" ]; then
    echo "..downloading plugin '${plugin}' from '${url}'"
    curl -sS --fail -o "${plugin_tmp_file}" -L "${url}"
    if [ $? -ne 0 ]; then
      echo "..#ERROR# failed to downalod plugin ${plugin} from url ${url}" 1>&2
      return 1
    fi
  fi

  # extract the archive according to the extension
  echo "..extracting plugin '${plugin_tmp_file}'"
  local tar_options="--directory=${GLPI_PATHS_PLUGINS}"
  case "$plugin_tmp_file" in
    *.tar.gz)
      tar ${tar_options} -xz -f "${plugin_tmp_file}"
      ;;
    *.tar.bz2)
      tar ${tar_options} -xj -f "${plugin_tmp_file}"
      ;;
    *.zip)
      unzip "${plugin_tmp_file}" -d "${GLPI_PATHS_PLUGINS}"
      ;;
    *)
      echo "..#ERROR# unknown extension for ${file}. Please open an issue or make a PR to https://github.com/Turgon37/docker-glpi" 1>&2
      false
      ;;
  esac
  if [ $? -ne 0 ]; then
    echo "..#ERROR# failed to extract plugin ${plugin}" 1>&2
    return 1
  fi

  # remove source and set file permissions
  rm -f "${plugin_tmp_file}"
  chown -R www-data:www-data "${plugin_root_dir}"
  chmod -R g=rX,o=--- "${plugin_root_dir}"
}

# run sartup action only if main command is given to entrypoint
if expr match $1 '.*supervisord' >/dev/null; then
  setTimezone

  echo "Installing plugins... in ${GLPI_PATHS_PLUGINS}"

  # Use the new syntax with comma separated list
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
    echo "..#error# GLPI_PLUGINS is deprecated use the new GLPI_INSTALL_PLUGINS instead" 1>&2
    exit 1
  fi

  ## Remove installer
  # used to remove the installer after first installation
  if [ "x${GLPI_REMOVE_INSTALLER}" = 'xyes' ]; then
    echo 'Removing installer if needed...'
    rm -f "${basedir}/install/install.php"
  fi

  ## Files structure
  echo "Create file structure..."
  for f in _cache _cron _dumps _graphs _lock _log _pictures _plugins _rss _sessions _tmp _uploads; do
    dir="${basedir}/files/${f}"
    if [ ! -d "${dir}" ]; then
      mkdir -p "${dir}"
      chown www-data:www-data "${dir}"
      chmod u=rwX,g=rwX,o=--- "${dir}"
    fi
  done

  ## Files permissions
  # address issue https://github.com/Turgon37/docker-glpi/issues/2
  if [ "x${GLPI_CHMOD_PATHS_FILES}" = 'xyes' ]; then
    echo 'Set files permissions...'
    chown -R www-data:www-data "${basedir}/files"
    chmod -R u=rwX,g=rX,o=--- "${basedir}/files"
  fi

  # address issue https://github.com/Turgon37/docker-glpi/issues/27
  if [ `stat -c %u ${basedir}/config` != `id -u www-data` ]; then
    find . -maxdepth 1 -not -name files | xargs -r chown -R www-data:www-data
  fi
fi

## Start
exec "$@"
