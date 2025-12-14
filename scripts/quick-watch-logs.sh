#!/bin/bash

# Hızlı log izleme - En son log dosyasını otomatik izler

set -e

# Runner dizinlerini bul
RUNNER_DIRS=(
    "$HOME/actions-runner"
    "/Users/$(whoami)/actions-runner"
    "/opt/actions-runner"
    "/usr/local/actions-runner"
)

RUNNER_DIR=""
for dir in "${RUNNER_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -d "$dir/_diag" ]; then
        RUNNER_DIR="$dir"
        break
    fi
done

if [ -z "$RUNNER_DIR" ]; then
    echo "❌ Runner dizini bulunamadı!"
    echo ""
    echo "Kullanım: $0 [runner-dizini]"
    exit 1
fi

DIAG_DIR="$RUNNER_DIR/_diag"

# En son log dosyasını bul
LATEST_LOG=$(ls -t "$DIAG_DIR"/*.log 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "❌ Log dosyası bulunamadı"
    echo "Runner henüz çalışmamış olabilir."
    exit 1
fi

echo "📋 İzlenen dosya: $(basename $LATEST_LOG)"
echo "📍 Konum: $LATEST_LOG"
echo "🛑 Çıkmak için Ctrl+C basın"
echo ""
echo "=========================================="
echo ""

# Tail ile izle
tail -f "$LATEST_LOG"
