

PHP=$(which php)
PHPIZE=$(which phpize)
PHP_CONFIG=$(which php-config)


if  test -x "${PHP}" -a  -x "${PHPIZE}" -a  -x  "${PHP_CONFIG}"  ; then
  ${PHP} -v
  ${PHPIZE} --help
  ${PHP_CONFIG} --help
else
  echo 'no found PHP '
  exit 0
fi

php -m
php --ri swoole
