#!/usr/bin/env bash
set -ex


IP_SLAVE=$(ip addr show eth0 | grep 'inet ' | sed -E 's/\s+inet ([0-9.]+)\/[0-9]+ .*/\1/g' | head -n 1)
IP_MASTER=${IP_MASTER:-}
REDIS_ROOT_PASS=${REDIS_ROOT_PASS:-password}
if [ -z $IP_MASTER ]; then
  IP_MASTER=$(dig +short master)
fi

while :; 
do
  if nc -z localhost 6379
  then
    break
  else
    sleep 3
  fi
done


while :; 
do
  if nc -z ${IP_MASTER} 6379
  then
    break
  else
    sleep 1
  fi
done

sed -i -E 's/^protected-mode no$/protected-mode yes/g' /etc/redis/redis.conf

#echo 'bind 0.0.0.0' >> /etc/redis/redis.conf
echo "masterauth \"$REDIS_ROOT_PASS\"" >> /etc/redis/redis.conf
echo "slaveof  \"$IP_MASTER\" 6379" >> /etc/redis/redis.conf
echo "requirepass \"$REDIS_ROOT_PASS\"" >> /etc/redis/redis.conf


service redis-server restart

echo "sentinel monitor redis-master \"$IP_MASTER\" 6379 2" >> /etc/redis/sentinel.conf
echo 'sentinel down-after-milliseconds redis-master 1500' >> /etc/redis/sentinel.conf
echo 'sentinel failover-timeout redis-master 3000' >> /etc/redis/sentinel.conf
echo 'protected-mode no' >> /etc/redis/sentinel.conf

service redis-sentinel restart

echo 'info replication' | redis-cli -a password
echo 'info sentinel' | redis-cli -p 26379