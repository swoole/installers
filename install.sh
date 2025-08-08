#!/usr/bin/env bash

__DIR__=$(
  # shellcheck disable=SC2164
  cd "$(dirname "$0")"
  pwd
)

init() {
  OS=$(uname -s)
  if [ "${OS}" = 'Linux' ]; then
    OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora' | 'openEuler' | 'hce') # |  'amzn' | 'ol' | 'rhel' | 'centos'  # 未测试
      yum update -y
      yum install -y which
      ;;
    'ubuntu') ;;

    'alpine')
      apk update
      apk add bash
      ;;
    'arch')
      pacman -Syyu --noconfirm
      pacman -Sy --noconfirm which
      ;;
    esac
  fi
}

OS=$(uname -s)
ARCH=$(uname -m)
if [ "$OS" = 'Linux' ]; then
  init
  if [ ! "$BASH_VERSION" ]; then
    echo "Please  use bash to run this script ($0) " 1>&2
    exit 0
  fi
fi

CPU_LOGICAL_PROCESSORS=4
MIRROR='' # swoole 源码镜像源
ENABLE_TEST=0
VERSION_LATEST=0                                      # 保持源码最新，每次执行都需要下载源码
SWOOLE_SRC='https://github.com/swoole/swoole-src.git' # swoole 源码地址
X_SWOOLE_VERSION=''                                   # 指定 swoole 版本
SWOOLE_VERSION='master'                               # 默认 swoole 版本
SWOOLE_DEBUG=0                                        # 启用 swoole debug 编译参数
INSTALL_PHP=0                                         # 0 未知，待检测 、1 系统已安装PHP、2 系统未安装PHP
FORCE_INSTALL_PHP=0                                   # 0 未设置、3 要求安装PHP 、 4 执行安装 =》 安装以后状态 1 成功安装PHP , 2 未成功安装PHP

PHP_SRC='https://github.com/php/php-src.git' # php 源码地址
PHP=''                                       # php     位置
PHPIZE=''                                    # phpize  位置
PHP_CONFIG=''                                # php-config 位置
PHP_INI_SCAN_DIR=''                          # php 扫描配置目录

INSTALL_PHPY=0                                # 0 安装 phpy
PHPY_SRC='https://github.com/swoole/phpy.git' # phpy 源码地址
X_PHPY_VERSION=''                             # 指定phpy版本
PHPY_VERSION='main'                           # phpy默认版本
PYTHON3_VERSION=''                            # python3 版本
PYTHON3_DIR=''                                # python3 位置
PYTHON3_CONFIG=''                             # python3-config 位置
FORCE_INSTALL_PYTHON3=0                       # 0 未设置、3 要求安装PHP

while [ $# -gt 0 ]; do
  case "$1" in
  --mirror)
    if test -n "$2"; then
      MIRROR="$2"
    fi
    ;;
  --debug)
    set -x
    ;;
  --latest)
    VERSION_LATEST=1
    ;;
  --swoole-version)
    if test -n "$2"; then
      X_SWOOLE_VERSION="$2"
    fi
    ;;
  --swoole-debug)
    SWOOLE_DEBUG=1
    ;;
  --swoole-test)
    ENABLE_TEST=1
    ;;
  --install-php)
    if [ "$2" = "1" ]; then
      FORCE_INSTALL_PHP=3
    fi
    ;;
  --install-phpy)
    INSTALL_PHPY=1
    ;;
  --phpy-version)
    if test -n "$2"; then
      X_PHPY_VERSION="$2"
    fi
    ;;
  --install-python3)
    if [ "$2" = "1" ]; then
      FORCE_INSTALL_PYTHON3=3
    fi
    ;;
  --*)
    echo "no found  option $1"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

case "$MIRROR" in
china)
  SWOOLE_SRC="https://gitee.com/swoole/swoole.git"
  PHP_SRC="https://gitee.com/mirrors/php-src.git"
  PHPY_SRC='https://gitee.com/swoole/phpy.git'
  ;;
*) ;;
esac

case "$OS" in
Darwin)
  CPU_LOGICAL_PROCESSORS=$(sysctl -n hw.ncpu)
  ;;
Linux)
  CPU_LOGICAL_PROCESSORS=$(grep "processor" /proc/cpuinfo | sort -u | wc -l)
  ;;
*) ;;
esac

