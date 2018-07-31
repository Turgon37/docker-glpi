# Docker GLPI

[![Build Status](https://travis-ci.org/Wolvverine/docker-glpi.svg?branch=master)](https://travis-ci.org/Wolvverine/docker-glpi)
[![](https://images.microbadger.com/badges/image/Wolvverine/glpi.svg)](https://microbadger.com/images/Wolvverine/glpi "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/Wolvverine/glpi.svg)](https://microbadger.com/images/Wolvverine/glpi "Get your own version badge on microbadger.com")

This images contains an instance of GLPI web application served by nginx and php5-fpm on port 80

:warning: Take care of the [changelogs](CHANGELOG.md) because some breaking changes may happend between versions.

## Supported tags and respective Dockerfile links

* [`9.3.2`,`latest`](https://github.com/Turgon37/docker-glpi/blob/master/Dockerfile)

* [`9.3.1`](https://github.com/Turgon37/docker-glpi/blob/master/Dockerfile)


## Docker Informations

* This image expose the following port

| Port           | Usage                |
| -------------- | -------------------- |
| 80/tcp         | HTTP web application |

 * This image takes theses environnements variables as parameters

| Environment               | Type             | Usage                                                                           |
| --------------------------|----------------- | ------------------------------------------------------------------------------- |
| GLPI_REMOVE_INSTALLER     | Boolean (yes/no) | Set to yes if it's not the first installation of glpi                           |
| GLPI_CHMOD_PATHS_FILES    | Boolean (yes/no) | Set to yes to apply chmod/chown on /var/www/files (useful for host mount)       |
| (deprecated) GLPI_PLUGINS | String           | (will be removed on 3.0) Space separated list of plugins to install (see below) |
| GLPI_INSTALL_PLUGINS      | String           | Comma separated list of plugins to install (see below)                          |
| GLPI_ENABLE_CRONJOB       | Boolean (yes/no) | Enable internal execution of the cron.php                                       |


The GLPI_INSTALL_PLUGINS variable must contains the list of plugins to install (download and extract) before starting glpi.
This environment variable is a comma separated list of plugins definitions. Each plugin definition must be like this "PLUGINNAME|URL".
The PLUGINNAME is the name of the first folder in plugin archive and will be the glpi's name of the plugin.
The URL is the full URL from which to download the plugin. This url can contains some compressed file extensions, in some case the installer script will not be able to extract it, so you can create an issue with specifying the unhandled file extension.
These two items are separated by a pipe symbol.

To summurize, the GLPI_INSTALL_PLUGINS variable must follow the following skeleton GLPI_INSTALL_PLUGINS="name1|url1,name2|url2"
For better example see at the end of this file.

   * The following volume is exposed by this image

| Volume             | Usage                                            |
| ------------------ | ------------------------------------------------ |
| /var/www/files     | The data path of GLPI                            |
| /var/www/config    | The configuration path of GLPI                   |


## Todo

* Normalize log output
* Propose splitted nginx/fpm images

## Installation

* Manual

```
git clone
docker build -t wolvverine/glpi .
```

* or Automatic

```
docker pull wolvverine/glpi
```


## Usage

The first time you run this image, set the GLPI_REMOVE_INSTALLER variable to 'no', then after this first installation set it to 'yes' to remove the installer.

### Without database link (you can use an ip address or a domain name in the installer gui)

```
docker run --name glpi --publish 8000:80 --volume data-glpi:/var/www/files --volume data-glpi-config:/var/www/config wolvverine/glpi
```

### With database link (if you have any MySQL/MariaDB as a docker container)

#### Create dedicated network

```
docker run --name glpi --publish 8000:80 --volume data-glpi:/var/www/files --volume data-glpi-config:/var/www/config --link yourdatabase:mysql wolvverine/glpi
```

#### Start a MySQL instance

```
docker run --name mysql -d --net glpi-network -e MYSQL_DATABASE=glpi -e MYSQL_USER=glpi -e MYSQL_PASSWORD=glpi -e MYSQL_ROOT_PASSWORD=root_password mysql
```

#### Start a GLPI instance

```
docker run --name glpi --publish 8000:80 --volume data-glpi:/var/www/files --volume data-glpi-config:/var/www/config --net glpi-network turgon37/glpi
```

### Docker-compose Specific configuration examples

* Production configuration with already installed GLPI with FusionInventory and dashboard plugin :

```
services:
  glpi:
    image: wolvverine/glpi
    environment:
      GLPI_REMOVE_INSTALLER: 'yes'
      GLPI_INSTALL_PLUGINS: 'fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.2%2B1.0/glpi-fusioninventory-9.2.1.0.tar.bz2'
    ports:
      - 80
    volumes:
      - data-glpi-files:/var/www/files
      - data-glpi-config:/var/www/config
volumes:
  data-glpi-files:
  data-glpi-config:
```
