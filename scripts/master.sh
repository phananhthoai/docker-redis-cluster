#!/usr/bin/env bash
set -ex

if [ $(id -u) != 0 ]; then
  sudo ${0}
  exit 0
fi

NAME_NET=$(ip route list | grep default | grep -Eo 'dev [a-z0-9]+' | awk '{print $2}')
IP_MASTER=$(ip addr show $NAME_NET | grep 'inet ' | sed -E 's/\s+inet ([0-9.]+)\/[0-9]+ .*/\1/g' | head -n 1)
REDIS_ROOT_PASS=${REDIS_ROOT_PASS:-password}

# If use docker run mysql no need use service redis-server start
#sudo service redis-server start

while ! nc -z localhost 6379; do
  sleep 2
done

#while ! ping -c 1 google.xyz >>/dev/null; do
#  sleep 1
#done

#if ping -c 1 google.xyz &>/dev/null; then
#  echo Success
#else
#  echo Failed
#fi

#echo "Ping Google $(ping -c 1 google.xyz &>/dev/null && echo Success || echo Failed)"

#DOCKER_VERSION=${DOCKER_VERSION:-}
#echo "apt install docker.io $([ -z ${DOCKER_VERSION} ] || echo "--version ${DOCKER_VERSION}")"

#MYSQL_PASSWORD=${MYSQL_PASSWORD:-$(openssl rand -base64 6)}
#echo "Password: ${MYSQL_PASSWORD}"

#sudo sed -i -E 's/^protected-mode no$/protected-mode yes/g' /etc/redis/redis.conf
#echo 'bind 0.0.0.0' >> /etc/redis/redis.conf
echo "masterauth \"$REDIS_ROOT_PASS\"" | tee -a /etc/redis/redis.conf
#echo 'replicaof "%s" 6379' $IP_MASTER >> /etc/redis/redis.conf
echo "requirepass \"$REDIS_ROOT_PASS\"" | tee -a /etc/redis/redis.conf

service redis-server restart

echo "sentinel monitor master \"$IP_MASTER\" 6379 2" | tee /etc/redis/sentinel.conf
echo 'sentinel down-after-milliseconds master 10000' | tee -a /etc/redis/sentinel.conf
echo 'sentinel failover-timeout master 100000' | tee -a /etc/redis/sentinel.conf
echo 'sentinel parallel-syncs master 1' | tee -a /etc/redis/sentinel.conf
echo 'sentinel auth-pass master password' | tee -a /etc/redis/sentinel.conf
echo 'protected-mode no' | tee -a /etc/redis/sentinel.conf

service redis-sentinel restart

echo 'info replication' | redis-cli -a password
echo 'info sentinel' | redis-cli -p 26379