check_php() {
  PHP="$(which php)"
  PHPIZE="$(which phpize)"
  PHP_CONFIG=""$(which php-config)""

  if test -x "${PHP}" -a -x "${PHPIZE}" -a -x "${PHP_CONFIG}"; then
    ${PHP} -v
    ${PHPIZE} --help
    ${PHP_CONFIG} --help
    PHP_INI_SCAN_DIR=$(php --ini | grep "Scan for additional .ini files in:" | awk -F 'in:' '{ print $2 }' | xargs)
    INSTALL_PHP=1
    if test ${FORCE_INSTALL_PHP} -eq 4; then
      FORCE_INSTALL_PHP=1
    fi
  else
    INSTALL_PHP=2
    if test ${FORCE_INSTALL_PHP} -eq 4; then
      FORCE_INSTALL_PHP=2
    fi
  fi
}

install_system_php() {
  case "$OS" in
  Darwin | darwin)
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1
    brew install php
    ;;
  Linux)
    OS_RELEASE="$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')"
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora' | 'openEuler' | 'hce') # |  'amzn' | 'ol' | 'rhel' | 'centos'  # 未测试
      yum update -y
      yum install -y php-cli php-devel php-curl php-intl
      { yum install -y php-pear; } || { echo $?; }
      { yum install -y php-json; } || { echo $?; }
      yum install -y php-mbstring php-tokenizer php-xml
      yum install -y php-pdo php-mysqlnd
      ;;
    'debian' | 'ubuntu' | 'kali') # 'raspbian' | 'deeping'| 'uos' | 'kylin'
      export DEBIAN_FRONTEND=noninteractive
      export TZ="Etc/UTC"
      ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
      apt update -y
      apt install -y php-cli php-pear php-dev php-curl php-intl
      apt install -y php-mbstring php-tokenizer php-xml
      apt install -y php-mysqlnd php-pgsql php-sqlite3 php-redis php-mongodb
      ;;
    'alpine')
      apk update
      apk add php82-cli php82-dev
      apk add php82-iconv php82-mbstring php82-phar php82-openssl
      apk add php82-posix php82-tokenizer php82-intl
      apk add php82-dom php82-xmlwriter php82-xml php82-simplexml
      apk add php82-pdo php82-sockets php82-curl php82-mysqlnd php82-pgsql php82-sqlite3
      apk add php82-redis php82-mongodb

      php82 -v
      php82 --ini
      php82 --ini | grep ".ini files"

      ln -sf /usr/bin/php82 /usr/bin/php
      ln -sf /usr/bin/phpize82 /usr/bin/phpize
      ln -sf /usr/bin/php-config82 /usr/bin/php-config

      ;;
    'arch')
      pacman -Sy --noconfirm php php-sqlite
      ;;
    esac
    ;;
  FreeBSD)
    if [ ! -f /etc/os-release ]; then
      echo 'support minimal version FreeBSD 13'
      exit 0
    fi
    env ASSUME_ALWAYS_YES=YES
    pkg install php83-8.3.6 php83-curl php83-pdo php83-sockets php83-phar
    pkg install php83-iconv php83-gmp php83-intl php83-mbstring
    pkg install php83-pgsql php83-readline php83-sqlite3 php83-sodium
    pkg install php83-tokenizer php83-zip php83-xml php83-mysqli php83-xml php83-simplexml

    ;;
  *)
    case "$(uname -r)" in
    *microsoft* | *Microsoft*)
      # WSL
      ;;
    esac
    ;;
  esac
  check_php

}

check_php_and_install_php() {
  check_php
  # 系统未安装PHP
  if test ${INSTALL_PHP} -eq 2; then
    # 要求安装PHP
    if test ${FORCE_INSTALL_PHP} -eq 3; then
      FORCE_INSTALL_PHP=4
      install_system_php
      if test ${FORCE_INSTALL_PHP} -eq 1; then
        echo 'INSTALL PHP SUCCESS '
      else
        echo 'no found php phpize php-config in $PATH'
        echo 'please reinstall PHP or link php phpize php-config'
        exit 3
      fi
    else
      # shellcheck disable=SC2016
      test -x "${PHP}" || echo 'no found php IN $PATH '
      # shellcheck disable=SC2016
      test -x "${PHPIZE}" || echo 'no found phpize IN $PATH '
      # shellcheck disable=SC2016
      test -x "${PHP_CONFIG}" || echo 'no found php-config IN $PATH '
      if test ${FORCE_INSTALL_PHP} -ne 3; then
        # 未发现 php ，也未要求安装 PHP
        exit 3
      fi
    fi
  fi

}

