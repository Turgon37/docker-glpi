# Changelog

Items starting with `DEPRECATE` are important deprecation notices.

## 3.0.0 (2019-03-10)

### Build process

- Use the official PHP image as FROM
- Separate image variant into dedicated dockerfiles

### Image

- Replace start.sh by entrypoint
- Remove cron job from supervisord
- Add /opt/scripts/cronwrapper.py to format cron output
- Remove support of GLPI_PLUGINS to install plugins, you must use GLPI_INSTALL_PLUGINS

## 2.4.2 (2018-12-16)

### Image

- Handle Timezone configuration #21

## 2.4.1 (2018-11-03)

### Image

- Clean composer local cache to free 20M of space

## 2.4.0 (2018-11-03)

### Image

+ Add ping and fping for https://github.com/pluginsGLPI/addressing plugin #18
+ Add apereo/phpCAS library to fix GLPI requirements #19 (https://github.com/apereo/phpCAS)
+ Upgrade GLPI to 9.3 #15

See this issue to upgrade from 9.2* to 9.3* : https://github.com/glpi-project/glpi/issues/4311

### Deprecation

- DEPRECATE environment variable GLPI_PLUGINS in favor of GLPI_INSTALL_PLUGINS (will be removed in 3.0)

## 2.3.0 (2018-05-29)

### Image

+ Add php5-soap #13
+ Add graphviz #12
+ Fix cronjob #11

## 2.2.0 (2018-04-02)

### Image

+ Add environment variable to control internal cronjob : GLPI_ENABLE_CRONJOB, default to enabled to keep backward compatiblity

### Deprecation

- DEPRECATE internal cronjobs handled by supervisor, it will be removed in 3.0 release.

## 2.1.0 (2018-02-04)

### Image

+ Add docker healthcheck

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
