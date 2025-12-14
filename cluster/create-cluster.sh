#!/bin/bash

set -e

echo " Creating Kind cluster..."

# Kind'in kurulu olup olmadığını kontrol et
if ! command -v kind &> /dev/null; then
    echo " Error: kind is not installed"
    echo "Please install kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Docker'ın çalışıp çalışmadığını kontrol et
if ! docker info &> /dev/null; then
    echo " Error: Docker is not running"
    echo "Please start Docker Desktop or Docker Engine"
    exit 1
fi

# Mevcut cluster varsa sil
if kind get clusters | grep -q "kind-cluster"; then
    echo " Existing cluster found. Deleting..."
    kind delete cluster --name kind-cluster
fi

# Cluster oluştur
echo " Creating Kind cluster..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
kind create cluster --config "${SCRIPT_DIR}/kind-config.yaml"

# kubectl context'ini ayarla
# Kind, cluster adına göre context oluşturur: kind-{cluster-name}
kubectl cluster-info --context kind-kind-cluster || kubectl cluster-info --context kind-cluster

# Local Path Provisioner kurulumu (PVC için gerekli)
echo " Installing Local Path Provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

# Local Path StorageClass'ı kontrol et ve oluştur
if ! kubectl get storageclass local-path &>/dev/null; then
    echo " Creating local-path StorageClass..."
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
else
    echo " Local Path StorageClass already exists, setting as default..."
    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
fi

# Local Path Provisioner'ın hazır olmasını bekle
echo " Waiting for Local Path Provisioner to be ready..."
sleep 5  # Pod'ların oluşması için bekle
if kubectl wait --namespace local-path-storage \
  --for=condition=ready pod \
  --selector=app=local-path-provisioner \
  --timeout=60s 2>&1; then
    echo " Local Path Provisioner is ready"
else
    echo " Warning: Local Path Provisioner may not be ready yet"
    kubectl get pods -n local-path-storage
fi

# NGINX Ingress Controller kurulumu
echo " Installing NGINX Ingress Controller..."
INGRESS_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"

# Manifest'i apply et
echo " Applying Ingress Controller manifest..."
if ! kubectl apply -f "$INGRESS_URL" 2>&1; then
    echo " ERROR: Failed to apply Ingress Controller manifest"
    echo " Please check your network connection"
    exit 1
fi
echo " Manifest applied successfully"

# Biraz bekle (kaynakların oluşması için)
echo " Waiting for resources to be created..."
sleep 10

# Deployment'ın oluştuğunu kontrol et ve bekle
echo " Waiting for Ingress Controller deployment..."
DEPLOYMENT_FOUND=false
for i in {1..30}; do
    if kubectl get deployment ingress-nginx-controller -n ingress-nginx &>/dev/null; then
        echo " Deployment found!"
        DEPLOYMENT_FOUND=true
        break
    fi
    echo " Waiting for deployment... ($i/30)"
    sleep 2
done

if [ "$DEPLOYMENT_FOUND" = false ]; then
    echo " ERROR: Deployment not found after 60 seconds"
    echo " Attempting to apply manifest again..."
    kubectl apply -f "$INGRESS_URL"
    sleep 10
    if ! kubectl get deployment ingress-nginx-controller -n ingress-nginx &>/dev/null; then
        echo " ERROR: Still cannot find deployment"
        echo " Please check manually: kubectl get all -n ingress-nginx"
    fi
fi

# Pod'ların hazır olmasını bekle
echo " Waiting for Ingress Controller pods to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s || {
    echo " Warning: Ingress Controller pods may not be ready yet"
    kubectl get pods -n ingress-nginx
}

# Node'u ingress-ready olarak label'la (Kind için gerekli)
echo " Labeling node for ingress..."
kubectl label node kind-cluster-control-plane ingress-ready=true --overwrite || echo "Node already labeled"

# cloud-provider-kind kontrolü ve çalıştırma (opsiyonel)
if command -v cloud-provider-kind &> /dev/null; then
    echo " Starting cloud-provider-kind (for LoadBalancer support)..."
    echo " Note: This requires sudo privileges"
    sudo cloud-provider-kind &>/dev/null &
    CLOUD_PROVIDER_PID=$!
    if [ $? -eq 0 ]; then
        echo " cloud-provider-kind started in background (PID: $CLOUD_PROVIDER_PID)"
        sleep 2
    else
        echo " Warning: Could not start cloud-provider-kind. You may need to run it manually:"
        echo "   sudo cloud-provider-kind"
    fi
else
    echo " cloud-provider-kind not found. To install:"
    echo "   macOS: brew install cloud-provider-kind"
    echo "   Linux: go install sigs.k8s.io/cloud-provider-kind@latest"
    echo "         sudo install ~/go/bin/cloud-provider-kind /usr/local/bin"
    echo " Then run: sudo cloud-provider-kind"
fi

# Ingress controller service'ini yapılandır
# Kind'ta LoadBalancer çalışmaz, ama port mapping (80:80, 443:443) zaten tanımlı
# Service tipi önemli değil, port mapping otomatik çalışır
echo " Ingress Controller configured (port mapping: 80:80, 443:443)"

# Ingress Controller'ın kurulu olduğunu doğrula
echo " Final verification: Ingress Controller installation..."
if ! kubectl get deployment ingress-nginx-controller -n ingress-nginx &>/dev/null; then
    echo " ERROR: Ingress Controller deployment not found!"
    echo " Attempting emergency installation..."
    INGRESS_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"
    kubectl apply -f "$INGRESS_URL"
    echo " Waiting for deployment to be created..."
    sleep 15
    if kubectl get deployment ingress-nginx-controller -n ingress-nginx &>/dev/null; then
        echo " Emergency installation successful"
        echo " Waiting for pods to be ready..."
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=120s 2>&1 || echo " Pods may still be starting..."
    else
        echo " ERROR: Failed to install Ingress Controller"
        echo " Please install manually:"
        echo "   kubectl apply -f $INGRESS_URL"
    fi
else
    echo " Ingress Controller deployment verified"
    # Pod'ların hazır olduğundan emin ol
    if ! kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --field-selector=status.phase=Running &>/dev/null; then
        echo " Waiting for Ingress Controller pods to be ready..."
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=60s 2>&1 || echo " Pods may still be starting..."
    fi
fi

echo " Cluster created successfully!"
echo ""
echo " Cluster information:"
kubectl get nodes
echo ""
echo " Ingress Controller status:"
if kubectl get namespace ingress-nginx &>/dev/null; then
    kubectl get pods -n ingress-nginx
else
    echo " Ingress Controller namespace not found"
fi
echo ""
echo " Next step: Run './setup.sh' to deploy the application"