install_swoole_dep_lib() {
  case "$OS" in
  Darwin | darwin)
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1
    brew install wget curl libtool automake re2c llvm flex bison
    brew install libtool gettext coreutils pkg-config cmake
    brew install c-ares libpq unixodbc brotli curl pcre2
    ;;
  Linux)
    LINUX_VERSION=$(uname -r | cut -d '-' -f 1)
    LINUX_MAJOR_VERSION=$(echo $LINUX_VERSION | cut -d '.' -f 1)
    LINUX_MINOR_VERSION=$(echo $LINUX_VERSION | cut -d '.' -f 2)
    LINUX_KERNEL_SUPPORT_IO_URING_FEATURE=0
    # shellcheck disable=SC2210
    if test $LINUX_MAJOR_VERSION -gt 6 || (test $LINUX_MAJOR_VERSION -eq 6 && test $LINUX_MINOR_VERSION -ge 7); then
      LINUX_KERNEL_SUPPORT_IO_URING_FEATURE=1
    fi
    OS_RELEASE="$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')"
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora' | 'openEuler' | 'hce') # |  'amzn' | 'ol' | 'rhel' | 'centos'  # 未测试
      yum update -y
      { yum install -y curl; } || { echo $?; }
      { yum install -y curl-minimal; } || { echo $?; }
      yum install -y curl-minimal
      yum install -y git wget ca-certificates
      yum install -y autoconf automake libtool cmake bison gettext zip unzip xz
      yum install -y pkg-config bzip2 flex which
      yum install -y c-ares-devel libcurl-devel pcre-devel postgresql-devel unixODBC brotli-devel sqlite-devel openssl-devel
      yum install -y bc
      yum install -y liburing

      ;;
    'debian' | 'ubuntu' | 'kali')
      export DEBIAN_FRONTEND=noninteractive
      export TZ="Etc/UTC"
      ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
      apt update -y
      apt install -y git curl wget ca-certificates
      apt install -y xz-utils autoconf automake libtool cmake bison re2c gettext coreutils lzip zip unzip
      apt install -y pkg-config bzip2 flex p7zip libssl-dev

      apt install -y gcc g++ libtool-bin autopoint
      apt install -y linux-headers-generic

      apt-get install -y libc-ares-dev libcurl4-openssl-dev
      apt-get install -y libpcre3 libpcre3-dev libpq-dev libsqlite3-dev unixodbc-dev
      apt-get install -y libbrotli-dev liburing-dev
      apt-get install -y bc

      ;;
    'alpine')
      apk update
      apk add autoconf automake make libtool cmake bison re2c gcc g++ git curl wget pkgconf ca-certificates
      apk add clang-dev clang lld alpine-sdk xz tar gzip zip unzip bzip2
      apk add curl-dev c-ares-dev postgresql-dev sqlite-dev unixodbc-dev liburing-dev linux-headers

      ;;
    'arch')
      pacman -Sy --noconfirm gcc autoconf automake make libtool cmake bison re2c gcc git curl
      pacman -Sy --noconfirm xz automake tar gzip zip unzip bzip2 pkg-config
      pacman -Sy --noconfirm curl postgresql-libs c-ares sqlite unixodbc liburing linux-headers

      ;;

    esac
    ;;
  *)
    case "$(uname -r)" in
    *microsoft* | *Microsoft*)
      # WSL
      ;;
    esac
    ;;
  esac
}

