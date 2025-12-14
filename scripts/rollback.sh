#!/bin/bash

set -e

# Renkler için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="linkding"
DEPLOYMENT="linkding"

echo -e "${GREEN} Starting rollback...${NC}"
echo ""

# Mevcut image'i göster
CURRENT_IMAGE=$(kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}')
echo -e "${YELLOW}Current image: ${CURRENT_IMAGE}${NC}"
echo ""

# Rollout geçmişini göster
echo -e "${YELLOW} Rollout history:${NC}"
kubectl rollout history deployment/${DEPLOYMENT} -n ${NAMESPACE}
echo ""

# Rollback yap
echo -e "${YELLOW} Rolling back to previous revision...${NC}"
kubectl rollout undo deployment/${DEPLOYMENT} -n ${NAMESPACE}

# Rollback durumunu izle
echo -e "${YELLOW} Waiting for rollback to complete...${NC}"
if kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=300s; then
    echo ""
    echo -e "${GREEN} Rollback completed successfully!${NC}"
else
    echo ""
    echo -e "${RED} Rollback failed${NC}"
    echo "Checking deployment status..."
    kubectl describe deployment/${DEPLOYMENT} -n ${NAMESPACE}
    exit 1
fi

# Geri dönülen image'i göster
ROLLBACK_IMAGE=$(kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}')
echo ""
echo -e "${GREEN} Deployment status:${NC}"
kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE}
echo ""
echo -e "${GREEN} Rolled back to image: ${ROLLBACK_IMAGE}${NC}"
echo ""
echo -e "${YELLOW} Updated rollout history:${NC}"
kubectl rollout history deployment/${DEPLOYMENT} -n ${NAMESPACE}
echo ""
echo -e "${GREEN} Rollback complete!${NC}"
