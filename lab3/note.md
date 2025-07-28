1. Docker create ubuntu:latest

```bash
docker run --rm --name dhcp-server --network none ubuntu:latest sleep 99999
```

2. Add docker ns to sudo ip netns

```bash
# Get PID of container
docker inspect -f '{{ .State.Pid }}' dhcp-server
xxxxxx
# Create link
mkdir -p /var/run/netns
rm -f /var/run/netns/dhcp-server
sudo ln -s /proc/`docker inspect -f  '{{ .State.Pid }}' dhcp-server`/ns/net \
  /var/run/netns/dhcp-server
# Verify
sudo ip netns exec dhcp-server sudo ip -br l
```

3. Create link topology

```bash
# Create bridge
sudo ip link add br0 type bridge
# Create veth and add to bridge and container
sudo ip link add vethbr-dhcp master br0 type veth peer name vethdhcp-br \
  netns dhcp-server
# Verify
sudo ip netns exec dhcp-server sudo ip -br l
```

4. Setup sudo ip Address

```bash
# Enable device
sudo ip link set vethbr-dhcp up
sudo ip netns exec dhcp-server ip link set vethdhcp-br up

# Set IP 
sudo ip netns exec dhcp-server ip a a 192.168.0.254/24 dev vethdhcp-br
```

5. Install iproute2 on container

```bash
docker exec dhcp-server /bin/sh -c 'apt update -y && apt install -y iproute2'

#Verify everything is good
docker exec dhcp-server ip -br a
```

6. Install and configure DHCP

```bash
docker exec dhcp-server /bin/sh -c 'apt update -y && apt install -y isc-dhcp-server'

docker exec dhcp-server /bin/sh -c 'touch /var/lib/dhcp/dhcpd.leases && cat <<EOF > /etc/dhcp/dhcpd.conf

subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.100 192.168.0.200;
  option subnet-mask 255.255.255.0;
  option routers 192.168.0.254;
  ping-check true;
  default-lease-time 259200;
  max-lease-time 604800;
}

EOF'

# Open TMUX
tmux

# Create split view
Ctrl B + %

# Focus on Current pane
Ctrl B + z

# Run DHCP server
docker exec -it dhcp-server /usr/sbin/dhcpd -f
```
