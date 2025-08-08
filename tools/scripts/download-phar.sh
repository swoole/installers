#!/usr/bin/env bash

set -exu
__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)
__PROJECT__=$(
  cd ${__DIR__}/../../
  pwd
)
cd ${__PROJECT__}

mkdir -p ${__PROJECT__}/var/
cd ${__PROJECT__}/var/

while [ $# -gt 0 ]; do
  case "$1" in
  --proxy)
    export HTTP_PROXY="$2"
    export HTTPS_PROXY="$2"
    NO_PROXY="127.0.0.0/8,10.0.0.0/8,100.64.0.0/10,172.16.0.0/12,192.168.0.0/16"
    NO_PROXY="${NO_PROXY},::1/128,fe80::/10,fd00::/8,ff00::/8"
    NO_PROXY="${NO_PROXY},localhost"
    NO_PROXY="${NO_PROXY},.aliyuncs.com,.aliyun.com,.tencent.com"
    NO_PROXY="${NO_PROXY},.myqcloud.com,.swoole.com"
    export NO_PROXY="${NO_PROXY},.tsinghua.edu.cn,.ustc.edu.cn,.npmmirror.com"
    ;;
  --*)
    echo "Illegal option $1"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

# box
# https://github.com/box-project/box/blob/main/doc/installation.md#installation

# phive
# https://github.com/phar-io/phive

# comopser
# https://getcomposer.org/

# PIE
# https://github.com/php/pie/blob/main/docs/usage.md
# https://packagist.org/extensions?

test -f composer.phar || curl -Lo composer.phar https://getcomposer.org/download/latest-stable/composer.phar
chmod +x composer.phar

test -f pie.phar || curl -Lo pie.phar https://github.com/php/pie/releases/latest/download/pie.phar
chmod +x pie.phar

which php
php -v

./composer.phar --help
./pie.phar --help
