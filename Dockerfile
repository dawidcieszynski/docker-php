FROM wildscamp/php:7.4

RUN apt-get -y update \
        && apt-get install -y libicu-dev \
        && docker-php-ext-configure intl \
        && docker-php-ext-install intl \
        && docker-php-ext-configure gd --with-jpeg \
        && docker-php-ext-install -j$(nproc) gd \
        && rm -rf /var/lib/apt/lists/*

RUN apt-get -y update \
    && apt-get install -y default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80 443

WORKDIR ${VOLUME_PATH}

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
