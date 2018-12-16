FROM alpine:3.7

ARG GLPI_VERSION

ENV GLPI_VERSION="${GLPI_VERSION}"
ENV GLPI_PATHS_ROOT=/var/www
ENV GLPI_PATHS_PLUGINS=/var/www/plugins
ENV GLPI_ENABLE_CRONJOB=yes
ENV GLPI_REMOVE_INSTALLER=no
ENV GLPI_CHMOD_PATHS_FILES=no
ENV GLPI_INSTALL_PLUGINS=''

# Install dependencies
RUN apk --no-cache add \
      curl \
      nginx \
      fping \
      graphviz \
      iputils \
      php5 \
      php5-apcu \
      php5-cli \
      php5-ctype \
      php5-curl \
      php5-dom \
      php5-fpm \
      php5-gd \
      php5-imap \
      php5-json \
      php5-ldap \
      php5-pdo_mysql \
      php5-phar \
      php5-mysqli \
      php5-openssl \
      php5-opcache \
      php5-soap \
      php5-xml \
      php5-xmlreader \
      php5-xmlrpc \
      php5-zlib \
      supervisor \
      tar \
      tzdata \
    ## Install GLPI sources
    && mkdir -p /run/nginx \
    && mkdir -p "${GLPI_PATHS_ROOT}" \
    && adduser -h "${GLPI_PATHS_ROOT}" -g 'Web Application User' -S -D -H -G www-data www-data \
    && cd "${GLPI_PATHS_ROOT}" \
    && curl -s -O -L "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz" \
    && tar -xzf "glpi-${GLPI_VERSION}.tgz" --strip 1 \
    ## Install composer to fetch missing libraries
    && EXPECTED_SIGNATURE="$(curl -s -o - https://composer.github.io/installer.sig)" \
    && php5 -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" \
    && CURRENT_SIGNATURE="$(php5 -r "echo hash_file('SHA384', '/tmp/composer-setup.php');")" \
    && [ "$EXPECTED_SIGNATURE" == "$CURRENT_SIGNATURE" ] || (echo 'ERROR: Invalid installer signature' >&2; rm composer-setup.php; exit 1) \
    && php5 /tmp/composer-setup.php --install-dir=/tmp/ && rm /tmp/composer-setup.php \
    && COMPOSER_HOME=/tmp/composer php5 /tmp/composer.phar require --no-interaction apereo/phpcas \
    ## Cleanup
    && rm "glpi-${GLPI_VERSION}.tgz" \
    && rm -rf AUTHORS.txt CHANGELOG.md COPYING.txt LISEZMOI.txt README.md composer.json composer.lock \
    && find /root /tmp -mindepth 1 -maxdepth 1 -not -name '.' -and -not -name '..' | xargs rm -rf \
    && apk del --no-cache \
      php5-phar

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
    sed -i -e "s|max_execution_time\s*=.*$|max_execution_time = 600|" /etc/php5/php.ini && \
    sed -i -e "s|upload_max_filesize\s*=.*$|upload_max_filesize = 30M|" /etc/php5/php.ini && \
    chown -R www-data:www-data /var/www && \
    chmod -R g=rX,o=--- /var/www

EXPOSE 80/tcp
VOLUME ["/var/www/files", "/var/www/config"]
WORKDIR "${GLPI_PATHS_ROOT}"

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
    CMD curl --silent --fail http://localhost:80 || exit 1

CMD ["/start.sh"]
