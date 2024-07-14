#!/bin/bash

set -x
__DIR__=$(
  cd "$(dirname "$0")"
  pwd
)
__PROJECT__=$(
  cd ${__DIR__}/../../../
  pwd
)
cd ${__PROJECT__}

MIRROR=''
WITH_UPDATE=0

while [ $# -gt 0 ]; do
  case "$1" in
  --mirror)
    MIRROR="$2"
    ;;
  --update)
    WITH_UPDATE=1
    ;;
  --*)
    echo "Illegal option $1"
    ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

case "$MIRROR" in
china | ustc)
  export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"

  export HOMEBREW_PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
  export PIPENV_PYPI_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple"

  # pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
  # pip3 config set global.index-url https://pypi.python.org/simple

  # 参考文档： https://help.mirrors.cernet.edu.cn/homebrew/
  ;;
esac

export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_INSTALL_FROM_API=1

if [ ${WITH_UPDATE} -eq 1 ]; then
  case "$MIRROR" in
  china | ustc)
    brew tap --custom-remote --force-auto-update homebrew/cask https://mirrors.ustc.edu.cn/homebrew-cask.git
    brew tap --custom-remote --force-auto-update homebrew/cask-versions https://mirrors.ustc.edu.cn/homebrew-cask-versions.git
    brew tap --custom-remote --force-auto-update homebrew/services https://mirrors.ustc.edu.cn/homebrew-services.git

    # 参考文档： https://help.mirrors.cernet.edu.cn/homebrew/
    # reset
    # brew tap --custom-remote --force-auto-update homebrew/cask https://github.com/Homebrew/homebrew-cask
    # brew tap --custom-remote --force-auto-update homebrew/cask-versions https://github.com/Homebrew/homebrew-cask-versions
    # brew tap --custom-remote --force-auto-update homebrew/services https://mirrors.ustc.edu.cn/homebrew-services.git
    ;;
  esac

  brew update

  exit 0

fi

# 已安装的包 跳过安装
PACKAGES_1=(wget curl libtool automake re2c llvm flex bison)
PACKAGES_2=(libtool gettext coreutils libunistring pkg-config cmake)

PACKAGES=("${PACKAGES_1[@]}" "${PACKAGES_2[@]}")
for PACKAGE in "${PACKAGES[@]}"; do
  brew list "$PACKAGE" &>/dev/null || brew install "$PACKAGE"
done

which glibtool

brew install xz zip unzip gzip bzip2 7zip p7zip
brew install git ca-certificates

brew install diffutils
brew install socat
