# Docker GLPI

[![](https://images.microbadger.com/badges/image/turgon37/glpi.svg)](https://microbadger.com/images/turgon37/glpi "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/turgon37/glpi.svg)](https://microbadger.com/images/turgon37/glpi "Get your own version badge on microbadger.com")

This images contains an instance of GLPI web application served by nginx on port 80

## Docker Informations

* This image expose the following port

| Port           | Usage                |
| -------------- | -------------------- |
| 80             | HTTP web application |

 * This image takes theses environnements variables as parameters

| Environment                 | Usage                                                           |
| --------------------------- | ----------------------------------------------------------------|


   * The following volume is exposed by this image

| Volume                     | Usage                                                 |
| -------------------------- | ----------------------------------------------------- |
| /var/www/files             | The data path of GLPI                                 |

## Installation

* Manual

```
git clone
docker build -t turgon37/glpi .
```

* or Automatic

```
docker pull turgon37/glpi
```


## Usage

```
docker run -p 8000:80 -v data-glpi:/var/www/files turgon37/glpi
```
