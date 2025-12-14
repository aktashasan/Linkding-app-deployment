#!/bin/bash

# Fresh installation script - Baştan kurulum için

set -e

# Renkler için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN} Starting fresh installation...${NC}"
echo ""

# Mevcut kaynakları temizle
echo -e "${YELLOW} Step 1: Cleaning existing resources...${NC}"
if kubectl get namespace linkding &> /dev/null; then
    echo "Deleting linkding namespace..."
    kubectl delete namespace linkding --wait=true --timeout=60s || true
fi

# Cluster'ı sil ve yeniden oluştur
echo ""
echo -e "${YELLOW} Step 2: Recreating cluster...${NC}"
cd "${SCRIPT_DIR}/cluster"
if kind get clusters | grep -q "kind-cluster"; then
    echo "Deleting existing cluster..."
    kind delete cluster --name kind-cluster
fi

echo "Creating new cluster..."
./create-cluster.sh

# Uygulamayı deploy et
echo ""
echo -e "${YELLOW} Step 3: Deploying application...${NC}"
cd "${SCRIPT_DIR}"
./setup.sh

echo ""
echo -e "${GREEN} Fresh installation completed!${NC}"
echo ""
echo "To access the application:"
echo "  ./scripts/port-forward.sh"
echo ""
echo "Then open: http://localhost:9090"
echo "Login: admin / admin"
