#!/usr/bin/env bash

set -exu
__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)
__PROJECT__=$(
  cd ${__DIR__}/../../../
  pwd
)
cd ${__DIR__}

{
  docker stop rhel-dev
  sleep 5
} || {
  echo $?
}
cd ${__DIR__}

# IMAGE=oraclelinux:9

IMAGE=almalinux:9
IMAGE=rockylinux:9

OS="rocky"
MIRROR=''
while [ $# -gt 0 ]; do
  case "$1" in
  --os)
    OS="$2"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

case "$OS" in
rocky)
  IMAGE=rockylinux:9
  ;;
alma)
  IMAGE=almalinux:9
  ;;
esac

cd ${__DIR__}
docker run --rm --name rhel-dev -d -v ${__PROJECT__}:/work -w /work $IMAGE tail -f /dev/null
