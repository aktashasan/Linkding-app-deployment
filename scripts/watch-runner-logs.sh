#!/bin/bash

# GitHub Actions Self-Hosted Runner Log İzleme Scripti

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Runner dizinlerini bul
RUNNER_DIRS=(
    "$HOME/actions-runner"
    "/Users/$(whoami)/actions-runner"
    "/opt/actions-runner"
    "/usr/local/actions-runner"
)

RUNNER_DIR=""
for dir in "${RUNNER_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -f "$dir/run.sh" ]; then
        RUNNER_DIR="$dir"
        break
    fi
done

if [ -z "$RUNNER_DIR" ]; then
    echo -e "${RED}Runner dizini bulunamadı!${NC}"
    echo ""
    echo "Lütfen runner dizinini manuel olarak belirtin:"
    echo "  ./scripts/watch-runner-logs.sh /path/to/actions-runner"
    echo ""
    echo "Veya şu dizinlerde arayın:"
    for dir in "${RUNNER_DIRS[@]}"; do
        echo "  - $dir"
    done
    exit 1
fi

echo -e "${GREEN}Runner dizini bulundu: $RUNNER_DIR${NC}"
echo ""

# Log dizinini kontrol et
DIAG_DIR="$RUNNER_DIR/_diag"
if [ ! -d "$DIAG_DIR" ]; then
    echo -e "${YELLOW}Log dizini bulunamadı: $DIAG_DIR${NC}"
    echo "Runner henüz çalışmamış olabilir."
    exit 1
fi

# Menü göster
show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}GitHub Actions Runner Log İzleme${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "1. Runner loglarını izle (Runner_*.log)"
    echo "2. Worker loglarını izle (Worker_*.log)"
    echo "3. Service loglarını izle (Service_*.log)"
    echo "4. Tüm logları izle (hepsi birlikte)"
    echo "5. Son log dosyalarını listele"
    echo "6. Belirli bir log dosyasını izle"
    echo "7. Log dosyalarını temizle"
    echo "8. Çıkış"
    echo ""
}

# Log dosyalarını listele
list_logs() {
    echo -e "${GREEN}Log dosyaları:${NC}"
    echo ""
    if [ -d "$DIAG_DIR" ]; then
        ls -lht "$DIAG_DIR"/*.log 2>/dev/null | head -20 || echo "Log dosyası bulunamadı"
    else
        echo "Log dizini bulunamadı"
    fi
    echo ""
}

# Log izleme fonksiyonu
watch_logs() {
    local pattern=$1
    local description=$2
    
    echo -e "${GREEN}$description izleniyor...${NC}"
    echo "Çıkmak için Ctrl+C basın"
    echo ""
    
    # En son log dosyasını bul
    LATEST_LOG=$(ls -t "$DIAG_DIR"/$pattern 2>/dev/null | head -1)
    
    if [ -z "$LATEST_LOG" ]; then
        echo -e "${YELLOW}Log dosyası bulunamadı: $pattern${NC}"
        echo "Runner henüz çalışmamış olabilir."
        return 1
    fi
    
    echo -e "${BLUE}İzlenen dosya: $(basename $LATEST_LOG)${NC}"
    echo ""
    
    # Tail ile izle
    tail -f "$LATEST_LOG"
}

# Tüm logları izle
watch_all_logs() {
    echo -e "${GREEN}Tüm loglar izleniyor...${NC}"
    echo "Çıkmak için Ctrl+C basın"
    echo ""
    
    # Tüm log dosyalarını bul
    LOG_FILES=$(ls -t "$DIAG_DIR"/*.log 2>/dev/null | head -5)
    
    if [ -z "$LOG_FILES" ]; then
        echo -e "${YELLOW}Log dosyası bulunamadı${NC}"
        return 1
    fi
    
    echo -e "${BLUE}İzlenen dosyalar:${NC}"
    for file in $LOG_FILES; do
        echo "  - $(basename $file)"
    done
    echo ""
    
    # Tüm logları birlikte izle (multitail benzeri)
    tail -f $LOG_FILES
}

# Belirli log dosyasını izle
watch_specific_log() {
    list_logs
    
    echo -e "${YELLOW}İzlemek istediğiniz log dosyasının adını girin:${NC}"
    read -r log_file
    
    if [ -z "$log_file" ]; then
        echo -e "${RED}Dosya adı boş olamaz${NC}"
        return 1
    fi
    
    # Tam yol oluştur
    if [[ "$log_file" == /* ]]; then
        FULL_PATH="$log_file"
    else
        FULL_PATH="$DIAG_DIR/$log_file"
    fi
    
    if [ ! -f "$FULL_PATH" ]; then
        echo -e "${RED}Log dosyası bulunamadı: $FULL_PATH${NC}"
        return 1
    fi
    
    echo -e "${GREEN}İzleniyor: $FULL_PATH${NC}"
    echo "Çıkmak için Ctrl+C basın"
    echo ""
    
    tail -f "$FULL_PATH"
}

# Log dosyalarını temizle
clean_logs() {
    echo -e "${YELLOW}Log dosyalarını temizlemek istediğinizden emin misiniz? (y/N):${NC}"
    read -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Log dosyaları temizleniyor...${NC}"
        rm -f "$DIAG_DIR"/*.log
        echo -e "${GREEN}Log dosyaları temizlendi${NC}"
    else
        echo -e "${YELLOW}İşlem iptal edildi${NC}"
    fi
}

# Ana döngü
while true; do
    show_menu
    read -p "Seçiminiz (1-8): " choice
    echo ""
    
    case $choice in
        1)
            watch_logs "Runner_*.log" "Runner logları"
            ;;
        2)
            watch_logs "Worker_*.log" "Worker logları"
            ;;
        3)
            watch_logs "Service_*.log" "Service logları"
            ;;
        4)
            watch_all_logs
            ;;
        5)
            list_logs
            ;;
        6)
            watch_specific_log
            ;;
        7)
            clean_logs
            ;;
        8)
            echo -e "${GREEN}Çıkılıyor...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim!${NC}"
            ;;
    esac
    
    echo ""
    read -p "Devam etmek için Enter'a basın..."
    clear
done
