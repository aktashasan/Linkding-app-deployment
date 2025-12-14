#!/bin/bash

# GitHub Actions Self-Hosted Runner Job Durdurma Scripti

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}GitHub Actions Runner Job Durdurma${NC}"
echo ""

# Yöntem 1: GitHub UI'dan Cancel (Önerilen)
echo -e "${GREEN}Yöntem 1: GitHub UI'dan Cancel (Önerilen)${NC}"
echo "1. GitHub Repository'ye gidin"
echo "2. Actions sekmesine tıklayın"
echo "3. Çalışan workflow'u bulun"
echo "4. 'Cancel workflow' butonuna tıklayın"
echo ""

# Yöntem 2: Runner process'lerini bul ve durdur
echo -e "${GREEN}Yöntem 2: Runner Process'lerini Durdur (Zorla)${NC}"
echo "Çalışan runner process'lerini arıyorum..."
echo ""

# Runner process'lerini bul
RUNNER_PIDS=$(ps aux | grep -i "actions-runner" | grep -v grep | awk '{print $2}' || true)

if [ -z "$RUNNER_PIDS" ]; then
    echo -e "${YELLOW}Runner process bulunamadı${NC}"
else
    echo -e "${YELLOW}Bulunan runner process'ler:${NC}"
    ps aux | grep -i "actions-runner" | grep -v grep
    echo ""
    
    read -p "Bu process'leri durdurmak istiyor musunuz? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for pid in $RUNNER_PIDS; do
            echo -e "${YELLOW}Durduruluyor: PID $pid${NC}"
            kill -TERM $pid 2>/dev/null || kill -9 $pid 2>/dev/null
            sleep 1
            if ps -p $pid > /dev/null 2>&1; then
                echo -e "${RED}Process durmadı, zorla durduruluyor...${NC}"
                kill -9 $pid 2>/dev/null || true
            fi
        done
        echo -e "${GREEN}Runner process'leri durduruldu${NC}"
    else
        echo -e "${YELLOW}İşlem iptal edildi${NC}"
    fi
fi

echo ""

# Yöntem 3: Runner servisini durdur
echo -e "${GREEN}Yöntem 3: Runner Servisini Durdur${NC}"
if [ -f "/Users/$(whoami)/actions-runner/svc.sh" ]; then
    RUNNER_DIR="/Users/$(whoami)/actions-runner"
    echo "Runner dizini bulundu: $RUNNER_DIR"
    echo ""
    read -p "Runner servisini durdurmak istiyor musunuz? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$RUNNER_DIR"
        sudo ./svc.sh stop || ./svc.sh stop || echo "Servis durdurulamadı (manuel kontrol gerekebilir)"
        echo -e "${GREEN}Runner servisi durduruldu${NC}"
    fi
elif [ -f "$HOME/actions-runner/svc.sh" ]; then
    RUNNER_DIR="$HOME/actions-runner"
    echo "Runner dizini bulundu: $RUNNER_DIR"
    echo ""
    read -p "Runner servisini durdurmak istiyor musunuz? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$RUNNER_DIR"
        sudo ./svc.sh stop || ./svc.sh stop || echo "Servis durdurulamadı (manuel kontrol gerekebilir)"
        echo -e "${GREEN}Runner servisi durduruldu${NC}"
    fi
else
    echo -e "${YELLOW}Runner dizini bulunamadı${NC}"
    echo "Manuel olarak runner dizinine gidin ve şu komutu çalıştırın:"
    echo "  sudo ./svc.sh stop"
    echo "  veya"
    echo "  ./svc.sh stop"
fi

echo ""

# Yöntem 4: Docker build process'lerini durdur
echo -e "${GREEN}Yöntem 4: Docker Build Process'lerini Durdur${NC}"
DOCKER_BUILD_PIDS=$(ps aux | grep -i "docker build" | grep -v grep | awk '{print $2}' || true)

if [ -z "$DOCKER_BUILD_PIDS" ]; then
    echo -e "${YELLOW}Docker build process bulunamadı${NC}"
else
    echo -e "${YELLOW}Bulunan Docker build process'ler:${NC}"
    ps aux | grep -i "docker build" | grep -v grep
    echo ""
    read -p "Bu Docker build process'lerini durdurmak istiyor musunuz? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for pid in $DOCKER_BUILD_PIDS; do
            echo -e "${YELLOW}Durduruluyor: PID $pid${NC}"
            kill -TERM $pid 2>/dev/null || kill -9 $pid 2>/dev/null
        done
        echo -e "${GREEN}Docker build process'leri durduruldu${NC}"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Notlar:${NC}"
echo "1. GitHub UI'dan cancel etmek en güvenli yöntemdir"
echo "2. Process'leri zorla durdurmak veri kaybına neden olabilir"
echo "3. Runner servisini durdurmak tüm job'ları durdurur"
echo "4. Runner'ı tekrar başlatmak için: sudo ./svc.sh start"
echo -e "${GREEN}========================================${NC}"