install_swoole_dep_ext() {
  # swoole 依赖 openssl  、curl、 sockets、 pdo  扩展
  local EXTENSION_OPENSSL_EXISTS=0
  local EXTENSION_CURL_EXISTS=0
  local EXTENSION_SOCKETS_EXISTS=0
  local EXTENSION_MYSQLND_EXISTS=0
  local EXTENSION_PDO_EXISTS=0

  php --ri openssl >/dev/null && EXTENSION_OPENSSL_EXISTS=1
  php --ri curl >/dev/null && EXTENSION_CURL_EXISTS=1
  php --ri sockets >/dev/null && EXTENSION_SOCKETS_EXISTS=1
  php --ri mysqlnd >/dev/null && EXTENSION_MYSQLND_EXISTS=1
  php --ri pdo >/dev/null && EXTENSION_PDO_EXISTS=1

  # shellcheck disable=SC2046
  if test -f /.dockerenv -a -x "$(which docker-php-source)" -a -x "$(which docker-php-ext-configure)" -a -x "$(which docker-php-ext-enable)"; then
    # php offical 容器中 启用被 swoole 依赖的扩展
    # 准备编译环境
    docker-php-source extract

    test ${EXTENSION_OPENSSL_EXISTS} -eq 0 && docker-php-ext-configure openssl && docker-php-ext-install openssl && docker-php-ext-enable openssl
    test ${EXTENSION_CURL_EXISTS} -eq 0 && docker-php-ext-configure curl && docker-php-ext-install curl && docker-php-ext-enable curl
    test ${EXTENSION_SOCKETS_EXISTS} -eq 0 && docker-php-ext-configure sockets && docker-php-ext-install sockets && docker-php-ext-enable sockets
    test ${EXTENSION_MYSQLND_EXISTS} -eq 0 && docker-php-ext-configure mysqlnd && docker-php-ext-install mysqlnd && docker-php-ext-enable mysqlnd
    test ${EXTENSION_PDO_EXISTS} -eq 0 && docker-php-ext-configure pdo && docker-php-ext-install pdo && docker-php-ext-enable pdo

    docker-php-source delete
  else
    if [ "$OS" = 'Linux' ]; then
      # arch 系统下 php 的 socket 扩展 需要源码编译启用
      # shellcheck disable=SC2155
      local OS_RELEASE="$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')"
      if [ "${OS_RELEASE}" = 'arch' ]; then
        mkdir -p /tmp/build
        # shellcheck disable=SC2155
        local PHP_TMP_VERSION="$(php-config --version)"
        local PHP_TMP_DIR=/tmp/build/php-src-${PHP_TMP_VERSION}
        git clone -b "php-${PHP_TMP_VERSION}" --depth=1 ${PHP_SRC} ${PHP_TMP_DIR}
        # shellcheck disable=SC2164
        cd ${PHP_TMP_DIR}/ext/sockets
        phpize
        ./configure --with-php-config="${PHP_CONFIG}"
        make install

        if [ -n "${PHP_INI_SCAN_DIR}" ] && [ -d "${PHP_INI_SCAN_DIR}" ]; then

          local SOCKETS_INI_FILE=${PHP_INI_SCAN_DIR}/10-sockets.ini
          tee ${SOCKETS_INI_FILE} <<EOF
extension=sockets.so
EOF

        fi
        # shellcheck disable=SC2164
        cd ${__DIR__}
        # test -d $PHP_TMP_DIR && rm -rf $PHP_TMP_DIR
        php --ri sockets >/dev/null && EXTENSION_SOCKETS_EXISTS=1
      fi
    fi

    local MESSAGES=' please manual enable extension : '
    local SUM=0
    test ${EXTENSION_OPENSSL_EXISTS} -eq 0 && MESSAGES="${MESSAGES}  openssl" && ((SUM++))
    test ${EXTENSION_CURL_EXISTS} -eq 0 && MESSAGES="${MESSAGES}  curl" && ((SUM++))
    test ${EXTENSION_SOCKETS_EXISTS} -eq 0 && MESSAGES="${MESSAGES} sockets" && ((SUM++))
    test ${EXTENSION_MYSQLND_EXISTS} -eq 0 && MESSAGES="${MESSAGES}  mysqlnd " && ((SUM++))
    test ${EXTENSION_PDO_EXISTS} -eq 0 && MESSAGES="${MESSAGES} pdo  " && ((SUM++))
    if test $SUM -gt 0; then
      echo $MESSAGES
      exit 3
    fi
  fi

}

