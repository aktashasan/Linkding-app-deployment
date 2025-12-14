# Kubernetes Deploy Seçenekleri

GitHub Actions'tan lokal Kind cluster'a deploy etmek için birkaç seçenek var:

## ❌ Sorun: Lokal Cluster'a Erişim

GitHub Actions runner'ları cloud'da çalışır ve lokal bilgisayarınızdaki Kind cluster'a doğrudan erişemez.

---

## ✅ Çözüm Seçenekleri

### Seçenek 1: Self-Hosted GitHub Runner (Önerilen - Lokal için)

Lokal bilgisayarınızda GitHub Actions runner çalıştırın. Bu şekilde runner lokal cluster'a erişebilir.

#### Kurulum:

1. **GitHub Repository → Settings → Actions → Runners → New self-hosted runner**

2. **macOS için komutları çalıştırın:**
   ```bash
   # Runner'ı indir
   mkdir actions-runner && cd actions-runner
   curl -o actions-runner-osx-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
   tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz
   
   # Runner'ı yapılandır
   ./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token YOUR-TOKEN
   
   # Runner'ı başlat
   ./run.sh
   ```

3. **Workflow'u self-hosted runner kullanacak şekilde güncelleyin:**
   ```yaml
   jobs:
     build-and-deploy:
       runs-on: self-hosted  # GitHub-hosted yerine
   ```

4. **KUBECONFIG secret'ı ekleyin:**
   ```bash
   kind export kubeconfig --name kind-cluster | base64
   # Çıktıyı GitHub Secrets → KUBECONFIG olarak ekleyin
   ```

**Avantajları:**
- ✅ Lokal cluster'a direkt erişim
- ✅ Hızlı deploy
- ✅ Ücretsiz

**Dezavantajları:**
- ⚠️ Bilgisayarınız açık olmalı
- ⚠️ Runner sürekli çalışmalı

---

### Seçenek 2: Cloud Kubernetes Cluster (Production için)

GKE, EKS, AKS gibi cloud cluster kullanın.

#### GKE (Google Kubernetes Engine) Örneği:

1. **GKE cluster oluşturun**
2. **Service Account oluşturun ve kubeconfig alın**
3. **GitHub Secrets'a ekleyin:**
   ```bash
   gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE
   cat ~/.kube/config | base64
   # Çıktıyı GitHub Secrets → KUBECONFIG olarak ekleyin
   ```

**Avantajları:**
- ✅ Her zaman erişilebilir
- ✅ Production-ready
- ✅ Scalable

**Dezavantajları:**
- ⚠️ Ücretli (cloud provider'a göre)
- ⚠️ Setup gerektirir

---

### Seçenek 3: Manuel Deploy (En Basit)

CI/CD sadece build ve push yapar, deploy'u manuel yaparsınız.

#### Workflow Zaten Hazır:

Workflow build ve push yapar. Deploy için:

```bash
# Lokal bilgisayarınızda
kubectl set image deployment/linkding \
  linkding=YOUR-USERNAME/linkding:COMMIT-SHA \
  -n linkding

# Veya script ile
./scripts/rolling-update.sh COMMIT-SHA
```

**Avantajları:**
- ✅ En basit yöntem
- ✅ Lokal cluster kontrolü
- ✅ Ekstra setup yok

**Dezavantajları:**
- ⚠️ Manuel adım gerektirir
- ⚠️ Otomatik değil

---

### Seçenek 4: Tunneling (Güvenlik Riski - Önerilmez)

ngrok, cloudflared gibi araçlarla lokal cluster'ı expose edin.

**⚠️ UYARI:** Güvenlik riski taşır, production'da kullanmayın!

---

## 🎯 Önerilen Yaklaşım

### Development/Testing için:
**Seçenek 1 (Self-Hosted Runner)** veya **Seçenek 3 (Manuel Deploy)**

### Production için:
**Seçenek 2 (Cloud Cluster)**

---

## 📝 Mevcut Workflow Yapısı

Mevcut workflow şu şekilde çalışıyor:

1. ✅ **Build**: Docker image build edilir
2. ✅ **Push**: Docker Hub'a push edilir
3. ⚠️ **Deploy**: KUBECONFIG varsa deploy eder, yoksa sadece talimat verir

### KUBECONFIG Secret'ı Yoksa:

Workflow şu mesajı verir:
```
Image built and pushed successfully!
Image: docker.io/username/linkding:COMMIT-SHA

To deploy to your local Kubernetes cluster:
kubectl set image deployment/linkding \
  linkding=docker.io/username/linkding:COMMIT-SHA \
  -n linkding
```

---

## 🚀 Hızlı Başlangıç

### Self-Hosted Runner Kurulumu (5 dakika):

```bash
# 1. Runner indir ve kur
mkdir -p ~/actions-runner && cd ~/actions-runner
curl -o actions-runner-osx-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz

# 2. GitHub'dan token al (Settings → Actions → Runners → New runner)
# 3. Config et
./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token YOUR-TOKEN

# 4. Service olarak çalıştır (opsiyonel)
sudo ./svc.sh install
sudo ./svc.sh start
```

### KUBECONFIG Secret Ekleme:

```bash
# Kind cluster için
kind export kubeconfig --name kind-cluster | base64

# Çıktıyı GitHub → Settings → Secrets → Actions → New secret
# Name: KUBECONFIG
# Value: (base64 çıktısı)
```

---

## 🔍 Kontrol

Workflow çalıştıktan sonra:

```bash
# Lokal cluster'da kontrol et
kubectl get deployment linkding -n linkding -o jsonpath='{.spec.template.spec.containers[0].image}'
```

Yeni image tag'ini görmelisiniz!
