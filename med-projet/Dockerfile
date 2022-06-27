# TODO: fix version of base-php later
ARG BASE_PHP_TAG

FROM ${BASE_PHP_TAG:-"ghcr.io/smartmedsa/base-php:develop"}

ARG UID=33
ARG GID=33

USER root

RUN set -xe; \
    group_exists=$(getent group www-data | cut -d: -f3); \
    if [ ${group_exists} != ${GID}]; then \
        groupmod --gid ${GID} www-data; \
    fi; \
    user_exists=$(id www-data -u); \
    if [ ${user_exists} != ${UID} ]; then \
            usermod --uid ${UID} www-data ; \
    fi; \
    install -o www-data -g www-data -d \
        "${APP_ROOT}"; \
    chown -R www-data:www-data \
        "${PHP_INI_DIR}/conf.d";

USER www-data

COPY composer.json composer.lock "${APP_ROOT}/"

RUN set -xe; \
    composer validate --no-interaction --quiet; \
    composer install --no-dev --no-scripts --no-plugins --prefer-dist --no-progress --no-interaction

COPY . "${APP_ROOT}"

CMD ["rr", "serve", "-c", ".rr.yaml"]
