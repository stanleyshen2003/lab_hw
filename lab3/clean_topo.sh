#!/bin/bash

docker stop alice bob eve
docker rm alice bob eve

ip netns del alice
ip netns del bob
ip netns del eve

ip link del br0
ip link del vethbr-alice
ip link del vethbr-bob
ip link del vethbr-eve