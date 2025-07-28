FROM ubuntu:latest

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install iproute2 and isc-dhcp-server
RUN apt update && \
    apt install -y iproute2 isc-dhcp-server && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Create required directories
RUN mkdir -p /var/lib/dhcp /etc/dhcp

RUN touch /var/lib/dhcp/dhcpd.leases

# Copy default config (optional — replace with your own)
COPY dhcpd.conf /etc/dhcp/dhcpd.conf

# Expose DHCP UDP port
EXPOSE 67/udp

# Default command to run the DHCP server in the foreground with logs to stdout
CMD ["sleep", "infinity"]
