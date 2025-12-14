# Self-Hosted Runner Kurulum Rehberi

## Adım 1: GitHub'dan Token Alın

1. **GitHub Repository'nize gidin**
2. **Settings** → **Actions** → **Runners** sekmesine gidin
3. **New self-hosted runner** butonuna tıklayın
4. **macOS** seçin
5. **Aşağıdaki komutları kopyalayın** (token otomatik olarak eklenir)

## Adım 2: Runner'ı İndirin ve Kurun

```bash
# Çalışma dizini oluştur
mkdir -p ~/actions-runner && cd ~/actions-runner

# Runner'ı indir (en son versiyonu kontrol edin)
curl -o actions-runner-osx-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz

# Aç
tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz
```

## Adım 3: Runner'ı Yapılandırın

**ÖNEMLİ:** GitHub'dan aldığınız token'ı kullanın (Settings → Actions → Runners → New runner sayfasından)

```bash
# GitHub'dan aldığınız komutu çalıştırın
# Örnek format:
./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token AXXXXXXXXXXXXXXXXXXXXX
```

**Token Formatı:**
- Token `A` ile başlamalı
- 39 karakter uzunluğunda olmalı
- GitHub UI'dan kopyaladığınız token'ı kullanın

## Adım 4: Runner'ı Başlatın

### Manuel Başlatma:
```bash
./run.sh
```

### Service Olarak Başlatma (Önerilen):
```bash
# Service olarak install et
sudo ./svc.sh install

# Service'i başlat
sudo ./svc.sh start

# Durum kontrolü
./svc.sh status
```

## Troubleshooting

### 404 Hatası

**Sorun:** `Http response code: NotFound`

**Çözümler:**

1. **Token'ı kontrol edin:**
   - Token GitHub UI'dan yeni alınmış olmalı
   - Token'ın süresi dolmamış olmalı (genelde 1 saat geçerlidir)
   - Token formatı: `A` ile başlayan 39 karakter

2. **URL'yi kontrol edin:**
   ```bash
   # Doğru format:
   https://github.com/YOUR-USERNAME/YOUR-REPO
   
   # Örnek:
   https://github.com/hasanaktas/Linkding-app-deployment
   ```

3. **Yeni token alın:**
   - GitHub → Settings → Actions → Runners → New self-hosted runner
   - Sayfayı yenileyin
   - Yeni token kopyalayın

4. **Repository erişimini kontrol edin:**
   - Repository'nin private olup olmadığını kontrol edin
   - Erişim izinlerinizi kontrol edin

### Token Süresi Doldu

Token'lar genelde 1 saat geçerlidir. Yeni token alın:

1. GitHub → Settings → Actions → Runners
2. Runner'ı silin (eğer varsa)
3. New self-hosted runner → Yeni token alın

### Runner Bağlanmıyor

```bash
# Runner'ı temizle ve yeniden başlat
cd ~/actions-runner
./config.sh remove --token YOUR_TOKEN
./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token NEW_TOKEN
./run.sh
```

## Workflow'u Güncelleme

Runner kurulduktan sonra workflow'u güncelleyin:

### Basit Kullanım (Tek Runner):

```yaml
jobs:
  build-and-deploy:
    runs-on: self-hosted  # ubuntu-latest yerine
```

### Runner Label Kullanımı (Birden Fazla Runner Varsa):

Eğer birden fazla self-hosted runner'ınız varsa, belirli bir runner'ı hedeflemek için label kullanabilirsiniz:

1. **Runner'a label ekleyin:**
   ```bash
   cd ~/actions-runner
   ./config.sh remove --token YOUR_TOKEN
   ./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token NEW_TOKEN --labels macos,linkding
   ```

2. **Workflow'da label kullanın:**
   ```yaml
   jobs:
     build-and-deploy:
       runs-on: [self-hosted, macos, linkding]
   ```

**Not:** Tek runner varsa sadece `runs-on: self-hosted` yeterlidir, runner adı yazmanıza gerek yok!

## Kontrol

1. **GitHub'da kontrol:**
   - Repository → Settings → Actions → Runners
   - Runner'ın "Idle" durumunda olduğunu görün

2. **Lokal kontrol:**
   ```bash
   cd ~/actions-runner
   ./run.sh
   # Runner çalışıyor olmalı
   ```

3. **Test workflow çalıştırın:**
   - GitHub → Actions → CI/CD Pipeline → Run workflow

## Notlar

- Runner çalışırken bilgisayarınız açık olmalı
- Runner'ı service olarak kurmak önerilir (otomatik başlar)
- Her runner sadece bir workflow job'u çalıştırabilir
- Runner'ı durdurmak için: `Ctrl+C` veya `./svc.sh stop`

## Service Komutları

```bash
# Service install
sudo ./svc.sh install

# Service start
sudo ./svc.sh start

# Service stop
sudo ./svc.sh stop

# Service status
./svc.sh status

# Service uninstall
sudo ./svc.sh uninstall
```
