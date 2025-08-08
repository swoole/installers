#!/usr/bin/env bash

set -x
__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)
cd ${__DIR__}

# use china mirror
# sh tools/scripts/archilinux-init.sh --mirror [ china | ustc | tuna ]

MIRROR=''
while [ $# -gt 0 ]; do
  case "$1" in
  --mirror)
    MIRROR="$2"
    ;;
  --*)
    echo "no found mirror option $1"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

case "$MIRROR" in
china | ustc)
  test -f /etc/pacman.d/mirrorlist || cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.save
  grep 'mirrors.ustc.edu.cn' /etc/pacman.d/mirrorlist
  result=$?
  if [ $result -ne 0 ]; then
    sed -i.bak '1i Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
  fi
  ;;
tuna) #
  test -f /etc/pacman.d/mirrorlist || cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.save
  grep 'mirrors.tuna.tsinghua.edu.cn' /etc/pacman.d/mirrorlist
  result=$?
  if [ $result -ne 0 ]; then
    sed -i.bak '1i Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
  fi
  ;;

esac

pacman -Syyu --noconfirm

pacman -Sy --noconfirm git curl wget openssl xz zip unzip ca-certificates which

# 搜索包
pacman -Ss php
