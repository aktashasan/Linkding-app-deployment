# 🚀 Quick Start Guide

Bu hızlı başlangıç rehberi, projeyi hızlıca çalıştırmak için gerekli adımları içerir.

## ⚡ Hızlı Kurulum (5 Dakika)

### 1. Gereksinimleri Kontrol Et

```bash
# Docker kontrolü
docker --version

# kubectl kontrolü
kubectl version --client

# kind kontrolü
kind --version
```

Eksik araçlar için: [README.md - Gereksinimler bölümüne bakın](README.md#gereksinimler)

### 2. Cluster'ı Oluştur

```bash
cd cluster
./create-cluster.sh
```

Bu işlem 2-3 dakika sürebilir.

### 3. Uygulamayı Deploy Et

```bash
cd ..
./setup.sh
```

Bu işlem 3-5 dakika sürebilir (pod'ların başlaması için).

### 4. Uygulamaya Eriş (Ingress)

Ingress ile erişim için:

1. **`/etc/hosts` dosyasını yapılandırın:**
   ```bash
   # macOS/Linux
   echo "127.0.0.1 linkding.local" | sudo tee -a /etc/hosts
   
   # Windows (PowerShell as Administrator)
   Add-Content C:\Windows\System32\drivers\etc\hosts "127.0.0.1 linkding.local"
   ```

2. **Tarayıcınızda açın:** **http://linkding.local**

**Varsayılan Giriş:**
- Username: `admin`
- Password: `admin`

**Not:** `cloud-provider-kind` sayesinde Kind cluster'ında LoadBalancer desteği aktif. Ingress controller port mapping (80:80, 443:443) ile çalışır.

## 🧪 Test Senaryoları

### Rolling Update Testi

```bash
./scripts/rolling-update.sh v1.23.0
```

### Rollback Testi

```bash
./scripts/rollback.sh
```

### Durum Kontrolü

```bash
# Tüm kaynakları listele
kubectl get all -n linkding

# Pod loglarını görüntüle
kubectl logs -f deployment/linkding -n linkding
```

## 🧹 Temizleme

```bash
# Uygulamayı sil
./scripts/cleanup.sh

# Cluster'ı sil (isteğe bağlı)
kind delete cluster --name kind-cluster
```

## 📸 Screenshot Alma

Proje dokümantasyonu için aşağıdaki komutları çalıştırabilirsiniz:

```bash
# Screenshot klasörü oluştur
mkdir -p screenshots

# Node'ları kaydet
kubectl get nodes > screenshots/nodes.txt

# Pod'ları kaydet
kubectl get pods -A > screenshots/pods.txt

# Service ve Ingress'i kaydet
kubectl get svc,ingress -n linkding > screenshots/services.txt

# Rolling update sürecini kaydet
./scripts/rolling-update.sh v1.23.0 2>&1 | tee screenshots/rolling-update.txt

# Rollback sürecini kaydet
./scripts/rollback.sh 2>&1 | tee screenshots/rollback.txt
```

## ❓ Sorun Giderme

### Pod'lar başlamıyor

```bash
# Pod durumunu kontrol et
kubectl get pods -n linkding

# Pod detaylarını görüntüle
kubectl describe pod <pod-name> -n linkding

# Logları kontrol et
kubectl logs <pod-name> -n linkding
```

### Ingress erişilemiyor

```bash
# Ingress controller'ı kontrol et
kubectl get pods -n ingress-nginx

# Ingress durumunu kontrol et
kubectl get ingress -n linkding
kubectl describe ingress linkding-ingress -n linkding
```

### PostgreSQL bağlantı hatası

```bash
# PostgreSQL pod'unu kontrol et
kubectl get pods -l app=postgres -n linkding

# PostgreSQL loglarını kontrol et
kubectl logs -l app=postgres -n linkding
```

## 📚 Daha Fazla Bilgi

Detaylı dokümantasyon için [README.md](README.md) dosyasına bakın.
