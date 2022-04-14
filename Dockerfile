ARG PHP_VERSION=7.4

FROM php:${PHP_VERSION}-apache
MAINTAINER Joel Rowley <joel.rowley@wilds.org>

LABEL vendor="The Wilds" \
      org.wilds.docker-php.version="${PHP_VERSION}.0"

RUN echo "PHP_VERSION: $PHP_VERSION"

RUN apt-get -qq update && apt-get -qq install \
        acl \
        libcurl3-dev \
        curl \
        git \
        libmcrypt-dev \
        rsync \
        telnet \
        vim \
        libpng-dev \
        libjpeg-dev \
        zlib1g-dev \
        libmemcached-dev \
        libicu-dev \
		&& apt-get clean \
		&& apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer

# Install wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN pecl install xdebug memcached \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install gd json mysqli \
    && docker-php-ext-enable xdebug memcached

RUN docker-php-ext-configure intl \
    && docker-php-ext-install intl

COPY bin/* /usr/local/bin/

ADD apache-conf/set-hostname.conf /etc/apache2/conf-available/
ADD apache-conf/default-ssl.conf /etc/apache2/sites-available/

RUN a2enmod rewrite ssl \
    && chmod -R +x /usr/local/bin/ \
    && ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf

ENV   CONFD_PATH=$PHP_INI_DIR/conf.d \
      APACHE_CONFDIR=/etc/apache2 \
      TIMEZONE='America/New_York' \
      VOLUME_PATH=/var/www/html \
      CERTIFICATE_PATH=/usr/local/share/ca-certificates \
      TERM=xterm \
      PHP_VERSION=${PHP_VERSION}

ENV APACHE_ENVVARS=$APACHE_CONFDIR/envvars

COPY php.ini-development.txt $PHP_INI_DIR/php.ini

# Installs sendmail
RUN apt-get update && apt-get install -q -y sendmail && rm -rf /var/lib/apt/lists/*
RUN echo "sendmail_path=/usr/sbin/sendmail -t -i" >> /usr/local/etc/php/conf.d/sendmail.ini
RUN sed -i '/#!\/bin\/sh/aservice sendmail restart' /usr/local/bin/docker-php-entrypoint
RUN sed -i '/#!\/bin\/sh/aecho "$(hostname -i)\t$(hostname) $(hostname).localhost" >> /etc/hosts' /usr/local/bin/docker-php-entrypoint

# Copy custom ini modules
COPY mods-available/*.ini $CONFD_PATH/

# Make a link to a PHP executable based on PHP version number
RUN ln -s $(which php) /usr/local/bin/php$(echo $PHP_VERSION | sed "s/\.//g" | cut -c -2)

EXPOSE 80

WORKDIR ${VOLUME_PATH}

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
