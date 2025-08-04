sudo ip netns add test
sudo ip link add testveth type veth peer name testveth2 netns test
sudo ip a a 192.168.99.1/24 dev testveth
sudo ip netns exec test ip a a 192.168.99.2/24 dev testveth2
sudo ip link set testveth up
sudo ip netns exec test ip link set testveth2 up
# ping 192.168.99.2
# sudo iptables -A OUTPUT -s 192.168.99.1 -j DROP
# ping 192.168.99.2
