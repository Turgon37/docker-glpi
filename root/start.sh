#!/bin/sh

set -e

basedir="${GLPI_ROOT}"

# used to remove the installer after first installation
if [ "x${GLPI_REMOVE_INSTALLER}" = 'xyes' ]; then
  rm -f "${basedir}/install/install.php"
fi

plugindir="${basedir}/plugins"
echo "Installing plugins..."
cd "$plugindir"
for i in ${GLPI_PLUGINS}; do
  plugin="${i%|*}"
  url="${i#*|}"
  file=$(basename "$url")

  # continue if plugin already installed
  if [ -d "$plugin" ]; then
    echo "..plugin ${plugin} already installed"
    continue
  fi
  # Download plugin source if not exists
  if [ ! -f "$file" ]; then
    echo "..downloading plugin '${plugin}' from '${url}'"
    curl -o "$file" -L "$url"
  fi
  
  # extract the archive according to the extension
  echo "..extracting plugin '${file}'"
  case $file in
    *.tar.gz)
      tar xzf "$file"
      ;;
    *)
    echo "..#ERROR# unknown extension for ${file}. Please open an issue or make a PR to https://github.com/Turgon37/docker-glpi"
      ;;
  esac
  if [ $? -ne 0 ]; then
    continue
  fi
  rm -f $file
  chown -R www-data:www-data "${plugin}"
  chmod -R g=rX,o=--- "${plugin}"
done
cd -

# address issue https://github.com/Turgon37/docker-glpi/issues/2
if [ "x${GLPI_CHMOD_FILES}" = 'xyes' ]; then
  chown -R www-data:www-data "${basedir}/files"
  chmod -R u=rwX,g=rX,o=--- "${basedir}/files"
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf
