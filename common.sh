#!/usr/bin/env bash

set -ex

export DEBIAN_FRONTEND=noninteractive

apt update

apt install -y systemd systemd-sysv kmod coreutils lsb-release wget curl zip unzip tar busybox iputils-ping iproute2 net-tools jq gnupg2 netcat bind9-dnsutils openssh-client git binutils ripgrep bash-completion

apt install -y redis-server redis-sentinel

curl https://getmic.ro | bash && mv micro /usr/local/bin

sed -i -E 's/^bind [0-9.]+ :+[0-9]$/bind 0.0.0.0/g' /etc/redis/redis.conf

sed -i -E 's/^bind [0-9.]+ :+[0-9]$/bind 0.0.0.0/g' /etc/redis/sentinel.conf
