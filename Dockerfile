FROM alpine:3.7

ARG GLPI_VERSION
ARG GLPI_VERSION_FILE
ARG IMAGE_VERSION
ARG BUILD_DATE
ARG VCS_REF

ENV GLPI_VERSION="${GLPI_VERSION}" \
    GLPI_VERSION_FILE="9.3" \
    GLPI_PATHS_ROOT="/var/www" \
    GLPI_PATHS_PLUGINS="/var/www/plugins" \
    GLPI_ENABLE_CRONJOB=yes \
    GLPI_REMOVE_INSTALLER=no \
    GLPI_CHMOD_PATHS_FILES=no \
    GLPI_INSTALL_PLUGINS=""
#   GLPI_INSTALL_PLUGINS="fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.3%2B1.1/fusioninventory-9.3.1.1.tar.bz2"

LABEL maintainer="<wolvverinepld@gmail.com>" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.name="Web application GLPI in docker" \
      org.label-schema.description="This image contains the GLPI web application" \
      org.label-schema.url="https://github.com/wolvverine/docker-glpi" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/wolvverine/docker-glpi" \
      org.label-schema.vendor="" \
      org.label-schema.version="${IMAGE_VERSION}" \
      org.label-schema.schema-version="1.0" \
      application.glpi.version="${GLPI_VERSION}" \
      image.version="${IMAGE_VERSION}"

# Install dependencies
RUN apk --no-cache add \
      fping \
      net-tools \
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
      tar && \
    apk --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.5/main/ add \
      php5-apcu && \
# Install GLPI sources
    mkdir -p /run/nginx && \
    mkdir -p "${GLPI_PATHS_ROOT}" && \
    adduser -h "${GLPI_PATHS_ROOT}" -g 'Web Application User' -S -D -H -G www-data www-data && \
    cd "${GLPI_PATHS_ROOT}" && \
    curl -O -L "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION_FILE}.tgz" && \
    tar -xzf "glpi-${GLPI_VERSION_FILE}.tgz" --strip 1 && \
    rm "glpi-${GLPI_VERSION_FILE}.tgz" && \
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
