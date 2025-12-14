# Kubernetes Deployment - Linkding Application

Bu proje, Kubernetes ortamı kurulumu, uygulama deployment'ı, otomasyon ve CI/CD pipeline'ını içeren kapsamlı bir Kubernetes deployment örneğidir.

## 📋 İçindekiler

- [Genel Bakış](#-genel-bakış)
- [Proje Yapısı](#-proje-yapısı)
- [Gereksinimler](#-gereksinimler)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Rolling Update ve Rollback](#-rolling-update-ve-rollback)
- [Kullanılan Araçlar](#-kullanılan-araçlar)
- [Bilinen Sorunlar ve Çözümler](#-bilinen-sorunlar-ve-çözümler)
- [Temizleme](#-temizleme)
- [Ek Kaynaklar](#-ek-kaynaklar)

## 🎯 Genel Bakış

Bu proje aşağıdaki bileşenleri içermektedir:

### Kubernetes Ortamı
- **Kind (Kubernetes in Docker)**: Lokal Kubernetes cluster
- **NGINX Ingress Controller**: HTTP/HTTPS trafik yönetimi
- **Local Path Provisioner**: Dinamik PVC sağlama

### Uygulama Stack
- **Linkding**: Modern, açık kaynak bookmark manager uygulaması
- **PostgreSQL**: Linkding'in veritabanı backend'i

### Kubernetes Objeleri
- ✅ **Deployment**: Linkding ve PostgreSQL için
- ✅ **Service (ClusterIP)**: İç servis keşfi
- ✅ **ConfigMap**: Uygulama konfigürasyonları
- ✅ **Secret**: Hassas bilgiler (şifreler)
- ✅ **Ingress**: Dış erişim için
- ✅ **PVC (PersistentVolumeClaim)**: PostgreSQL veri kalıcılığı
- ✅ **Namespace**: Kaynak izolasyonu

### Otomasyon
- ✅ **setup.sh**: Otomatik kurulum scripti
- ✅ **Rolling Update**: Image tag değiştirerek güncelleme
- ✅ **Rollback**: Önceki versiyona geri dönme
- ✅ **CI/CD Pipeline**: GitHub Actions ile otomatik build ve deploy

## 📁 Proje Yapısı

```
.
├── README.md                    # Bu dosya
├── QUICKSTART.md                # Hızlı başlangıç rehberi
├── TROUBLESHOOTING.md           # Sorun giderme rehberi
├── ROADMAP.md                   # Proje planı
│
├── setup.sh                     # Ana kurulum scripti
├── manifests.yaml               # Tüm Kubernetes manifestleri (birleştirilmiş)
│
├── cluster/
│   ├── kind-config.yaml         # Kind cluster yapılandırması
│   └── create-cluster.sh        # Cluster oluşturma scripti
│
├── scripts/
│   ├── rolling-update.sh        # Rolling update scripti
│   ├── rollback.sh              # Rollback scripti
│   ├── cleanup.sh               # Temizleme scripti
│
├── linkding-source/             # Linkding kaynak kodu (git submodule)
│   └── docker/
│       └── default.Dockerfile   # Dockerfile
│
└── .github/
    └── workflows/
        └── ci-cd.yml            # GitHub Actions CI/CD pipeline
```

## 📦 Gereksinimler

### Zorunlu Araçlar

Aşağıdaki araçların sisteminizde kurulu olması gerekmektedir:

| Araç | Minimum Versiyon | Açıklama |
|------|------------------|----------|
| **Docker** | 20.10+ | Container runtime |
| **kubectl** | v1.28+ | Kubernetes CLI |
| **kind** | v0.20+ | Kubernetes in Docker |
| **git** | 2.0+ | Version control |

### Opsiyonel Araçlar

- **cloud-provider-kind**: LoadBalancer desteği için (opsiyonel)
- **jq**: JSON parsing için (opsiyonel)

### Kurulum Komutları

#### macOS

```bash
# Homebrew ile
brew install kind kubectl docker

# Docker Desktop'u manuel olarak indirin:
# https://www.docker.com/products/docker-desktop

# Opsiyonel: go (cloud-provider-kind otomatik kurulacak)
# macOS: brew install go
# Linux: https://go.dev/doc/install
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

# Go (cloud-provider-kind otomatik kurulacak)
# Go kurulumu için: https://go.dev/doc/install
```

## 🚀 Kurulum

### Detaylı Kurulum Adımları

#### 1. Repository'yi Klonlayın

```bash
git clone https://github.com/aktashasan/Linkding-app-deployment.git
cd Linkding-app-deployment
```

#### 2. Git Submodule'ları Güncelleyin

Linkding kaynak kodu git submodule olarak eklenmiştir:

```bash
git submodule update --init --recursive
```

#### 3. Cluster'ı Oluşturun

```bash
sudo ./cluster/create-cluster.sh
```

**Not:** Script `cloud-provider-kind` kurulumu ve başlatılması için sudo gerektirir.

Bu script:
- ✅ Kind cluster'ı oluşturur (`kind-cluster`)
- ✅ Local Path Provisioner kurar (PVC desteği için)
- ✅ NGINX Ingress Controller kurar
- ✅ cloud-provider-kind kurar ve başlatır (LoadBalancer desteği için)
- ✅ Node'u ingress-ready olarak label'lar
- ✅ Cluster'ın hazır olduğunu doğrular

**Beklenen süre:** 2-5 dakika

#### 4. Uygulamayı Deploy Edin

```bash
./setup.sh
```

Bu script:
- ✅ Cluster erişimini doğrular (`kubectl get nodes`)
- ✅ Manifestleri apply eder
- ✅ Temel otomasyonu sağlar
- ✅ Cluster erişimini doğrular (`kubectl get nodes`)
- ✅ StorageClass'ı kontrol eder/oluşturur
- ✅ Tüm Kubernetes manifestlerini apply eder
- ✅ PostgreSQL'in hazır olmasını bekler
- ✅ Linkding'in hazır olmasını bekler
- ✅ Veritabanını oluşturur (gerekirse)
- ✅ Django migration'larını çalıştırır
- ✅ Superuser oluşturur/reset eder (admin/admin)

**Beklenen süre:** 3-5 dakika

#### 5. Uygulamaya Erişin

**Ingress ile Erişim (Önerilen):**

1. **LoadBalancer IP'yi alın:**
   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```

2. **`/etc/hosts` dosyasını yapılandırın:**
   ```bash
   # macOS/Linux - LoadBalancer IP ile
   LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   sudo sed -i.bak '/linkding.local/d' /etc/hosts
   echo "$LB_IP linkding.local" | sudo tee -a /etc/hosts
   
   # Alternatif: Eğer port mapping varsa (port 80 boşsa)
   # echo "127.0.0.1 linkding.local" | sudo tee -a /etc/hosts
   
   # Windows (PowerShell as Administrator)
   # $LB_IP = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   # (Get-Content C:\Windows\System32\drivers\etc\hosts) | Where-Object { $_ -notmatch 'linkding.local' } | Set-Content C:\Windows\System32\drivers\etc\hosts
   # Add-Content C:\Windows\System32\drivers\etc\hosts "$LB_IP linkding.local"
   ```

3. **Tarayıcıda açın:**
   - **http://linkding.local**

**Not:** `cloud-provider-kind` sayesinde Kind cluster'ında LoadBalancer service tipi desteklenmektedir. Cluster kurulumu sırasında otomatik olarak kurulur ve başlatılır. Port 80 mapping olmadığında LoadBalancer IP kullanılmalıdır.

**Varsayılan Kullanıcı Bilgileri:**
- **Username:** `admin`
- **Password:** `admin` (ilk girişte değiştirmeniz önerilir)

## 📝 Kullanım

### Cluster Durumunu Kontrol Etme

```bash
# Node'ları listele
kubectl get nodes

# Tüm pod'ları listele
kubectl get pods -A

# Namespace'deki tüm kaynakları listele
kubectl get all -n linkding

# Service ve Ingress'i listele
kubectl get svc,ingress -n linkding

# Deployment durumunu kontrol et
kubectl get deployment -n linkding
```

### Logları Görüntüleme

```bash
# Linkding pod logları
kubectl logs -f deployment/linkding -n linkding

# PostgreSQL pod logları
kubectl logs -f deployment/postgres -n linkding



### ConfigMap ve Secret'ları Görüntüleme

```bash
# ConfigMap
kubectl get configmap linkding-config -n linkding -o yaml

# Secret (base64 decode edilmiş)
kubectl get secret linkding-secret -n linkding -o jsonpath='{.data}' | \
  jq -r 'to_entries[] | "\(.key): \(.value | @base64d)"'
```

### Pod'lara Erişim

```bash
# Linkding pod'una shell aç
kubectl exec -it deployment/linkding -n linkding -c linkding -- /bin/bash

# PostgreSQL pod'una shell aç
kubectl exec -it deployment/postgres -n linkding -- /bin/bash

# Komut çalıştır
kubectl exec deployment/linkding -n linkding -c linkding -- python manage.py shell
```

## 🔄 Rolling Update ve Rollback

### Rolling Update

Yeni bir image versiyonuna geçmek için:

```bash
./scripts/rolling-update.sh v1.23.0
```

Bu script:
- ✅ Mevcut image'ı gösterir
- ✅ Deployment'ın image tag'ini günceller
- ✅ Rolling update'i başlatır (pod'lar sırayla güncellenir)
- ✅ Update durumunu izler (5 dakika timeout)
- ✅ Başarılı olursa yeni image'ı gösterir
- ✅ Rollout history'yi gösterir

**Örnek:**
```bash
# Mevcut: sissbruecker/linkding:1.22.0
# Yeni: sissbruecker/linkding:1.23.0
./scripts/rolling-update.sh v1.23.0
```

### Rollback

Önceki versiyona dönmek için:

```bash
./scripts/rollback.sh
```

Bu script:
- ✅ Rollout geçmişini gösterir
- ✅ Son rollout'u geri alır
- ✅ Rollback durumunu izler (5 dakika timeout)
- ✅ Başarılı olursa rollback edilen image'ı gösterir
- ✅ Güncellenmiş rollout history'yi gösterir

### Manuel Rollout Komutları

```bash
kubectl set image deployment/linkding \
  linkding=sissbruecker/linkding:v1.23.0 \
  -n linkding

kubectl rollout status deployment/linkding -n linkding

kubectl rollout undo deployment/linkding -n linkding

kubectl rollout undo deployment/linkding -n linkding --to-revision=2

kubectl rollout history deployment/linkding -n linkding

```

## 🔧 CI/CD Pipeline

Bu proje GitHub Actions ile CI/CD pipeline içermektedir.

### Özellikler

- ✅ **Docker Image Build**: Linkding kaynak kodundan image build
- ✅ **Multi-Platform Support**: linux/amd64 ve linux/arm64
- ✅ **Docker Hub Push**: Build edilen image'ı registry'ye push
- ✅ **Kubernetes Deploy**: Otomatik rolling update
- ✅ **Self-Hosted Runner**: Lokal cluster'a deploy için

### Kurulum

Detaylı kurulum için: [CI-CD-SETUP.md](CI-CD-SETUP.md)

**Gerekli GitHub Secrets:**
- `DOCKER_USERNAME`: Docker Hub kullanıcı adı
- `DOCKER_PASSWORD`: Docker Hub access token
- `REGISTRY`: Registry adresi (örn: `docker.io`)
- `APPLICATION_NAME`: Uygulama adı (örn: `linkding`)
- `NAMESPACE`: Kubernetes namespace (örn: `linkding`)
- `DEPLOYMENT`: Deployment adı (örn: `linkding`)
- `KUBECONFIG`: Kubernetes cluster config (base64 encoded) 

### Self-Hosted Runner Kurulumu

Lokal cluster'a deploy için self-hosted runner gerekir:

Detaylı kurulum için: [SELF-HOSTED-RUNNER-SETUP.md](SELF-HOSTED-RUNNER-SETUP.md)

### Workflow Kullanımı

**Otomatik Trigger:**
- `main` branch'ine push (sadece belirli dosyalarda değişiklik olduğunda)
- `linkding-source/` klasöründe değişiklik
- `manifests.yaml` dosyasında değişiklik
- `.github/workflows/ci-cd.yml` dosyasında değişiklik

**Manuel Trigger:**
1. GitHub → Actions → CI/CD Pipeline
2. Run workflow
3. Image tag girin (örn: `v1.23.0`)

### Workflow Adımları

1. **Checkout code**: Repository ve submodule'ları checkout eder
2. **Check linkding-source**: Linkding kaynak kodunu kontrol eder/clone eder
3. **Docker Build**: Multi-platform image build eder
4. **Docker Push**: Docker Hub'a push eder
5. **Kubernetes Deploy**: Rolling update ile deploy eder (KUBECONFIG varsa)
6. **Verify**: Deployment durumunu kontrol eder

## 🛠️ Kullanılan Araçlar

| Araç | Versiyon | Amaç |
|------|----------|------|
| **Kind** | v0.20+ | Kubernetes cluster'ı Docker container'ları içinde çalıştırmak |
| **NGINX Ingress Controller** | Latest | Ingress trafiğini yönetmek |
| **Local Path Provisioner** | v0.0.24 | Dinamik PVC sağlama |
| **Linkding** | 1.22.0+ | Deploy edilen açık kaynak bookmark manager |
| **PostgreSQL** | 15-alpine | Linkding'in veritabanı backend'i |
| **kubectl** | v1.28+ | Kubernetes cluster'ı yönetmek |
| **Docker** | 20.10+ | Container runtime |

## ⚠️ Bilinen Sorunlar ve Çözümler

### 1. PVC Bind Edilemedi

**Sorun:** `pod has unbound immediate PersistentVolumeClaims`

**Çözüm:** Local Path Provisioner otomatik kurulur. Eğer sorun devam ederse:
```bash
kubectl get storageclass
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### 2. PostgreSQL Veritabanı Bulunamadı

**Sorun:** `FATAL: database "linkding" does not exist`

**Çözüm:** `setup.sh` scripti otomatik olarak veritabanını oluşturur. Manuel oluşturmak için:
```bash
kubectl exec -n linkding deployment/postgres -- psql -U linkding -d postgres -c "CREATE DATABASE linkding;"
```

### 3. Django Migration'ları Çalışmadı

**Sorun:** `relation "bookmarks_bookmark" does not exist`

**Çözüm:** `setup.sh` scripti otomatik olarak migration'ları çalıştırır. Manuel çalıştırmak için:
```bash
kubectl exec -n linkding deployment/linkding -c linkding -- python manage.py migrate
```

### 4. Ingress Erişim Sorunu

**Sorun:** Ingress çalışmıyor veya erişilemiyor

**Not:** Kind cluster'ında varsayılan olarak LoadBalancer service tipi desteklenmez, ancak `cloud-provider-kind` ile bu özellik sağlanmaktadır. Cluster kurulumu sırasında (`sudo ./cluster/create-cluster.sh`) `cloud-provider-kind` otomatik olarak kurulur ve başlatılır (sudo gerektirir), böylece LoadBalancer desteği aktif hale gelir.

**Çözüm:**
```bash
# Ingress controller'ın çalıştığını kontrol et
kubectl get pods -n ingress-nginx

# Ingress'i kontrol et
kubectl get ingress -n linkding
kubectl describe ingress linkding-ingress -n linkding

# cloud-provider-kind'ın çalıştığını kontrol et
pgrep -f cloud-provider-kind
```

### 5. Linkding Login Sorunu

**Sorun:** Username/password ile giriş yapılamıyor

**Çözüm:** `setup.sh` scripti otomatik olarak superuser oluşturur/reset eder. Manuel reset için:
```bash
kubectl exec -n linkding deployment/linkding -c linkding -- python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
user = User.objects.get(username='admin')
user.set_password('admin')
user.save()
"
```

### 6. Platform Uyumsuzluğu (CI/CD)

**Sorun:** `no match for platform in manifest: not found`

**Çözüm:** Workflow multi-platform build yapar (amd64 + arm64). Yeni build yapıldığında sorun çözülür.

### 7. GitHub Actions Lokal Cluster Deploy

**Sorun:** GitHub Actions'tan lokal cluster'a erişilemiyor

**Çözüm:** Self-hosted runner kurulmalı. Detaylar: [SELF-HOSTED-RUNNER-SETUP.md](SELF-HOSTED-RUNNER-SETUP.md)

**Detaylı sorun giderme:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🧹 Temizleme

### Uygulamayı Temizleme

```bash
./scripts/cleanup.sh
```

Bu script:
- ✅ `linkding` namespace'ini siler (tüm kaynaklar dahil)
- ✅ PVC'leri siler (veri kaybı olur!)

### Cluster'ı Temizleme

```bash
# Kind cluster'ı sil
kind delete cluster --name kind-cluster

# Veya tüm cluster'ları sil
kind delete clusters --all
```

### Tam Temizlik

```bash
# 1. Uygulamayı temizle
./scripts/cleanup.sh

# 2. Cluster'ı sil
kind delete cluster --name kind-cluster

# 3. Docker image'ları temizle (opsiyonel)
docker system prune -a
```

## 📚 Ek Kaynaklar

### Dokümantasyon

- [QUICKSTART.md](QUICKSTART.md) - Hızlı başlangıç rehberi
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Detaylı sorun giderme
- [CI-CD-SETUP.md](CI-CD-SETUP.md) - CI/CD kurulum rehberi
- [SELF-HOSTED-RUNNER-SETUP.md](SELF-HOSTED-RUNNER-SETUP.md) - Runner kurulumu
- [DEPLOYMENT-OPTIONS.md](DEPLOYMENT-OPTIONS.md) - Deploy seçenekleri

### Dış Kaynaklar

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Linkding GitHub](https://github.com/sissbruecker/linkding)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Docker Documentation](https://docs.docker.com/)

## 📸 Screenshot ve Video Gereksinimleri

Proje dokümantasyonu için aşağıdaki screenshot'lar veya video kayıtları örnek olarak verilebilir:

1. ✅ `kubectl get nodes` çıktısı
2. ✅ `kubectl get pods -A` çıktısı (tüm pod'lar Running durumunda)
3. ✅ `kubectl get svc,ingress -n linkding` çıktısı
4. ✅ Tarayıcıda `http://linkding.local` erişimi
5. ✅ Rolling update süreci (`kubectl rollout status`)
6. ✅ Rollback süreci (`kubectl rollout undo`)
7. ✅ CI/CD pipeline çalışması (GitHub Actions)
8. ✅ Docker Hub'da image görünümü

### Screenshot Alma

```bash
# Terminal çıktılarını kaydet
mkdir -p screenshots
kubectl get nodes > screenshots/nodes.txt
kubectl get pods -A > screenshots/pods.txt
kubectl get svc,ingress -n linkding > screenshots/services.txt
kubectl rollout status deployment/linkding -n linkding > screenshots/rolling-update.txt
kubectl rollout history deployment/linkding -n linkding > screenshots/rollout-history.txt
```

