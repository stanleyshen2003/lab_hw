#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

docker run -d --name alice --network none dhcpserver
docker run -d --name bob --network none dhcpclient
docker run -d --name eve --network none dhcpclient

ln -s /proc/`docker inspect -f  '{{ .State.Pid }}' alice`/ns/net \
  /var/run/netns/alice
ln -s /proc/`docker inspect -f  '{{ .State.Pid }}' bob`/ns/net \
  /var/run/netns/bob
ln -s /proc/`docker inspect -f  '{{ .State.Pid }}' eve`/ns/net \
  /var/run/netns/eve

ip link add br0 type bridge

ip link add vethbr-alice master br0 type veth peer name vethalice-br netns alice
ip link add vethbr-bob master br0 type veth peer name vethbob-br netns bob
ip link add vethbr-eve master br0 type veth peer name vetheve-br netns eve

ip link set br0 up
ip link set vethbr-alice up
ip link set vethbr-bob up
ip link set vethbr-eve up

ip netns exec alice ip addr add 192.168.1.254/24 dev vethalice-br
ip netns exec eve ip addr add 192.168.1.250/24 dev vetheve-br

ip netns exec alice ip link set vethalice-br up
ip netns exec bob ip link set vethbob-br up
ip netns exec eve ip link set vetheve-br up

docker exec alice /usr/sbin/dhcpd
# ip netns exec bob dhclient vethbob-br
