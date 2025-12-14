# GitHub Secrets Ekleme Rehberi

Bu dokümanda GitHub Actions için gerekli secrets'ların nasıl ekleneceği açıklanmaktadır.

## Adım Adım Kurulum

### 1. GitHub Repository'ye Git

1. GitHub'da projenizin repository sayfasına gidin
2. **Settings** sekmesine tıklayın (repository sağ üst menüde)

### 2. Secrets Menüsüne Erişim

1. Sol menüden **Secrets and variables** → **Actions** seçeneğine tıklayın
2. **New repository secret** butonuna tıklayın

### 3. Gerekli Secrets'ları Ekleyin

Aşağıdaki secrets'ları sırayla ekleyin:

---

## Secret 1: DOCKER_USERNAME

**Name:** `DOCKER_USERNAME`

**Value:** Docker Hub kullanıcı adınız

**Örnek:**
```
hasanaktas
```

**Nasıl Bulunur:**
- Docker Hub'a giriş yapın: https://hub.docker.com
- Sağ üst köşedeki profil adınızı kopyalayın

---

## Secret 2: DOCKER_PASSWORD

**Name:** `DOCKER_PASSWORD`

**Value:** Docker Hub access token (önerilen) veya şifreniz

**Önerilen: Access Token Oluşturma:**

1. Docker Hub → **Account Settings** → **Security**
2. **New Access Token** butonuna tıklayın
3. Token adı verin (örn: `github-actions`)
4. **Read & Write** izni verin
5. Token'ı kopyalayın (bir daha gösterilmeyecek!)

**Örnek Token:**
```
dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Not:** Şifre yerine access token kullanmanız önerilir (daha güvenli).

---

## Secret 3: KUBECONFIG (Opsiyonel - Kubernetes Deploy İçin)

**Name:** `KUBECONFIG`

**Value:** Kubernetes cluster kubeconfig dosyanız (base64 encoded)

### Kind Cluster İçin:

```bash
# Kind cluster kubeconfig'ini export et ve base64 encode et
kind export kubeconfig --name kind-cluster | base64
```

Çıktıyı kopyalayın (uzun bir string olacak).

### Diğer Cluster'lar İçin:

```bash
# Mevcut kubeconfig'i base64 encode et
cat ~/.kube/config | base64
```

**Örnek Çıktı:**
```
YXBpVmVyc2lvbjogdjEKY2x1c3RlcnM6Ci0gY2x1c3RlcjoKICAgIHNlcnZlcjog...
```

**Not:** 
- Bu secret opsiyoneldir
- Eğer eklenmezse, workflow sadece Docker image build ve push yapar
- Kubernetes deploy yapmak istiyorsanız mutlaka ekleyin

---

## Secret Ekleme Ekranı

GitHub'da secret eklerken:

1. **Name** alanına secret adını yazın (örn: `DOCKER_USERNAME`)
2. **Secret** alanına değeri yazın
3. **Add secret** butonuna tıklayın

**Önemli:** Secret değerleri bir daha görüntülenemez! Değerleri kaydedin.

---

## Kontrol

Secrets'ları ekledikten sonra:

1. **Actions** sekmesine gidin
2. **CI/CD Pipeline** workflow'unu seçin
3. **Run workflow** butonuna tıklayın
4. Workflow çalışırken secrets'ların kullanıldığını görebilirsiniz

---

## Troubleshooting

### "DOCKER_USERNAME is not set" Hatası

- Secret adının tam olarak `DOCKER_USERNAME` olduğundan emin olun
- Büyük/küçük harf duyarlıdır
- Secret'ı yeniden oluşturun

### Docker Push Başarısız

- `DOCKER_PASSWORD` secret'ının doğru olduğundan emin olun
- Access token kullanıyorsanız, token'ın `Read & Write` iznine sahip olduğundan emin olun
- Docker Hub'da repository oluşturma izniniz olduğundan emin olun

### Kubernetes Deploy Başarısız

- `KUBECONFIG` secret'ının base64 encoded olduğundan emin olun
- Kubeconfig'in geçerli olduğundan emin olun:
  ```bash
  echo "<base64-string>" | base64 -d > /tmp/kubeconfig
  KUBECONFIG=/tmp/kubeconfig kubectl get nodes
  ```

---

## Özet

| Secret Name | Gerekli | Açıklama |
|------------|---------|----------|
| `DOCKER_USERNAME` | ✅ Evet | Docker Hub kullanıcı adı |
| `DOCKER_PASSWORD` | ✅ Evet | Docker Hub access token |
| `KUBECONFIG` | ⚠️ Opsiyonel | Kubernetes cluster config (base64) |

---

## Hızlı Komutlar

### Tüm Secrets'ları Kontrol Et

GitHub CLI kullanarak:
```bash
gh secret list
```

### Secret Ekleme (GitHub CLI)

```bash
# Docker username
gh secret set DOCKER_USERNAME --body "your-username"

# Docker password
gh secret set DOCKER_PASSWORD --body "your-token"

# Kubeconfig
gh secret set KUBECONFIG --body "$(cat ~/.kube/config | base64)"
```
