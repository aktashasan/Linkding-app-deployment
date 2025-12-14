#!/bin/bash

# Port 80 ve 443'ü kullanan servisleri durdurma scripti

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Checking ports 80 and 443...${NC}"

# Port 80 kontrolü
echo ""
echo -e "${YELLOW}Port 80:${NC}"
if sudo lsof -i :80 -P 2>/dev/null | head -5; then
    echo -e "${RED}Port 80 is in use. Processes:${NC}"
    sudo lsof -i :80 -P -t | while read pid; do
        echo "  PID: $pid - $(ps -p $pid -o comm= 2>/dev/null || echo 'unknown')"
    done
else
    echo -e "${GREEN}Port 80 is free${NC}"
fi

# Port 443 kontrolü
echo ""
echo -e "${YELLOW}Port 443:${NC}"
if sudo lsof -i :443 -P 2>/dev/null | head -5; then
    echo -e "${RED}Port 443 is in use. Processes:${NC}"
    sudo lsof -i :443 -P -t | while read pid; do
        echo "  PID: $pid - $(ps -p $pid -o comm= 2>/dev/null || echo 'unknown')"
    done
else
    echo -e "${GREEN}Port 443 is free${NC}"
fi

# macOS AirPlay Receiver kontrolü
echo ""
echo -e "${YELLOW}Checking macOS AirPlay Receiver...${NC}"
if launchctl list | grep -q "com.apple.AirPlayXPCHelper"; then
    echo -e "${YELLOW}AirPlay Receiver is running (may use port 80)${NC}"
    echo "To disable: System Settings > General > AirDrop & Handoff > AirPlay Receiver (turn off)"
fi

# Docker container kontrolü
echo ""
echo -e "${YELLOW}Checking Docker containers...${NC}"
if docker ps --format "{{.Ports}}" 2>/dev/null | grep -qE ":80->|:443->"; then
    echo -e "${RED}Docker containers using ports 80/443:${NC}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}" | grep -E ":80->|:443->"
else
    echo -e "${GREEN}No Docker containers using ports 80/443${NC}"
fi

echo ""
echo -e "${YELLOW}To free ports 80 and 443:${NC}"
echo "1. Stop processes using the ports (requires sudo):"
echo "   sudo kill -9 \$(sudo lsof -t -i:80)"
echo "   sudo kill -9 \$(sudo lsof -t -i:443)"
echo ""
echo "2. Disable AirPlay Receiver (macOS):"
echo "   System Settings > General > AirDrop & Handoff > AirPlay Receiver (turn off)"
echo ""
echo "3. Stop Docker containers (if any):"
echo "   docker ps | grep -E '80|443'"
echo "   docker stop <container-id>"
