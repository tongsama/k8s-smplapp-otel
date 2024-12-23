#!/bin/sh
#umask 0002;  #no effect
set -e

##### Configurations switch should be ensure power equality when container restarted
PHP_CONF_DIR=/usr/local/etc/php
PHPFPM_CONF_DIR=/usr/local/etc/php-fpm.d

#######################################################################
# switch xdebug on/off by environment variable
# default is off
XDEBUG_ENABLED=${XDEBUG_ENABLED:-0}
XDEBUG_CLIENT_HOST=${XDEBUG_CLIENT_HOST:-"host.docker.internal"}
XDEBUG_CLIENT_PORT=${XDEBUG_CLIENT_PORT:-9003}
if [ ${XDEBUG_ENABLED} -eq 1 ]; then
    echo "xdebug is enabled" >&2
    sed -i "s/^;\(zend_extension=xdebug.*\)/\1/" ${PHP_CONF_DIR}/conf.d/docker-php-ext-xdebug.ini
    sed -i "s/^\(xdebug.client_host =\).*/\1 ${XDEBUG_CLIENT_HOST}/" ${PHP_CONF_DIR}/conf.d/docker-php-ext-xdebug.ini
    sed -i "s/^\(xdebug.client_port =\).*/\1 ${XDEBUG_CLIENT_PORT}/" ${PHP_CONF_DIR}/conf.d/docker-php-ext-xdebug.ini
else
    echo "xdebug is disabled" >&2
    sed -i "s/^\(zend_extension=xdebug.*\)/;\1/" ${PHP_CONF_DIR}/conf.d/docker-php-ext-xdebug.ini
fi

#######################################################################
# switch php.ini & php-fpm.conf by development/production environment
#  (values are overwritten by later one)
# default is production
ln -sf ${PHP_CONF_DIR}/php.ini-add-common ${PHP_CONF_DIR}/conf.d/php.ini-add-a-common.ini
DEV_ENABLED=${DEV_ENABLED:-0}
if [ ${DEV_ENABLED} -eq 1 ]; then
    echo "setup development environment" >&2
    ln -sf ${PHP_CONF_DIR}/php.ini-development ${PHP_CONF_DIR}/php.ini
    ln -sf ${PHP_CONF_DIR}/php.ini-add-development ${PHP_CONF_DIR}/conf.d/php.ini-add-z-alt.ini
    ln -sf ${PHPFPM_CONF_DIR}/www.conf-development ${PHPFPM_CONF_DIR}/www.conf-alt
else
    echo "setup production environment" >&2
    ln -sf ${PHP_CONF_DIR}/php.ini-production ${PHP_CONF_DIR}/php.ini
    ln -sf ${PHP_CONF_DIR}/php.ini-add-production ${PHP_CONF_DIR}/conf.d/php.ini-add-z-alt.ini
    ln -sf ${PHPFPM_CONF_DIR}/www.conf-production ${PHPFPM_CONF_DIR}/www.conf-alt
fi
# rewrite php-fpm:www.conf extra tunings
if [ -n "${PM_MAX_CHILDREN}" ]; then
    sed -i "s/^\(pm\.max_children =\).*/\1 ${PM_MAX_CHILDREN}/" ${PHPFPM_CONF_DIR}/www.conf-alt
fi
if [ -n "${PM_START_SERVERS}" ]; then
    sed -i "s/^\(pm\.start_servers =\).*/\1 ${PM_START_SERVERS}/" ${PHPFPM_CONF_DIR}/www.conf-alt
fi
if [ -n "${PM_MIN_SPARE_SERVERS}" ]; then
    sed -i "s/^\(pm\.min_spare_servers =\).*/\1 ${PM_MIN_SPARE_SERVERS}/" ${PHPFPM_CONF_DIR}/www.conf-alt
fi
if [ -n "${PM_MAX_SPARE_SERVERS}" ]; then
    sed -i "s/^\(pm\.max_spare_servers =\).*/\1 ${PM_MAX_SPARE_SERVERS}/" ${PHPFPM_CONF_DIR}/www.conf-alt
fi
if [ -n "${PM_MAX_SPAWN_RATE}" ]; then
    sed -i "s/^\(pm\.max_spawn_rate =\).*/\1 ${PM_MAX_SPAWN_RATE}/" ${PHPFPM_CONF_DIR}/www.conf-alt
fi
if [ -n "${PM_PROCESS_IDLE_TIMEOUT}" ]; then
    sed -i "s/^\(pm\.process_idle_timeout =\).*/\1 ${PM_PROCESS_IDLE_TIMEOUT}/" ${PHPFPM_CONF_DIR}/www.conf-alt
fi
if [ -n "${PM_MAX_REQUESTS}" ]; then
    sed -i "s/^\(pm\.max_requests =\).*/\1 ${PM_MAX_REQUESTS}/" ${PHPFPM_CONF_DIR}/www.conf-alt
fi


# exec php-fpm with args
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1"  ]; then
   set -- php-fpm "$@"
fi
umask 0002 && exec "$@"
