# First stage : download glpi + build it
FROM php:5.6-fpm-alpine3.8 as build_glpi

ARG GLPI_VERSION
ARG GLPI_PATHS_ROOT=/var/www

RUN set -ex; \
    mkdir -p "${GLPI_PATHS_ROOT}" ; \
    curl --fail -o glpi.tgz -L "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz" ; \
    tar -xzf glpi.tgz --strip 1 --directory ${GLPI_PATHS_ROOT} ; \
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" ; \
    export EXPECTED_SIGNATURE=`curl -s -o - https://composer.github.io/installer.sig` ; \
    export CURRENT_SIGNATURE=`php -r "echo hash_file('SHA384', '/tmp/composer-setup.php');"` ; \
    [ "$EXPECTED_SIGNATURE" == "$CURRENT_SIGNATURE" ] || (echo 'ERROR: Invalid installer signature' >&2; exit 1) ; \
    php /tmp/composer-setup.php --install-dir=/tmp/ ; \
    COMPOSER_HOME=/tmp/composer php /tmp/composer.phar require --no-interaction --working-dir ${GLPI_PATHS_ROOT} apereo/phpcas ; \
    cd "${GLPI_PATHS_ROOT}" && rm -fv composer.json composer.lock

# Second stage : build final image
FROM php:5.6-fpm-alpine3.8

LABEL maintainer='Pierre GINDRAUD <pgindraud@gmail.com>'

ARG GLPI_VERSION

ENV GLPI_VERSION "${GLPI_VERSION}"
ENV GLPI_PATHS_ROOT /var/www
ENV GLPI_PATHS_PLUGINS /var/www/plugins
ENV GLPI_REMOVE_INSTALLER no
ENV GLPI_CHMOD_PATHS_FILES no
ENV GLPI_INSTALL_PLUGINS ''

# Install dependencies
RUN set -ex; \
    apk --no-cache add \
      curl \
      nginx \
      fping \
      graphviz \
      iputils \
      net-snmp-libs \
      supervisor \
      tar \
      tzdata \
    ; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        autoconf \
        coreutils \
        curl-dev \
        freetype-dev \
        icu-dev \
        imap-dev \
        libevent-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        net-snmp-dev \
        openldap-dev \
        pcre-dev \
        imagemagick-dev \
    ; \
    docker-php-source extract ; \
    docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr; \
    docker-php-ext-configure ldap ; \
    docker-php-ext-install \
       exif \
       gd \
       imap \
       ldap \
       mysqli \
       opcache \
       snmp \
       soap \
       xmlrpc \
    ; \
    pecl install apcu-4.0.11 && docker-php-ext-enable apcu ; \
    docker-php-source delete ; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .nextcloud-phpext-rundeps $runDeps; \
    apk del .build-deps ; \
    mkdir -p /run/nginx ; \
    find "${GLPI_PATHS_ROOT}" -mindepth 1 -maxdepth 1 -not -name '.*' -and -not -name '..' | xargs rm -rfv

# Copy glpi build
COPY --from=build_glpi --chown=www-data:www-data ${GLPI_PATHS_ROOT} ${GLPI_PATHS_ROOT}

# Add some configurations files
COPY root/ /

# Apply PHP FPM configuration
RUN ( \
      echo 'memory_limit=64M' ; \
    ) > /usr/local/etc/php/conf.d/memory-limit.ini ; \
    ( \
      echo 'file_uploads=on' ; \
      echo 'max_execution_time=600' ; \
      echo 'register_globals=off' ; \
      echo 'magic_quotes_sybase=off' ; \
      echo 'session.auto_start=off' ; \
      echo 'session.use_trans_sid=0' ; \
      echo 'display_errors=stderr' ; \
      echo 'display_startup_errors=On' ; \
    ) > /usr/local/etc/php/conf.d/tuning.ini ; \
    ( \
      echo '[www]' ; \
      echo 'listen = /var/run/php-fpm.sock' ; \
      echo 'listen.owner = www-data' ; \
      echo 'listen.group = nginx' ; \
      echo 'listen.mode =' ; \
    ) > /usr/local/etc/php-fpm.d/zzz-nginx.conf ; \
    chmod -R g=rX,o=--- /var/www/* ; \
    addgroup nginx www-data

EXPOSE 80/tcp
VOLUME ["/var/www/files", "/var/www/config"]
WORKDIR "${GLPI_PATHS_ROOT}"

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
    CMD curl --silent --fail http://localhost:80 || exit 1

COPY /entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "--configuration", "/etc/supervisord.conf"]
