## 📋 Genel Bakış

Bu bir Kubernetes ortamı kurma, temel objeleri yönetme ve otomasyon adımlarını uygulama konularındaki pratik yetkinlikleri değerlendirmek amacıyla hazırlanmıştır.

## 🎯 Seçimler

### Kubernetes Ortamı: **Kind (Kubernetes in Docker)**
- ✅ En hızlı kurulum
- ✅ Docker üzerinde çalışır, ekstra VM gerektirmez
- ✅ Production-like ortam
- ✅ Kolay temizleme ve yeniden başlatma

### Uygulama: **Linkding**
- ✅ Hafif ve modern bookmark manager
- ✅ PostgreSQL veritabanı gerektirir (PVC kullanımı için uygun)
- ✅ Docker image mevcut
- ✅ ConfigMap ve Secret kullanımı için uygun

## 📁 Proje Yapısı

```
/
├── README.md                 # Ana dokümantasyon
├── ROADMAP.md               # Bu dosya
├── setup.sh                 # Ana setup scripti
├── cluster/
│   ├── kind-config.yaml     # Kind cluster yapılandırması
│   └── create-cluster.sh    # Cluster oluşturma scripti
├── manifests/
│   ├── namespace.yaml        # Namespace tanımı
│   ├── configmap.yaml        # ConfigMap
│   ├── secret.yaml          # Secret (base64 encoded)
│   ├── pvc.yaml             # PersistentVolumeClaim
│   ├── postgres/
│   │   ├── deployment.yaml  # PostgreSQL deployment
│   │   └── service.yaml     # PostgreSQL service
│   ├── linkding/
│   │   ├── deployment.yaml  # Linkding deployment
│   │   └── service.yaml     # Linkding service (ClusterIP)
│   └── ingress.yaml         # Ingress controller
├── scripts/
│   ├── rolling-update.sh    # Rolling update scripti
│   ├── rollback.sh          # Rollback scripti
│   └── cleanup.sh           # Temizleme scripti
└── .github/
    └── workflows/
        └── ci-cd.yml        # GitHub Actions CI/CD 
```

## 🚀 Adım Adım Plan

### 1️⃣ Proje Yapısı ve Temel Dosyalar
- [x] Proje klasör yapısını oluştur
- [ ] .gitignore ekle

### 2️⃣ Kubernetes Cluster Kurulumu
- [ ] Kind kurulum scripti
- [ ] Kind cluster yapılandırması
- [ ] Cluster oluşturma ve doğrulama

### 3️⃣ Kubernetes Manifestleri
- [ ] Namespace
- [ ] ConfigMap (Linkding ayarları)
- [ ] Secret (PostgreSQL credentials)
- [ ] PVC (PostgreSQL data)
- [ ] PostgreSQL Deployment + Service
- [ ] Linkding Deployment + Service (ClusterIP)
- [ ] Ingress (NGINX Ingress Controller)

### 4️⃣ Otomasyon Scriptleri
- [ ] setup.sh - Ana setup scripti
  - Cluster erişimini doğrula (kubectl get nodes)
  - Ingress controller kurulumu
  - Manifestleri apply et
  - Pod durumlarını kontrol et
  - Ingress erişimini test et

### 5️⃣ Rolling Update & Rollback
- [ ] rolling-update.sh
  - Image tag değiştirme
  - Rolling update uygulama
  - Durum kontrolü
- [ ] rollback.sh
  - Eski versiyona dönme
  - Rollback durumunu kontrol etme

### 6️⃣ Dokümantasyon
- [ ] README.md
  - Gereksinimler
  - Kurulum talimatları
  - Kullanılan araçlar
  - Bilinen sorunlar
  - Screenshot/video talimatları

### 7️⃣ Opsiyonel: CI/CD Pipeline
- [ ] GitHub Actions workflow
  - Docker image build
  - Registry push (Docker Hub veya GHCR)
  - Kubernetes deploy
  - Rolling update tetikleme

## 🔧 Teknik Detaylar

### Gereksinimler
- Docker Desktop veya Docker Engine
- kubectl
- kind
- curl veya wget

### Linkding Versiyonları
- v1.22.0 (başlangıç)
- v1.23.0 (rolling update için)

### PostgreSQL
- Image: postgres:15-alpine
- Database: linkding
- User: linkding (Secret'tan)


## 📝 Test Senaryoları

1. ✅ Cluster kurulumu ve doğrulama
2. ✅ Tüm podların Running durumunda olması
3. ✅ Service'lerin doğru çalışması
4. ✅ Ingress üzerinden erişim
5. ✅ Rolling update başarılı
6. ✅ Rollback başarılı
7. ✅ ConfigMap ve Secret değişikliklerinin uygulanması

## 🎬 Screenshot/Video Gereksinimleri

1. `kubectl get nodes` çıktısı
2. `kubectl get pods -A` çıktısı
3. `kubectl get svc,ingress` çıktısı
4. Ingress üzerinden uygulama erişimi (browser)
5. Rolling update süreci (`kubectl rollout status`)
6. Rollback süreci (`kubectl rollout undo`)


**Toplam: ~5-6 saat** (CI/CD ile ~6-7 saat)
