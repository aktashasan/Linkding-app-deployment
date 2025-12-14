#!/bin/bash

# Port 80 ve 443'ü kullanan process'leri durdurma scripti
# DİKKAT: Bu script port 80/443 kullanan tüm process'leri durdurur!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Freeing ports 80 and 443...${NC}"
echo ""

# Port 80
echo -e "${YELLOW}Port 80:${NC}"
PIDS_80=$(sudo lsof -t -i:80 2>/dev/null || echo "")
if [ -n "$PIDS_80" ]; then
    echo -e "${RED}Found processes using port 80:${NC}"
    echo "$PIDS_80" | while read pid; do
        echo "  PID: $pid - $(ps -p $pid -o comm= 2>/dev/null || echo 'unknown')"
    done
    echo ""
    read -p "Kill these processes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$PIDS_80" | xargs sudo kill -9 2>/dev/null || true
        echo -e "${GREEN}Port 80 processes killed${NC}"
    else
        echo "Skipped"
    fi
else
    echo -e "${GREEN}Port 80 is free${NC}"
fi

echo ""

# Port 443
echo -e "${YELLOW}Port 443:${NC}"
PIDS_443=$(sudo lsof -t -i:443 2>/dev/null || echo "")
if [ -n "$PIDS_443" ]; then
    echo -e "${RED}Found processes using port 443:${NC}"
    echo "$PIDS_443" | while read pid; do
        echo "  PID: $pid - $(ps -p $pid -o comm= 2>/dev/null || echo 'unknown')"
    done
    echo ""
    read -p "Kill these processes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$PIDS_443" | xargs sudo kill -9 2>/dev/null || true
        echo -e "${GREEN}Port 443 processes killed${NC}"
    else
        echo "Skipped"
    fi
else
    echo -e "${GREEN}Port 443 is free${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Note: If AirPlay Receiver is enabled, you may need to disable it:"
echo "  System Settings > General > AirDrop & Handoff > AirPlay Receiver (turn off)"
