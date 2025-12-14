#!/bin/bash

set -e

# Renkler için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="linkding"
DEPLOYMENT="linkding"

# Image tag kontrolü
if [ -z "$1" ]; then
    echo -e "${RED} Error: Image tag is required${NC}"
    echo "Usage: $0 <image-tag>"
    echo "Example: $0 v1.23.0"
    exit 1
fi

NEW_TAG="$1"
NEW_IMAGE="sissbruecker/linkding:${NEW_TAG}"

echo -e "${GREEN} Starting rolling update...${NC}"
echo -e "${YELLOW}New image: ${NEW_IMAGE}${NC}"
echo ""

# Mevcut image'i göster
CURRENT_IMAGE=$(kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}')
echo -e "${YELLOW}Current image: ${CURRENT_IMAGE}${NC}"
echo ""

# Image tag'ini güncelle
echo -e "${YELLOW} Updating deployment image...${NC}"
kubectl set image deployment/${DEPLOYMENT} linkding=${NEW_IMAGE} -n ${NAMESPACE}

# Rollout durumunu izle
echo -e "${YELLOW} Waiting for rollout to complete...${NC}"
if kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=300s; then
    echo ""
    echo -e "${GREEN} Rolling update completed successfully!${NC}"
else
    echo ""
    echo -e "${RED} Rolling update failed${NC}"
    echo "Checking deployment status..."
    kubectl describe deployment/${DEPLOYMENT} -n ${NAMESPACE}
    exit 1
fi

# Güncellenmiş image'i göster
UPDATED_IMAGE=$(kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}')
echo ""
echo -e "${GREEN} Deployment status:${NC}"
kubectl get deployment ${DEPLOYMENT} -n ${NAMESPACE}
echo ""
echo -e "${GREEN} Updated image: ${UPDATED_IMAGE}${NC}"
echo ""
echo -e "${YELLOW} Rollout history:${NC}"
kubectl rollout history deployment/${DEPLOYMENT} -n ${NAMESPACE}
echo ""
echo -e "${GREEN} Rolling update complete!${NC}"
