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

echo ""
echo -e "${GREEN} Cleanup complete!${NC}"
echo ""
echo -e "${YELLOW} To delete the entire Kind cluster, run:${NC}"
echo "   kind delete cluster --name kind-cluster"
