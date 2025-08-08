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
  docker stop archlinux-dev
  sleep 5
} || {
  echo $?
}
cd ${__DIR__}

IMAGE=archlinux:base

cd ${__DIR__}
docker run --rm --name archlinux-dev -d -v ${__PROJECT__}:/work -w /work -e TZ='Etc/UTC' $IMAGE tail -f /dev/null
