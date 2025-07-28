from scapy.all import sniff, BOOTP, DHCP

def dhcp_monitor(pkt):
    print(f"Packet captured: {pkt.summary()}")
    if DHCP in pkt and BOOTP in pkt:
        dhcp_message_type = pkt[DHCP].options[0][1]
        msg_types = {
            1: "Discover",
            2: "Offer",
            3: "Request",
            5: "ACK"
        }
        print(f"[+] DHCP {msg_types.get(dhcp_message_type, 'Other')} detected")
        print(pkt.summary())

# Sniff DHCP packets on your interface (e.g., "eth0")
sniff(filter="udp and (port 67 or port 68)", prn=dhcp_monitor, store=0)
