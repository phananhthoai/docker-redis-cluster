#!/usr/bin/env bash
set -ex

if [ $(id -u) != 0 ]; then
  sudo ${0}
  exit 0
fi

IP_SLAVE=$(ip addr show eth0 | grep 'inet ' | sed -E 's/\s+inet ([0-9.]+)\/[0-9]+ .*/\1/g' | head -n 1)
IP_MASTER=${IP_MASTER:-}
REDIS_ROOT_PASS=${REDIS_ROOT_PASS:-password}

# Input IP master change "dig +short master"

if [ -z $IP_MASTER ]; then
  IP_MASTER="10.127.220.246"
fi

# If use docker run mysql no need use service redis-server start
#service redis-server start

while ! nc -z localhost 6379; do
  sleep 2
done


#sed -i -E 's/^protected-mode no$/protected-mode yes/g' /etc/redis/redis.conf

#echo 'bind 0.0.0.0' >> /etc/redis/redis.conf
echo "masterauth \"$REDIS_ROOT_PASS\"" | tee -a /etc/redis/redis.conf
echo "slaveof  \"$IP_MASTER\" 6379" | tee -a /etc/redis/redis.conf
echo "requirepass \"$REDIS_ROOT_PASS\"" | tee -a /etc/redis/redis.conf


service redis-server restart

echo "sentinel monitor master \"$IP_MASTER\" 6379 2" | tee /etc/redis/sentinel.conf
echo 'sentinel down-after-milliseconds master 10000' | tee -a /etc/redis/sentinel.conf
echo 'sentinel failover-timeout master 10000' | tee -a /etc/redis/sentinel.conf
echo 'sentinel parallel-syncs master 1' | tee -a /etc/redis/sentinel.conf
echo 'sentinel auth-pass master password' | tee -a /etc/redis/sentinel.conf
echo 'protected-mode no' | tee -a /etc/redis/sentinel.conf

service redis-sentinel restart

echo 'info replication' | redis-cli -a password
echo 'info sentinel' | redis-cli -p 26379
