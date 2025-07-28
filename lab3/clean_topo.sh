#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

docker stop alice bob eve
docker rm alice bob eve

ip netns del alice
ip netns del bob
ip netns del eve

ip link del br0
ip link del vethbr-alice
ip link del vethbr-bob
ip link del vethbr-eve