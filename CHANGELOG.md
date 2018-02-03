# Changelog

Items starting with `DEPRECATE` are important deprecation notices.

## 2.0.0 (2018-02-03)

### Image

+ Upgrade to Alpine 3.7
+ Add GLPI_CHMOD_PATHS_FILES [#2](https://github.com/Turgon37/docker-glpi/issues/2)
+ Add support for .bz2 plugin archives
+ Add standard labels in docker image
- Fix a bug when the image cannot be started if a plugin installation fail

### GLPI

* Upgrade to 9.2.1 [#1](https://github.com/Turgon37/docker-glpi/issues/1)

### Deprecation

- Deprecate `GLPI_PLUGINS` environment variable in favor of GLPI_INSTALL_PLUGINS. GLPI_INSTALL_PLUGINS is comma separated and follow the same pattern as GLPI_PLUGINS.

## 1.0.0 (2017-08-07)

First release