install_swoole() {

  local SWOOLE_OPTIONS=''

  # shellcheck disable=SC2155
  local PHP_VERSION=$($(which php-config) --vernum)

  if test -n "${X_SWOOLE_VERSION}"; then
    SWOOLE_VERSION="${X_SWOOLE_VERSION}"
  fi

  if test $((PHP_VERSION)) -ge 80000 -a $((PHP_VERSION)) -lt 80100; then
    test -z "${X_SWOOLE_VERSION}" && SWOOLE_VERSION="v5.1.3"
    test ${VERSION_LATEST} -eq 1 && SWOOLE_VERSION="5.1.x"
  fi

  if test $((PHP_VERSION)) -ge 70200 -a $((PHP_VERSION)) -lt 80000; then
    test -z "${X_SWOOLE_VERSION}" && SWOOLE_VERSION="v4.8.13"
    test ${VERSION_LATEST} -eq 1 && SWOOLE_VERSION="4.8.x"
    SWOOLE_OPTIONS=' --enable-swoole-json --enable-http2 '
  fi

  if test $((PHP_VERSION)) -lt 70200; then
    echo 'no support this php version'
    exit 0
  fi

  mkdir -p /tmp/build
  # shellcheck disable=SC2164
  cd /tmp/build/

  # 指定swoole版本 和 已经存在的版本不一致
  if test -n "${X_SWOOLE_VERSION}" -a -d swoole-src/; then
    if test -f swoole-src/x-swoole-version; then
      if test "$(cat swoole-src/x-swoole-version)" != "${X_SWOOLE_VERSION}"; then
        test -d swoole-src && rm -rf swoole-src
      fi
    else
      test -d swoole-src && rm -rf swoole-src
    fi
  fi

  # 保持源码最新
  test $VERSION_LATEST -eq 1 && test -d swoole-src && rm -rf swoole-src
  # 执行下载 swoole 源码
  if test ! -d swoole-src; then
    git clone -b $SWOOLE_VERSION --single-branch --depth=1 ${SWOOLE_SRC} swoole-src
    if [ $? -ne 0 ]; then
      echo $?
      exit 3
    fi
    echo $SWOOLE_VERSION >swoole-src/x-swoole-version
  fi

  local SWOOLE_ODBC_OPTIONS=""
  local SWOOLE_IO_URING=''
  local SWOOLE_DEBUG_OPTIONS=''
  local SWOOLE_THREAD_OPTION=''

  if [ $SWOOLE_DEBUG -eq 1 ]; then
    SWOOLE_DEBUG_OPTIONS=' --enable-debug --enable-debug-log --enable-trace-log '
  fi

  # shellcheck disable=SC2155
  local PHP_ENABLE_ZTS=$(php -r "echo PHP_ZTS;")
  if [ "${PHP_ENABLE_ZTS}" = '1' ]; then
    SWOOLE_THREAD_OPTION="--enable-swoole-thread "
  fi

  case "$OS" in
  Darwin)
    BREW_PREFIX=$(echo $(brew --prefix) | tr -d '\n')
    case "$ARCH" in
    x86_64)
      export PKG_CONFIG_PATH=${BREW_PREFIX}/opt/libpq/lib/pkgconfig/:${BREW_PREFIX}/opt/unixodbc/lib/pkgconfig/
      SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,${BREW_PREFIX}/opt/unixodbc/"
      ;;
    arm64)
      export PKG_CONFIG_PATH=${BREW_PREFIX}/opt/libpq/lib/pkgconfig/:${BREW_PREFIX}/opt/unixodbc/lib/pkgconfig/
      # /opt/homebrew/opt/pcre2/lib/pkgconfig
      # export PATH=/opt/homebrew/opt/pcre2/bin/:$PATH
      php-config --prefix
      ln -s ${BREW_PREFIX}/opt/pcre2/include/pcre2.h $(php-config --prefix)/include/php/ext/pcre/pcre2.h

      SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,${BREW_PREFIX}/opt/unixodbc/"
      ;;
    esac
    ;;
  Linux)
    HAVE_IOURING_FUTEX=0
    if test ${LINUX_KERNEL_SUPPORT_IO_URING_FEATURE} -eq 1; then
      {
        URING_VERSION=$(pkg-config --modversion liburing)
        IOURING_MAJOR_VERSION=$(echo $URING_VERSION | cut -d '.' -f 1)
        IOURING_MINOR_VERSION=$(echo $URING_VERSION | cut -d '.' -f 2)
        if test $IOURING_MAJOR_VERSION -gt 2 || (test $IOURING_MAJOR_VERSION -eq 2 && test $IOURING_MINOR_VERSION -ge 6); then
          HAVE_IOURING_FUTEX=1
        fi
      } || {
        echo $?
      }
    fi
    OS_RELEASE="$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')"
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora' | 'openEuler' | 'hce') # |  'amzn' | 'ol' | 'rhel' | 'centos'  # 未测试
      SWOOLE_ODBC_OPTIONS=""                                                      # 缺少 unixODBC-devel
      ;;
    'debian' | 'ubuntu' | 'kali') # 'raspbian' | 'deeping'| 'uos' | 'kylin'
      if test -f /.dockerenv -a -x "$(which docker-php-source)" -a -x "$(which docker-php-ext-enable)"; then
        if test ${HAVE_IOURING_FUTEX} -eq 1; then
          SWOOLE_IO_URING=' --enable-iouring '
        fi
      fi

      SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,/usr"
      ;;
    'arch')
      SWOOLE_IO_URING=' --enable-iouring '
      SWOOLE_ODBC_OPTIONS="--with-swoole-odbc=unixODBC,/usr"
      ;;
    'alpine') # 构建 iouring 报错
      ;;

    esac
    ;;
  *) ;;

  esac

  # shellcheck disable=SC2164
  cd /tmp/build/swoole-src

  test -f ext-src/.libs/php_swoole.o && make clean

  phpize

  ./configure --help

  # --enable-swoole-pgsql \
  ./configure \
    --with-php-config="${PHP_CONFIG}" \
    ${SWOOLE_DEBUG_OPTIONS} \
    --enable-openssl \
    --enable-sockets \
    --enable-mysqlnd \
    --enable-cares \
    --enable-swoole-curl \
    ${SWOOLE_OPTIONS} \
    --enable-swoole-sqlite \
    ${SWOOLE_ODBC_OPTIONS} \
    ${SWOOLE_IO_URING} \
    ${SWOOLE_THREAD_OPTION}

  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  # --with-php-config=/usr/bin/php-config
  # --enable-swoole-thread  \
  # --enable-iouring

  make -j ${CPU_LOGICAL_PROCESSORS}

  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  if test $ENABLE_TEST -eq 1; then
    # shellcheck disable=SC2164
    cd /tmp/build/swoole-src/tests/include/lib/
    composer install
    # shellcheck disable=SC2164
    cd /tmp/build/swoole-src/
    make test
  fi

  make install
  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  # 创建 swoole.ini

  if [ -n "${PHP_INI_SCAN_DIR}" ] && [ -d "${PHP_INI_SCAN_DIR}" ]; then
    local SUDO=''
    if [ ! -w "${PHP_INI_SCAN_DIR}" ]; then
      SUDO='sudo'
    fi

    local EXT_INI_FILE=${PHP_INI_SCAN_DIR}/60-swoole.ini
    # shellcheck disable=SC2046
    # 解决 php official 容器中 扩展加载顺序问题
    if test -f /.dockerenv -a -x "$(which docker-php-source)" -a -x "$(which docker-php-ext-enable)"; then
      test -f ${EXT_INI_FILE} && rm -f ${EXT_INI_FILE}
      EXT_INI_FILE=${PHP_INI_SCAN_DIR}/docker-php-ext-swoole-60.ini
    fi
    ${SUDO} tee ${EXT_INI_FILE} <<EOF
