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
  docker stop php-debian-dev
  sleep 5
} || {
  echo $?
}
cd ${__DIR__}

IMAGE=php:8.1-zts-bullseye


while [ $# -gt 0 ]; do
  case "$1" in
  --php-image)
    IMAGE="$2"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

cd ${__DIR__}
docker run --rm --name php-debian-dev -d -v ${__PROJECT__}:/work -w /work $IMAGE tail -f /dev/null
