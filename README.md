# Swoole Installer

一行命令给PHP安装上 swoole 扩展

## 用法

From https://www.swoole.com:

```bash

curl -fsSL  https://github.com/swoole/installers/blob/main/install.sh?raw=true | bash -s -- --latest --swoole-version=v5.1.3

```

From https://github.com/swoole/installers:

```bash

curl -fsSL  https://github.com/swoole/installers/blob/main/install.sh?raw=true | bash -s -- --mirror china --latest

```

From https://gitee.com/jingjingxyk/swoole-install:

```bash

curl -fsSL  https://gitee.com/jingjingxyk/swoole-install/raw/main/install.sh | bash -s -- --mirror china --latest

# 使用系统包管理工具安装 php
curl -fsSL  https://gitee.com/jingjingxyk/swoole-install/raw/main/install.sh | bash -s -- --mirror china --latest --install-php

```

## $PATH 环境变量 未检测到php phpize php-config

通过临时修改 $PATH 环境变量,例子：
` export PATH=php-install-dir/bin/:$PATH`

## rhel 系 、alpine、archlinux  解决 `which` command no found

```bash

curl -fsSL  https://github.com/swoole/installers/blob/main/init.sh?raw=true | bash

# mirror

curl -fsSL  https://gitee.com/jingjingxyk/swoole-install/raw/main/init.sh  | bash

```

## 支持的操作系统

| 操作系统                                                         | 支持情况 |
|--------------------------------------------------------------|------|
| [debian](https://www.debian.org/)                            | ✅    |
| [ubuntu](https://ubuntu.com/)                                | ✅    |
| [rockylinux](https://rockylinux.org/)                        | ✅    |
| [almalinux](https://almalinux.org/)                          | ✅    |
| [Alibaba cloud liunx](https://www.aliyun.com/product/alinux) | ✅    |
| [anolis](https://openanolis.cn/anolisos)                     | ✅    |
| [fedora ](https://fedoraproject.org/)                        | ✅    |
| [alpine](https://www.alpinelinux.org/)                       | ✅    |
| [kali](https://www.kali.org/)                                | ✅    |
| [macos](https://www.apple.com/)                              | ✅    |
| wsl                                                          |      |
| FreeBSD 13                                                   |      |
| [OpenEuler](https://www.openeuler.org/)                      | ✅    |
| Huawei Cloud EulerOS                                         | ✅    |
| [archlinux](https://archlinux.org/)                          | ✅    |
