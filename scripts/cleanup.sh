#!/bin/bash

set -e

# Renkler için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="linkding"

echo -e "${YELLOW} Starting cleanup...${NC}"
echo ""

# Namespace'deki tüm kaynakları sil
if kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}  Deleting all resources in namespace ${NAMESPACE}...${NC}"
    kubectl delete namespace ${NAMESPACE} --wait=true --timeout=60s || {
        echo -e "${YELLOW}  Some resources may still be terminating. This is normal.${NC}"
    }
    echo -e "${GREEN} Namespace ${NAMESPACE} deleted${NC}"
else
    echo -e "${YELLOW} Namespace ${NAMESPACE} does not exist${NC}"
fi

# cloud-provider-kind process'ini durdur
echo ""
echo -e "${YELLOW} Stopping cloud-provider-kind...${NC}"
if pgrep -f "cloud-provider-kind" > /dev/null; then
    CLOUD_PROVIDER_PIDS=$(pgrep -f "cloud-provider-kind")
    echo -e "${YELLOW} Found cloud-provider-kind process(es): ${CLOUD_PROVIDER_PIDS}${NC}"
    for pid in $CLOUD_PROVIDER_PIDS; do
        if sudo kill -9 $pid 2>/dev/null; then
            echo -e "${GREEN} Stopped cloud-provider-kind (PID: $pid)${NC}"
        else
            echo -e "${YELLOW} Could not stop cloud-provider-kind (PID: $pid) - may require sudo${NC}"
            echo "   Run manually: sudo kill -9 $pid"
        fi
    done
else
    echo -e "${YELLOW} cloud-provider-kind is not running${NC}"
fi

echo ""
echo -e "${GREEN} Cleanup complete!${NC}"
echo ""
echo -e "${YELLOW} To delete the entire Kind cluster, run:${NC}"
echo "   kind delete cluster --name kind-cluster"
echo ""
echo -e "${YELLOW} Note: If cloud-provider-kind is still running, stop it manually:${NC}"
echo "   sudo pkill -9 cloud-provider-kind"
