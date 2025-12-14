#!/bin/bash

set -e

# Renkler için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN} Starting Linkding deployment setup...${NC}"

# Script'in bulunduğu dizini bul
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# kubectl'in kurulu olup olmadığını kontrol et
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED} Error: kubectl is not installed${NC}"
    exit 1
fi

# Cluster erişimini doğrula
echo -e "${YELLOW} Verifying cluster access...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED} Error: Cannot access Kubernetes cluster${NC}"
    echo "Please make sure the cluster is running and kubectl is configured correctly"
    exit 1
fi

# Node'ları listele
echo -e "${GREEN} Cluster access verified${NC}"
echo ""
echo -e "${YELLOW} Cluster nodes:${NC}"
kubectl get nodes
echo ""

# StorageClass kontrolü ve oluşturma
echo -e "${YELLOW} Checking StorageClass...${NC}"
if ! kubectl get storageclass local-path &>/dev/null; then
    echo -e "${YELLOW} Creating local-path StorageClass...${NC}"
    kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF
fi

# Tüm manifestleri apply et
echo -e "${YELLOW} Applying Kubernetes manifests...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests.yaml"

# PostgreSQL'in hazır olmasını bekle
echo -e "${YELLOW} Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n linkding || {
    echo -e "${RED} PostgreSQL deployment failed${NC}"
    kubectl describe deployment/postgres -n linkding
    kubectl logs -l app=postgres -n linkding --tail=50
    exit 1
}


# Linkding'in hazır olmasını bekle
echo -e "${YELLOW} Waiting for Linkding to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/linkding -n linkding || {
    echo -e "${RED} Linkding deployment failed${NC}"
    kubectl describe deployment/linkding -n linkding
    kubectl logs -l app=linkding -n linkding --tail=50
    exit 1
}

# Superuser oluştur (eğer yoksa)
echo -e "${YELLOW} Creating superuser...${NC}"
sleep 5  # Linkding'in tamamen hazır olması için bekle
kubectl exec -n linkding deployment/linkding -c linkding -- python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print('Superuser created: admin/admin')
else:
    user = User.objects.get(username='admin')
    user.set_password('admin')
    user.save()
    print('Superuser password reset to: admin')
" 2>&1 | grep -E "(Superuser|created|reset)" || echo "Superuser setup completed"

# Durum raporu
echo ""
echo -e "${GREEN} Deployment completed successfully!${NC}"
echo ""
echo -e "${YELLOW} Deployment status:${NC}"
kubectl get all -n linkding
echo ""
echo -e "${YELLOW} Ingress status:${NC}"
kubectl get ingress -n linkding
echo ""

# Pod durumlarını kontrol et
echo -e "${YELLOW} Pod status:${NC}"
kubectl get pods -n linkding
echo ""

# Erişim bilgileri
echo -e "${GREEN} Access Information:${NC}"
echo ""
echo "To access the application via Ingress:"
echo "1. Add to /etc/hosts (macOS/Linux):"
echo "   echo '127.0.0.1 linkding.local' | sudo tee -a /etc/hosts"
echo ""
echo "2. Open in browser: http://linkding.local"
echo ""
echo "Alternative: Port-forward"
echo "  ./scripts/port-forward.sh"
echo "  Then: http://localhost:9090"
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: admin (change on first login)"
echo ""

echo ""
echo -e "${GREEN} Setup complete!${NC}"
