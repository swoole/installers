## 查看扩展加载顺序

```bash

ls -lh `php --ini | grep  "Scan for additional .ini files in:" | awk -F 'in:' '{ print $2 }' | xargs`

```

## php.ini 配置文件中 curl、sockets、mysqld 扩展应该在 swoole 扩展之前加载

    https://github.com/swoole/swoole-src/issues/4085

    编译 php 时 扫描目录配置 --with-config-file-scan-dir

## 查看配置所在目录

```bash


php --ini | grep  ".ini files"

```

## 可能遇到的的问题

### $PATH 环境变量 未检测到php phpize php-config

通过临时修改 $PATH 环境变量,例子：
` export PATH=your-php-install-dir/bin/:$PATH`

### alpine 环境运行本脚本需要bash

> 第一次用 sh 执行脚本
> 第二次用 bash 执行脚本

```bash

  sh install.sh
  bash install.sh

```
