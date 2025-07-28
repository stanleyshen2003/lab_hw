FROM ubuntu:latest

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install iproute2 and isc-dhcp-client
RUN apt update && \
    apt install -y iproute2 isc-dhcp-client && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

