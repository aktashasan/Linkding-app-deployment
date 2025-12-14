# Linkding Source Kurulum Rehberi

GitHub Actions CI/CD'nin çalışması için `linkding-source` klasörünün repository'ye eklenmesi gerekmektedir.

## Seçenek 1: Git Submodule Olarak Ekleme (Önerilen)

Bu yöntem, Linkding kaynak kodunu ayrı bir repository olarak tutar ve daha temiz bir yapı sağlar.

### Adımlar:

1. **Mevcut linkding-source klasörünü silin:**
   ```bash
   cd /Users/hasanaktas/ankasoft-project/k8s-orchestration/case-study
   rm -rf linkding-source
   ```

2. **Git submodule olarak ekleyin:**
   ```bash
   git submodule add https://github.com/sissbruecker/linkding.git linkding-source
   ```

3. **Commit edin:**
   ```bash
   git add .gitmodules linkding-source
   git commit -m "Add Linkding source as git submodule"
   git push origin main
   ```

### Avantajları:
- Repository boyutu küçük kalır
- Linkding güncellemelerini kolayca alabilirsiniz
- GitHub Actions otomatik olarak submodule'ı checkout eder

---

## Seçenek 2: Direkt Repository'ye Ekleme

Bu yöntem, Linkding kaynak kodunu direkt repository'nize ekler.

### Adımlar:

1. **.gitignore'dan linkding-source'u kaldırın:**
   ```bash
   # .gitignore dosyasında linkding-source satırını silin veya yorum yapın
   ```

2. **linkding-source'u git'e ekleyin:**
   ```bash
   cd /Users/hasanaktas/ankasoft-project/k8s-orchestration/case-study
   git add linkding-source
   git commit -m "Add Linkding source code"
   git push origin main
   ```

### Dezavantajları:
- Repository boyutu büyük olur (~50MB+)
- Her push'ta tüm kaynak kodu gönderilir

---

## Seçenek 3: GitHub Actions'da Clone Etme

Bu yöntem, GitHub Actions workflow'unda Linkding'i clone eder.

### Workflow'a ekleyin:

```yaml
- name: Clone Linkding source
  run: |
    git clone https://github.com/sissbruecker/linkding.git linkding-source
    cd linkding-source
    git checkout <specific-tag-or-branch>  # Örnek: v1.23.0
```

### Avantajları:
- Repository boyutu küçük kalır
- Her build'de fresh clone alınır

### Dezavantajları:
- Her build'de clone işlemi yapılır (daha uzun sürer)

---

## Önerilen Yöntem: Git Submodule

**En iyi pratik:** Git submodule kullanmak.

### Tam Kurulum:

```bash
cd /Users/hasanaktas/ankasoft-project/k8s-orchestration/case-study

# Mevcut klasörü sil
rm -rf linkding-source

# Submodule ekle
git submodule add https://github.com/sissbruecker/linkding.git linkding-source

# Commit ve push
git add .gitmodules linkding-source
git commit -m "Add Linkding source as git submodule"
git push origin main
```

### Submodule Güncelleme:

```bash
# Linkding'i güncellemek için
cd linkding-source
git pull origin main
cd ..
git add linkding-source
git commit -m "Update Linkding submodule"
git push origin main
```

---

## Kontrol

Kurulumdan sonra:

```bash
# Submodule'ın doğru eklendiğini kontrol et
git submodule status

# GitHub Actions'da test et
# Repository → Actions → CI/CD Pipeline → Run workflow
```

---

## Troubleshooting

### "linkding-source not found" Hatası

1. **Submodule kontrolü:**
   ```bash
   git submodule status
   ```

2. **Submodule'ı initialize et:**
   ```bash
   git submodule update --init --recursive
   ```

3. **GitHub Actions'da submodule checkout:**
   Workflow'da `submodules: recursive` parametresi olmalı (zaten eklendi).

### "Permission denied" Hatası

GitHub Actions'da submodule checkout için `GITHUB_TOKEN` kullanılır (otomatik).

---

## Notlar

- Submodule kullanıyorsanız, `.gitignore`'da `linkding-source/` olmamalı
- Her yeni clone'da `git submodule update --init --recursive` çalıştırılmalı
- GitHub Actions otomatik olarak submodule'ları checkout eder
