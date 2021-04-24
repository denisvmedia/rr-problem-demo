FROM php:7.4-fpm-alpine AS base

RUN apk add --no-cache --virtual .intl-deps icu-dev \
    && docker-php-ext-install pdo_mysql opcache intl sockets \
    && apk del .intl-deps \
    && apk add --update --no-cache icu

RUN docker-php-source extract \
    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && apk del .phpize-deps-configure \
    && docker-php-source delete

RUN sed -i \
        #-e "s/pm = dynamic/pm = static/g" \
        -e "s/pm.max_children = 5/pm.max_children = 100/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 10/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 10/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 70/g" \
        -e "s/;decorate_workers_output = no/decorate_workers_output = no/g" \
        -e "s/;catch_workers_output = yes/catch_workers_output = yes/g" \
        /usr/local/etc/php-fpm.d/www.conf

# road-runner image
FROM base AS base-rr

WORKDIR /var/www/html

COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN apk --update --no-cache add git
RUN mkdir -p /opt/rr-build \
    && cd /opt/rr-build \
    && composer require spiral/roadrunner:v2.0 nyholm/psr7 \
    && ./vendor/bin/rr get-binary --location /usr/local/bin \
    && chmod +x /usr/local/bin/rr \
    && cd /var/www/html \
    && rm -rf /opt/rr-build

RUN echo "apc.enable_cli=1" >> /usr/local/etc/php/php.ini

EXPOSE 8080

CMD ["rr", "serve"]
