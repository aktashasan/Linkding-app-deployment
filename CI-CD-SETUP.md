# CI/CD Kurulum Rehberi

Bu dokümanda GitHub Actions CI/CD pipeline'ının nasıl kurulacağı açıklanmaktadır.

## Gereksinimler

1. **GitHub Repository**: Projenin GitHub'da bir repository'si olmalı
2. **Docker Hub Hesabı**: Docker image'larını push etmek için
3. **Kubernetes Cluster**: Deploy edilecek cluster (Kind, GKE, EKS, vb.)

## Kurulum Adımları

### 1. Linkding Source Kodunu Ekleme

Linkding kaynak kodu `linkding-source/` klasörüne clone edilmiştir. 

**Not:** Production ortamında git submodule kullanılması önerilir:

```bash
git submodule add https://github.com/sissbruecker/linkding.git linkding-source
git submodule update --init --recursive
```

### 2. GitHub Secrets Ayarlama

GitHub repository'nizde aşağıdaki secrets'ları ekleyin:

**Settings → Secrets and variables → Actions → New repository secret**

#### Gerekli Secrets:

1. **DOCKER_USERNAME**
   - Docker Hub kullanıcı adınız
   - Örnek: `hasanaktas`

2. **DOCKER_PASSWORD**
   - Docker Hub şifreniz veya access token
   - Örnek: `dckr_pat_xxxxxxxxxxxxx`

3. **KUBECONFIG** (Opsiyonel - Kubernetes deploy için)
   - Kubernetes cluster kubeconfig dosyanız (base64 encoded)
   - Oluşturma:
     ```bash
     cat ~/.kube/config | base64
     ```
   - Kind cluster için:
     ```bash
     kind export kubeconfig --name kind-cluster | base64
     ```

### 3. Workflow Yapılandırması

CI/CD workflow'u `.github/workflows/ci-cd.yml` dosyasında tanımlıdır.

**Trigger'lar:**
- `main` veya `master` branch'ine push
- `linkding-source/` klasöründe değişiklik
- `manifests/` klasöründe değişiklik
- Manuel trigger (workflow_dispatch)

### 4. Image Tag Stratejisi

- **Otomatik push**: Commit SHA kullanılır (`${{ github.sha }}`)
- **Manuel trigger**: Belirtilen tag kullanılır

### 5. Kubernetes Deploy

**Not:** Kubernetes deploy için `KUBECONFIG` secret'ı ayarlanmalıdır.

Eğer secret ayarlanmamışsa, workflow sadece image build ve push işlemini yapar.

## Kullanım

### Otomatik Deploy

1. `linkding-source/` klasöründe değişiklik yapın
2. Değişiklikleri commit edin
3. `main` veya `master` branch'ine push edin
4. GitHub Actions otomatik olarak:
   - Docker image'ı build eder
   - Docker Hub'a push eder
   - Kubernetes cluster'a deploy eder

### Manuel Deploy

1. GitHub repository → Actions sekmesine gidin
2. "CI/CD Pipeline" workflow'unu seçin
3. "Run workflow" butonuna tıklayın
4. Image tag girin (örnek: `v1.23.0`)
5. "Run workflow" butonuna tıklayın

## Workflow Adımları

1. **Checkout code**: Repository'yi checkout eder
2. **Set up Docker Buildx**: Docker build için hazırlar
3. **Log in to Docker Hub**: Docker Hub'a giriş yapar
4. **Determine image tag**: Image tag'ini belirler
5. **Build and push Docker image**: Linkding'i build eder ve push eder
6. **Set up kubectl**: kubectl kurulumu
7. **Configure kubectl**: Kubernetes cluster'a bağlanır
8. **Deploy to Kubernetes**: Rolling update ile deploy eder
9. **Verify deployment**: Deploy durumunu kontrol eder

## Troubleshooting

### Docker Build Başarısız

- `linkding-source/` klasörünün mevcut olduğundan emin olun
- Dockerfile path'ini kontrol edin: `docker/default.Dockerfile`

### Docker Push Başarısız

- `DOCKER_USERNAME` ve `DOCKER_PASSWORD` secrets'larını kontrol edin
- Docker Hub'da repository oluşturma izniniz olduğundan emin olun

### Kubernetes Deploy Başarısız

- `KUBECONFIG` secret'ının doğru olduğundan emin olun
- Cluster'ın erişilebilir olduğundan emin olun
- Namespace'in mevcut olduğundan emin olun

## Örnek Kullanım

```bash
# Linkding source'u güncelle
cd linkding-source
git pull origin main

# Değişiklikleri commit et
cd ..
git add linkding-source
git commit -m "Update Linkding to latest version"
git push origin main

# GitHub Actions otomatik olarak çalışacak
```

## Notlar

- İlk build uzun sürebilir (dependencies indirme)
- Docker Hub rate limit'lerine dikkat edin
- Production'da image tag'leri semantic versioning kullanın
