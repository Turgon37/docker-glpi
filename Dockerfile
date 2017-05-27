FROM alpine:3.6
MAINTAINER Pierre GINDRAUD <pgindraud@gmail.com>

ENV GLPI_VERSION=9.1.3 \
    GLPI_ROOT="/var/www" \
    GLPI_REMOVE_INSTALLER=no \
    GLPI_PLUGINS=""
#   GLPI_PLUGINS="fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.1%2B1.1/fusioninventory-for-glpi_9.1.1.1.tar.gz"

# Install dependencies
RUN apk --no-cache add \
      curl \
      nginx \
      php5 \
      php5-curl \
      php5-ctype \
      php5-dom \
      php5-fpm \
      php5-gd \
      php5-imap \
      php5-json \
      php5-ldap \
      php5-pdo_mysql \
      php5-mysqli \
      php5-openssl \
      php5-zlib \
      supervisor \
      tar && \
    apk --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.5/main/ add \
      php5-apcu && \

# Install phppadmin sources
    mkdir -p /run/nginx && \
    mkdir -p "${GLPI_ROOT}" && \
    adduser -h "${GLPI_ROOT}" -g 'Web Application User' -S -D -H -G www-data www-data && \
    cd "${GLPI_ROOT}" && \
    curl -O -L "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz" && \
    tar -xzf "glpi-${GLPI_VERSION}.tgz" --strip 1 && \
    rm "glpi-${GLPI_VERSION}.tgz" && \
    rm -rf AUTHORS.txt CHANGELOG.txt LISEZMOI.txt README.md

# Add some configurations files
COPY root/ /

# Apply PHP FPM configuration
RUN sed -i -e "s|;daemonize\s*=\s*yes|daemonize = no|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|display_errors = Off|display_errors = stderr|" /etc/php5/php.ini && \
    sed -i -e "s|display_startup_errors = Off|display_startup_errors = On|" /etc/php5/php.ini && \
    sed -i -e "s|user\s*=\s*nobody|user = www-data|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|group\s*=\s*nobody|group = www-data|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|listen\s*=\s*127\.0\.0\.1:9000|listen = /var/run/php-fpm5.sock|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.owner\s*=\s*.*$|listen.owner = www-data|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.group\s*=.*$|listen.group = nginx|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.mode\s*=\s*|listen.mode = |g" /etc/php5/php-fpm.conf && \
    chown -R www-data:www-data /var/www && \
    chmod -R g=rX,o=--- /var/www

EXPOSE 80/tcp
VOLUME ["/var/www/files", "/var/www/config"]
WORKDIR "${GLPI_ROOT}"

CMD ["/start.sh"]
