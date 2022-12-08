#!/usr/bin/env bash
set -ex

#IP_MASTER=$(ip addr show eth0 | grep 'inet ' | sed -E 's/\s+inet ([0-9.]+)\/[0-9]+ .*/\1/g' | head -n 1)
REDIS_ROOT_PASS=${REDIS_ROOT_PASS:-password}

while :;
do
  if nc -z localhost 6379
  then
    break
  else
    sleep 2
  fi
done

sed -i -E 's/^protected-mode no$/protected-mode yes/g' /etc/redis/redis.conf
#echo 'bind 0.0.0.0' >> /etc/redis/redis.conf
echo "masterauth \"$REDIS_ROOT_PASS\"" >> /etc/redis/redis.conf
#echo 'replicaof "%s" 6379' $IP_MASTER >> /etc/redis/redis.conf
echo "requirepass \"$REDIS_ROOT_PASS\"" >> /etc/redis/redis.conf

service redis-server restart