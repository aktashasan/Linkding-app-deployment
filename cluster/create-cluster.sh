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

# Port 80 ve 443'ün kullanılabilir olduğunu kontrol et
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || \
       netstat -an 2>/dev/null | grep -q ":$port.*LISTEN" || \
       (command -v ss >/dev/null && ss -lnt 2>/dev/null | grep -q ":$port"); then
        return 1  # Port kullanımda
    fi
    return 0  # Port boş
}

PORT_80_AVAILABLE=true
PORT_443_AVAILABLE=true

if ! check_port 80; then
    PORT_80_AVAILABLE=false
    echo " Warning: Port 80 is already in use"
    echo " Creating temporary kind config without port 80 mapping..."
    
    # Geçici config dosyası oluştur (port mapping olmadan)
    TEMP_CONFIG="${SCRIPT_DIR}/kind-config-temp.yaml"
    KIND_CONFIG_FILE="$TEMP_CONFIG"
    cat > "$TEMP_CONFIG" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
EOF
    
    # Port 443 kullanılabilirse ekle
    if check_port 443; then
        cat >> "$TEMP_CONFIG" <<EOF
  extraPortMappings:
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
    fi
    
    echo " Note: Ingress will be accessible via LoadBalancer IP (cloud-provider-kind)"
    echo "       or you can use port-forward: kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80"
fi

if ! check_port 443; then
    PORT_443_AVAILABLE=false
    echo " Warning: Port 443 is already in use"
    echo " HTTPS Ingress may not work on port 443"
fi

if ! check_port 443; then
    echo " Warning: Port 443 is already in use"
    echo " HTTPS Ingress may not work on port 443"
    echo " Continuing anyway..."
fi

# Mevcut cluster varsa sil
if kind get clusters | grep -q "kind-cluster"; then
    echo " Existing cluster found. Deleting..."
    kind delete cluster --name kind-cluster
fi

# Cluster oluştur
echo " Creating Kind cluster..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
KIND_CONFIG_FILE="${SCRIPT_DIR}/kind-config.yaml"
TEMP_CONFIG=""

# Docker'ın hazır olduğundan emin ol
echo " Waiting for Docker to be ready..."
sleep 2

# Kind cluster oluştur
# --wait parametresi ile timeout artırıldı ve --retain ile hata durumunda cluster silinmez
echo " Creating cluster (this may take a few minutes)..."
if ! kind create cluster --config "${KIND_CONFIG_FILE}" --wait 10m --retain; then
    echo " Warning: Cluster creation encountered an issue"
    echo " Checking if cluster was partially created..."
    
    # Cluster'ın oluşup oluşmadığını kontrol et
    if kind get clusters | grep -q "kind-cluster"; then
        echo " Cluster exists, attempting to use it..."
        # Context'i kontrol et
        kubectl cluster-info --context kind-kind-cluster 2>/dev/null || kubectl cluster-info --context kind-cluster 2>/dev/null
        if [ $? -eq 0 ]; then
            echo " Cluster is accessible, continuing..."
        else
            echo " Error: Cluster exists but is not accessible"
            echo " Try deleting and recreating: kind delete cluster --name kind-cluster"
            exit 1
        fi
    else
        echo " Error: Cluster creation failed completely"
        echo " Troubleshooting steps:"
        echo " 1. Check Docker is running: docker ps"
        echo " 2. Try deleting any existing clusters: kind delete clusters --all"
        echo " 3. Check Docker resources: docker system df"
        exit 1
    fi
fi

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

# cloud-provider-kind kurulumu ve çalıştırma (LoadBalancer desteği için)
echo " Setting up cloud-provider-kind for LoadBalancer support..."

# cloud-provider-kind kurulu mu kontrol et
if ! command -v cloud-provider-kind &> /dev/null; then
    echo " cloud-provider-kind not found. Installing..."
    
    # Go kurulu mu kontrol et
    if ! command -v go &> /dev/null; then
        echo " Error: Go is required to install cloud-provider-kind"
        echo " Please install Go first:"
        echo "   macOS: brew install go"
        echo "   Linux: https://go.dev/doc/install"
        echo " Or use Homebrew (macOS): brew install cloud-provider-kind"
        exit 1
    fi
    
    # Go install ile cloud-provider-kind'ı kur
    echo " Installing cloud-provider-kind using go install..."
    go install sigs.k8s.io/cloud-provider-kind@latest
    
    # Binary'yi /usr/local/bin'e kopyala (sudo gerekir)
    if [ -f ~/go/bin/cloud-provider-kind ]; then
        echo " Installing cloud-provider-kind to /usr/local/bin (requires sudo)..."
        sudo install ~/go/bin/cloud-provider-kind /usr/local/bin
        if [ $? -eq 0 ]; then
            echo " cloud-provider-kind installed successfully"
        else
            echo " Warning: Failed to install to /usr/local/bin"
            echo " You can run it from: ~/go/bin/cloud-provider-kind"
        fi
    else
        echo " Error: cloud-provider-kind binary not found after installation"
        echo " Please install manually:"
        echo "   go install sigs.k8s.io/cloud-provider-kind@latest"
        echo "   sudo install ~/go/bin/cloud-provider-kind /usr/local/bin"
        exit 1
    fi
fi

# cloud-provider-kind'ı başlat (sudo gerekir)
if command -v cloud-provider-kind &> /dev/null; then
    echo " Starting cloud-provider-kind (for LoadBalancer support)..."
    echo " Note: This requires sudo privileges"
    
    # Önce çalışan bir instance var mı kontrol et
    if pgrep -f "cloud-provider-kind" > /dev/null; then
        echo " cloud-provider-kind is already running"
    else
        # Arka planda başlat
        sudo cloud-provider-kind &>/dev/null &
        CLOUD_PROVIDER_PID=$!
        sleep 2
        
        # Başarılı başladı mı kontrol et
        if pgrep -f "cloud-provider-kind" > /dev/null; then
            echo " cloud-provider-kind started successfully (PID: $CLOUD_PROVIDER_PID)"
        else
            echo " Warning: Could not start cloud-provider-kind"
            echo " You may need to run it manually:"
            echo "   sudo cloud-provider-kind"
        fi
    fi
else
    echo " Error: cloud-provider-kind is not available"
    exit 1
fi

# Ingress controller service'ini yapılandır
# cloud-provider-kind ile LoadBalancer desteği aktif
# Port mapping (80:80, 443:443) kind-config.yaml'da tanımlı
echo " Ingress Controller configured (port mapping: 80:80, 443:443)"
echo " LoadBalancer support enabled via cloud-provider-kind"

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

# Geçici config dosyasını temizle
if [ -n "$TEMP_CONFIG" ] && [ -f "$TEMP_CONFIG" ]; then
    echo " Cleaning up temporary config file..."
    rm -f "$TEMP_CONFIG"
fi

echo " Cluster created successfully!"
echo ""
if [ "$PORT_80_AVAILABLE" = "false" ]; then
    echo " Note: Port 80 was in use, cluster created without port mapping"
    echo "       Access Ingress via:"
    echo "       1. LoadBalancer IP (cloud-provider-kind): kubectl get svc -n ingress-nginx"
    echo "       2. Port-forward: kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80"
    echo ""
fi
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