extension=swoole.so
swoole.use_shortname=On
EOF

  fi

  php -v
  php -m
  php --ini | grep ".ini files"
  php --ini
  php --ri swoole
}

install_system_python3() {
  case "$OS" in
  Darwin | darwin)
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1
    brew install python3
    ;;
  Linux)
    OS_RELEASE=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '\n' | tr -d '\"')
    case "$OS_RELEASE" in
    'rocky' | 'almalinux' | 'alinux' | 'anolis' | 'fedora' | 'openEuler' | 'hce') # |  'amzn' | 'ol' | 'rhel' | 'centos'  # 未测试
      yum install -y update
      yum install -y python3 python3-devel
      ;;
    'debian' | 'ubuntu' | 'kali')
      export DEBIAN_FRONTEND=noninteractive
      export TZ="Etc/UTC"
      ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
      apt update -y
      apt install -y python3 python3-dev

      ;;
    'alpine')
      apk update
      apk add python3 python3-dev
      ;;
    'arch')
      pacman -Sy --noconfirm python3

      ;;

    esac
    ;;
  *)
    case "$(uname -r)" in
    *microsoft* | *Microsoft*)
      # WSL
      ;;
    esac
    ;;
  esac
}

check_python3_and_install_python3() {
  # shellcheck disable=SC2155
  local PYTHON3="$(which python3)"
  PYTHON3_CONFIG="$(which python3-config)"
  if test -x "${PYTHON3}" -a -x "${PYTHON3_CONFIG}"; then
    PYTHON3_DIR=$(python3-config --prefix)
    PYTHON3_VERSION="$(python3 -V | awk '{ print $2 }')"
    FORCE_INSTALL_PYTHON3=1
    # 检测 python3 版本
    # reference https://semver.org/
    # shellcheck disable=SC2155
    local PYTON3_MAJOR="$(python3 -V | awk '{ print $2 }' | awk -F '.' '{ print $1 }')"
    # shellcheck disable=SC2155
    local PYTON3_MINOR="$(python3 -V | awk '{ print $2 }' | awk -F '.' '{ print $2 }')"
    if [ $((${PYTON3_MAJOR})) -ge 3 ]; then
      if [ $((${PYTON3_MAJOR})) -eq 3 ] && [ $((${PYTON3_MINOR})) -lt 10 ]; then
        echo "phpy no support   python3 ${PYTHON3_VERSION}  ! "
        exit 0
      fi
    fi

    return 0
  else
    if test ${FORCE_INSTALL_PYTHON3} -eq 3; then
      FORCE_INSTALL_PYTHON3=2
      install_system_python3
      check_python3_and_install_python3
      test $? -eq 0 && return 0
    fi
    echo 'no found python3 python3-config in $PATH '
    echo 'please install python3 or link python3 python3-config '
    exit 3

  fi

}

