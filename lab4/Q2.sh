#!/bin/bash
set -e

# Clean up old containers
docker rm -f alice bob wgserver 2>/dev/null || true

# Base image with WireGuard installed (Debian-based)
BASE_IMAGE="ghcr.io/linuxserver/wireguard"

# 1. Run containers with no network
docker run -dit --name wgserver --network none --cap-add NET_ADMIN --cap-add SYS_MODULE --sysctl net.ipv4.ip_forward=1 $BASE_IMAGE
docker run -dit --name alice    --network none --cap-add NET_ADMIN --cap-add SYS_MODULE $BASE_IMAGE
docker run -dit --name bob      --network none --cap-add NET_ADMIN --cap-add SYS_MODULE $BASE_IMAGE

# Get PIDs for each container
PID_WG=$(docker inspect -f '{{.State.Pid}}' wgserver)
PID_ALICE=$(docker inspect -f '{{.State.Pid}}' alice)
PID_BOB=$(docker inspect -f '{{.State.Pid}}' bob)

ln -s /proc/$PID_ALICE/ns/net /var/run/netns/$PID_ALICE
ln -s /proc/$PID_BOB/ns/net /var/run/netns/$PID_BOB
ln -s /proc/$PID_WG/ns/net /var/run/netns/$PID_WG




# Create veth pairs and assign to containers
# alice ↔ wgserver
ip link add veth-al type veth peer name veth-wg-a
ip link set veth-al netns $PID_ALICE
ip link set veth-wg-a netns $PID_WG

# bob ↔ wgserver
ip link add veth-bo type veth peer name veth-wg-b
ip link set veth-bo netns $PID_BOB
ip link set veth-wg-b netns $PID_WG

# Configure IPs
# Alice
ip netns exec $PID_ALICE ip addr add 192.168.1.1/24 dev veth-al
ip netns exec $PID_ALICE ip link set veth-al up
ip netns exec $PID_ALICE ip link set lo up

# Bob
ip netns exec $PID_BOB ip addr add 192.168.2.1/24 dev veth-bo
ip netns exec $PID_BOB ip link set veth-bo up
ip netns exec $PID_BOB ip link set lo up

# WG server
ip netns exec $PID_WG ip addr add 192.168.1.2/24 dev veth-wg-a
ip netns exec $PID_WG ip addr add 192.168.2.2/24 dev veth-wg-b
ip netns exec $PID_WG ip link set veth-wg-a up
ip netns exec $PID_WG ip link set veth-wg-b up
ip netns exec $PID_WG ip link set lo up

# WireGuard setup
# Generate keys
WG_SERVER_PRIV=$(wg genkey)
WG_SERVER_PUB=$(echo $WG_SERVER_PRIV | wg pubkey)

BOB_PRIV=$(wg genkey)
BOB_PUB=$(echo $BOB_PRIV | wg pubkey)

# WG server interface
ip netns exec $PID_WG ip link add wg0 type wireguard
ip netns exec $PID_WG ip addr add 192.168.3.254/24 dev wg0
ip netns exec $PID_WG wg set wg0 private-key <(echo $WG_SERVER_PRIV)
ip netns exec $PID_WG wg set wg0 listen-port 51820 peer $BOB_PUB allowed-ips 0.0.0.0/0
ip netns exec $PID_WG ip link set wg0 up


# Bob WireGuard interface
ip netns exec $PID_BOB ip link add wg0 type wireguard
ip netns exec $PID_BOB ip addr add 192.168.3.1/24 dev wg0
ip netns exec $PID_BOB wg set wg0 private-key <(echo $BOB_PRIV)
ip netns exec $PID_BOB wg set wg0 listen-port 51820 peer $WG_SERVER_PUB allowed-ips 0.0.0.0/0 endpoint 192.168.2.2:51820
ip netns exec $PID_BOB ip link set wg0 up

sleep 1
ip netns exec $PID_BOB ip r add default via 192.168.3.254 dev wg0
ip netns exec $PID_ALICE ip r add default via 192.168.1.2


echo "✅ Topology is ready!"
echo "Alice PID: $PID_ALICE"
echo "Bob PID: $PID_BOB"
echo "WG server PID: $PID_WG"
