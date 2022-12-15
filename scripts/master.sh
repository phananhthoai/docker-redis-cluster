#!/usr/bin/env bash
set -ex

NAME_NET=$(ip route list | grep default | grep -Eo 'dev [a-z0-9]+' | awk '{print $2}')
IP_MASTER=$(ip addr show $NAME_NET | grep 'inet ' | sed -E 's/\s+inet ([0-9.]+)\/[0-9]+ .*/\1/g' | head -n 1)
REDIS_ROOT_PASS=${REDIS_ROOT_PASS:-password}

# If use docker run mysql no need use service redis-server start
#sudo service redis-server start

while :;
do
  if nc -z localhost 6379
  then
    break
  else
    sleep 2
  fi
done

sudo sed -i -E 's/^protected-mode no$/protected-mode yes/g' /etc/redis/redis.conf
#echo 'bind 0.0.0.0' >> /etc/redis/redis.conf
echo "masterauth \"$REDIS_ROOT_PASS\"" | sudo tee -a /etc/redis/redis.conf
#echo 'replicaof "%s" 6379' $IP_MASTER >> /etc/redis/redis.conf
echo "requirepass \"$REDIS_ROOT_PASS\"" | sudo tee -a /etc/redis/redis.conf

sudo service redis-server restart

echo "sentinel monitor redis-master \"$IP_MASTER\" 6379 2" | sudo tee -a /etc/redis/sentinel.conf
echo 'sentinel down-after-milliseconds redis-master 1500' | sudo tee -a /etc/redis/sentinel.conf
echo 'sentinel failover-timeout redis-master 3000' | sudo tee -a /etc/redis/sentinel.conf
echo 'protected-mode no' | sudo tee -a /etc/redis/sentinel.conf

sudo service redis-sentinel restart

echo 'info replication' | sudo redis-cli -a password
echo 'info sentinel' | sudo redis-cli -p 26379