install_php_ext_phpy() {

  mkdir -p /tmp/build
  # shellcheck disable=SC2164
  cd /tmp/build/

  # 指定 phpy 版本 和 已经存在的 phpy 版本不一致
  if test -n "${X_PHPY_VERSION}" -a -d phpy/; then
    if test -f phpy/x-phpy-version; then
      if test "$(cat phpy/x-phpy-version)" != "${X_PHPY_VERSION}"; then
        test -d phpy && rm -rf phpy
      fi
    else
      test -d phpy && rm -rf phpy
    fi
  fi

  # 保持源码最新
  test $VERSION_LATEST -eq 1 && test -d phpy && rm -rf phpy
  test -d phpy || git clone -b $PHPY_VERSION --single-branch --depth=1 $PHPY_SRC
  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi
  echo $PHPY_VERSION >phpy/x-phpy-version

  # shellcheck disable=SC2164
  cd /tmp/build/phpy
  phpize

  ./configure --help

  ./configure \
    --with-php-config="${PHP_CONFIG}" \
    --with-python-dir="${PYTHON3_DIR}" \
    --with-python-config="${PYTHON3_CONFIG}" \
    --with-python-version="${PYTHON3_VERSION}"

  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  make -j ${CPU_LOGICAL_PROCESSORS}
  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  if test $ENABLE_TEST -eq 1; then
    # shellcheck disable=SC2164
    cd /tmp/build/phpy/tests/include/lib/
    composer install
    # shellcheck disable=SC2164
    cd /tmp/build/phpy/
    make test
  fi

  make install
  if [ $? -ne 0 ]; then
    echo $?
    exit 3
  fi

  if [ -n "${PHP_INI_SCAN_DIR}" ] && [ -d "${PHP_INI_SCAN_DIR}" ]; then
    local SUDO=''
    if [ ! -w "${PHP_INI_SCAN_DIR}" ]; then
      SUDO='sudo'
    fi
    local EXT_INI_FILE=${PHP_INI_SCAN_DIR}/61-phpy.ini
    # shellcheck disable=SC2046
    # 解决 php official 容器中 扩展加载顺序问题
    if test -f /.dockerenv -a -x "$(which docker-php-source)" -a -x "$(which docker-php-ext-enable)"; then
      test -f ${EXT_INI_FILE} && rm -f ${EXT_INI_FILE}
      EXT_INI_FILE=${PHP_INI_SCAN_DIR}/docker-php-ext-phpy-61.ini
    fi
    ${SUDO} tee ${EXT_INI_FILE} <<EOF
extension=phpy.so
EOF

  fi

  php -v
  php -m
  php --ini
  php --ini | grep ".ini files"
  php --ri phpy
}

install() {
  check_php_and_install_php
  if test ${INSTALL_PHP} -eq 1; then
    install_swoole_dep_lib
    install_swoole_dep_ext
    install_swoole

    if test ${INSTALL_PHPY} -eq 1; then
      check_python3_and_install_python3
      if test -x "${PYTHON3_CONFIG}"; then
        install_php_ext_phpy
      fi
    fi
  fi
}

# 安装 入口
install
