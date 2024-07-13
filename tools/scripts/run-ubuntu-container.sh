#!/bin/bash

set -exu
__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)
__PROJECT__=$(
  cd ${__DIR__}/../../
  pwd
)
cd ${__DIR__}

{
  docker stop ubuntu-dev
  sleep 5
} || {
  echo $?
}
cd ${__DIR__}
IMAGE=ubuntu:22.04
IMAGE=ubuntu:23.10

MIRROR=''
while [ $# -gt 0 ]; do
  case "$1" in
  --mirror)
    MIRROR="$2"
    case "$MIRROR" in
      china | openatom)
        IMAGE="hub.atomgit.com/library/ubuntu:23.10"
        ;;
    esac
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

cd ${__DIR__}
docker run --rm --name ubuntu-dev -d -v ${__PROJECT__}:/work -w /work -e TZ='Etc/UTC' $IMAGE tail -f /dev/null
