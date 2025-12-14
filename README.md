# Kubernetes Deployment - Linkding Application

Bu proje, Kubernetes ortamı kurulumu, uygulama deployment'ı ve otomasyon adımlarını içermektedir.

## 📋 İçindekiler

- [Genel Bakış](#genel-bakış)
- [Gereksinimler](#gereksinimler)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Rolling Update ve Rollback](#rolling-update-ve-rollback)
- [Kullanılan Araçlar](#kullanılan-araçlar)
- [Bilinen Sorunlar](#bilinen-sorunlar)
- [Screenshot ve Video Gereksinimleri](#screenshot-ve-video-gereksinimleri)

## 🎯 Genel Bakış

Bu proje aşağıdaki bileşenleri içermektedir:

- **Kubernetes Ortamı**: Kind (Kubernetes in Docker) kullanılarak kurulmuş mini Kubernetes cluster
- **Uygulama**: Linkding - Modern, açık kaynak bookmark manager
- **Kubernetes Objeleri**:
  - Deployment (Linkding + PostgreSQL)
  - Service (ClusterIP)
  - ConfigMap
  - Secret
  - Ingress
  - PVC (PersistentVolumeClaim)
- **Otomasyon**: setup.sh scripti ile otomatik kurulum
- **Rolling Update & Rollback**: Image tag değiştirerek güncelleme ve geri alma

## 📦 Gereksinimler

Aşağıdaki araçların sisteminizde kurulu olması gerekmektedir:

- **Docker Desktop** veya **Docker Engine** (20.10+)
- **kubectl** (v1.28+)
- **kind** (v0.20+)
- **curl** veya **wget**

### Kurulum Komutları

#### macOS
```bash
# Homebrew ile
brew install kind kubectl docker

# Docker Desktop'u manuel olarak indirin: https://www.docker.com/products/docker-desktop
```

#### Linux
```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Docker
# Docker kurulumu için: https://docs.docker.com/engine/install/
```

## 🚀 Kurulum

### 1. Repository'yi Klonlayın

```bash
git clone <repository-url>
cd case-study
```

### 2. Cluster'ı Oluşturun

```bash
./cluster/create-cluster.sh
```

Bu script:
- Kind cluster'ı oluşturur
- NGINX Ingress Controller'ı kurar
- Cluster'ın hazır olduğunu doğrular

### 3. Uygulamayı Deploy Edin

```bash
./setup.sh
```

Bu script:
- Cluster erişimini doğrular (`kubectl get nodes`)
- Tüm manifestleri apply eder
- Pod'ların hazır olmasını bekler
- Ingress erişimini test eder

### 4. Uygulamaya Erişin

Kind cluster'ında LoadBalancer çalışmaz, ancak Ingress controller port mapping ile çalışır. 

**Kind Config'de port mapping tanımlı:**
- Host port 80 → Container port 80
- Host port 443 → Container port 443

**Erişim için:**

1. `/etc/hosts` dosyasını yapılandırın:
```bash
# macOS/Linux
echo "127.0.0.1 linkding.local" | sudo tee -a /etc/hosts

# Windows (PowerShell as Administrator)
Add-Content C:\Windows\System32\drivers\etc\hosts "127.0.0.1 linkding.local"
```

2. Tarayıcıda açın:
- **http://linkding.local**

**Not:** Kind'ta LoadBalancer service tipi çalışmaz (cloud provider yok), ancak `kind-config.yaml`'da tanımlı port mapping sayesinde direkt erişim mümkündür.

**Varsayılan Kullanıcı Bilgileri:**
- Username: `admin`
- Password: `admin` (ilk girişte değiştirmeniz önerilir)

## 📝 Kullanım

### Cluster Durumunu Kontrol Etme

```bash
# Node'ları listele
kubectl get nodes

# Tüm pod'ları listele
kubectl get pods -A

# Namespace'deki kaynakları listele
kubectl get all -n linkding

# Service ve Ingress'i listele
kubectl get svc,ingress -n linkding
```

### Logları Görüntüleme

```bash
# Linkding pod logları
kubectl logs -f deployment/linkding -n linkding

# PostgreSQL pod logları
kubectl logs -f deployment/postgres -n linkding
```

### ConfigMap ve Secret'ları Görüntüleme

```bash
# ConfigMap
kubectl get configmap linkding-config -n linkding -o yaml

# Secret (base64 decode edilmiş)
kubectl get secret linkding-secret -n linkding -o jsonpath='{.data}' | jq -r 'to_entries[] | "\(.key): \(.value | @base64d)"'
```

## 🔄 Rolling Update ve Rollback

### Rolling Update

Yeni bir image versiyonuna geçmek için:

```bash
./scripts/rolling-update.sh v1.23.0
```

Bu script:
- Deployment'ın image tag'ini günceller
- Rolling update'i başlatır
- Update durumunu izler

### Rollback

Önceki versiyona dönmek için:

```bash
./scripts/rollback.sh
```

Bu script:
- Son rollout'u geri alır
- Rollback durumunu izler

### Manuel Rollout Komutları

```bash
# Rolling update başlat
kubectl set image deployment/linkding linkding=sissbruecker/linkding:v1.23.0 -n linkding

# Rollout durumunu izle
kubectl rollout status deployment/linkding -n linkding

# Rollback yap
kubectl rollout undo deployment/linkding -n linkding

# Rollout geçmişini görüntüle
kubectl rollout history deployment/linkding -n linkding
```

## 🛠️ Kullanılan Araçlar

- **Kind**: Kubernetes cluster'ı Docker container'ları içinde çalıştırmak için
- **NGINX Ingress Controller**: Ingress trafiğini yönetmek için
- **Linkding**: Deploy edilen açık kaynak bookmark manager uygulaması
- **PostgreSQL**: Linkding'in veritabanı backend'i
- **kubectl**: Kubernetes cluster'ı yönetmek için

## ⚠️ Bilinen Sorunlar

1. **Port-Forward Gereksinimi**: Kind cluster'ında LoadBalancer çalışmadığı için uygulamaya erişmek için port-forward kullanılması gerekmektedir. `./scripts/port-forward.sh` scripti ile kolayca erişilebilir.

2. **PVC Storage Class**: Kind cluster'ında Local Path Provisioner otomatik olarak kurulur ve `local-path` storage class'ı kullanılır. `manifests/pvc.yaml` dosyasında `storageClassName: local-path` tanımlıdır.

3. **Superuser Oluşturma**: İlk kurulumda superuser otomatik olarak oluşturulur. Eğer oluşturulmazsa, manuel olarak `kubectl exec` komutu ile oluşturulabilir.

4. **Resource Limits**: Geliştirme ortamı için resource limit'ler minimum seviyede tutulmuştur. Production ortamında artırılmalıdır.

5. **Migration'lar**: İlk kurulumda Django migration'ları otomatik çalıştırılmaz. Eğer gerekirse manuel olarak çalıştırılabilir.

## 📸 Screenshot ve Video Gereksinimleri

Proje dokümantasyonu için aşağıdaki screenshot'lar veya video kayıtları örnek olarak verilebilir:

1. ✅ `kubectl get nodes` çıktısı
2. ✅ `kubectl get pods -A` çıktısı (tüm pod'lar Running durumunda)
3. ✅ `kubectl get svc,ingress -n linkding` çıktısı
4. ✅ Tarayıcıda `http://linkding.local` erişimi
5. ✅ Rolling update süreci (`kubectl rollout status`)
6. ✅ Rollback süreci (`kubectl rollout undo`)

### Screenshot Alma

```bash
# Terminal çıktılarını kaydet
kubectl get nodes > screenshots/nodes.txt
kubectl get pods -A > screenshots/pods.txt
kubectl get svc,ingress -n linkding > screenshots/services.txt
kubectl rollout status deployment/linkding -n linkding > screenshots/rolling-update.txt
```

## 🔗 Ingress ile Erişim

Kind cluster'ında Ingress controller port mapping ile çalışır. Erişim için:

1. `/etc/hosts` dosyasına ekleyin:
```bash
# macOS/Linux
echo "127.0.0.1 linkding.local" | sudo tee -a /etc/hosts

# Windows (PowerShell as Administrator)
Add-Content C:\Windows\System32\drivers\etc\hosts "127.0.0.1 linkding.local"
```

2. Tarayıcıda açın: **http://linkding.local**

**Alternatif: Port-Forward (Ingress kullanmak istemezseniz)**

```bash
./scripts/port-forward.sh
# Sonra: http://localhost:9090
```

## 🧹 Temizleme

Cluster'ı ve tüm kaynakları temizlemek için:

```bash
./scripts/cleanup.sh
```

Bu script:
- Tüm Kubernetes kaynaklarını siler
- Kind cluster'ı siler

## 📚 Ek Kaynaklar

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Linkding GitHub](https://github.com/sissbruecker/linkding)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

## 📄 Lisans

Bu proje Kubernetes öğrenme ve pratik yapma amaçlı hazırlanmıştır.
