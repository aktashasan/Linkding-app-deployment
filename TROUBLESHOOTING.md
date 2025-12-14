# Sorun Giderme Rehberi

Bu dokümanda proje sırasında karşılaşılan sorunlar ve çözümleri listelenmiştir.

## Sorunlar ve Çözümler

### 1. PVC Bind Edilemedi - "pod has unbound immediate PersistentVolumeClaims"

**Sorun:**
```
Warning  FailedScheduling  0/1 nodes are available: pod has unbound immediate PersistentVolumeClaims.
```

**Neden:**
- Kind cluster'ında varsayılan storage class yok
- PVC `storageClassName: ""` ile oluşturulmuştu ama bind edilemedi

**Çözüm:**
1. Local Path Provisioner kuruldu:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
   kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
   ```

2. PVC manifest'i güncellendi:
   ```yaml
   storageClassName: local-path  # Önceden: storageClassName: ""
   ```

3. Eski PVC silinip yeniden oluşturuldu:
   ```bash
   kubectl delete pvc postgres-pvc -n linkding
   kubectl apply -f manifests/pvc.yaml
   ```

**Dosyalar:**
- `cluster/create-cluster.sh` - Local Path Provisioner kurulumu eklendi
- `manifests/pvc.yaml` - storageClassName güncellendi

---

### 2. PostgreSQL Veritabanı Bulunamadı - "FATAL: database 'linkding' does not exist"

**Sorun:**
```
django.db.utils.OperationalError: FATAL:  database "linkding" does not exist
```

**Neden:**
- PostgreSQL container'ı başladı ama `POSTGRES_DB` environment variable'ı ile veritabanı otomatik oluşturulmadı
- PVC'de önceden veri varsa, PostgreSQL init script'i çalışmıyor

**Çözüm:**
Manuel olarak veritabanı oluşturuldu:
```bash
kubectl exec -n linkding deployment/postgres -- psql -U linkding -d postgres -c "CREATE DATABASE linkding;"
```

**Not:** Bu sorun sadece ilk kurulumda oluştu. PVC temizlenirse PostgreSQL otomatik oluşturur.

---

### 3. Django Migration'ları Çalıştırılmadı - "relation 'bookmarks_bookmark' does not exist"

**Sorun:**
```
django.db.utils.ProgrammingError: relation "bookmarks_bookmark" does not exist
```

**Neden:**
- Linkding uygulaması başladı ama Django migration'ları çalıştırılmadı
- Veritabanı tabloları oluşturulmadı

**Çözüm:**
Manuel olarak migration'lar çalıştırıldı:
```bash
kubectl exec -n linkding deployment/linkding -c linkding -- python manage.py migrate
```

**Gelecek İyileştirme:**
Linkding deployment'ına init container eklenebilir:
```yaml
initContainers:
- name: migrate
  image: sissbruecker/linkding:1.22.0
  command: ["python", "manage.py", "migrate"]
  env:
    # ... tüm environment variables
```

---

### 4. Port 8080 Kullanımda - "Unable to listen on port 8080: address already in use"

**Sorun:**
```
Unable to listen on port 8080: Listeners failed to create with the following errors: 
[unable to create listener: Error listen tcp4 127.0.0.1:8080: bind: address already in use]
```

**Neden:**
- Önceki bir `kubectl port-forward` işlemi hala çalışıyor
- Port 8080 başka bir uygulama tarafından kullanılıyor

**Çözüm:**
1. Çalışan port-forward işlemini bul ve sonlandır:
   ```bash
   lsof -ti:8080 | xargs kill -9
   # veya
   ps aux | grep port-forward
   kill <PID>
   ```

2. Alternatif port kullan:
   ```bash
   kubectl port-forward -n linkding service/linkding 9090:80
   ```

**Dosyalar:**
- `scripts/port-forward.sh` - Varsayılan port 9090 olarak değiştirildi

---

### 5. Ingress-Nginx Kurulum Sorunu - "ingress-nginx namespace empty"

**Sorun:**
```
kubectl get pods -n ingress-nginx
No resources found in ingress-nginx namespace.
```

**Neden:**
- Ingress Controller manifest'i apply edildi ama pod'lar oluşmadı
- Network bağlantı sorunları
- Deployment oluşmadan önce bekleme süresi yetersiz

**Çözüm:**
1. `create-cluster.sh` script'ine retry mekanizması eklendi:
   - Deployment'ın oluşması için 30 kez kontrol (60 saniye)
   - Pod'ların hazır olması için 3 dakika bekleme
   - Emergency installation fallback mekanizması

2. Manuel kurulum:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
   kubectl wait --namespace ingress-nginx \
     --for=condition=ready pod \
     --selector=app.kubernetes.io/component=controller \
     --timeout=180s
   ```

**Dosyalar:**
- `cluster/create-cluster.sh` - Retry logic ve deployment kontrolü eklendi

---

### 6. Kind Context Hatası - "error: context 'kind-cluster' does not exist"

**Sorun:**
```
error: context "kind-cluster" does not exist
```

**Neden:**
- Kind, context'i `kind-{cluster-name}` formatında oluşturur
- Script `kind-cluster` arıyordu ama Kind `kind-kind-cluster` oluşturmuştu

**Çözüm:**
Script güncellendi, her iki context adını da kontrol ediyor:
```bash
kubectl cluster-info --context kind-kind-cluster || kubectl cluster-info --context kind-cluster
```

**Dosyalar:**
- `cluster/create-cluster.sh` - Context kontrolü dinamik hale getirildi

---

### 7. cloud-provider-kind Syntax Hatası

**Sorun:**
```
line 131: syntax error near unexpected token `;`
```

**Neden:**
- Bash syntax hatası: `if sudo cloud-provider-kind &>/dev/null &; then` geçersiz

**Çözüm:**
Syntax düzeltildi:
```bash
sudo cloud-provider-kind &>/dev/null &
CLOUD_PROVIDER_PID=$!
if [ $? -eq 0 ]; then
    echo "cloud-provider-kind started"
fi
```

**Dosyalar:**
- `cluster/create-cluster.sh` - Syntax hatası düzeltildi

---

### 8. create-cluster.sh kind-config.yaml Path Sorunu

**Sorun:**
```
ERROR: failed to create cluster: error reading file: open kind-config.yaml: no such file or directory
```

**Neden:**
- Script farklı dizinden çalıştırıldığında `kind-config.yaml` dosyasını bulamıyor
- Relative path kullanılıyordu

**Çözüm:**
Script'in bulunduğu dizin dinamik olarak bulunuyor:
```bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
kind create cluster --config "${SCRIPT_DIR}/kind-config.yaml"
```

**Dosyalar:**
- `cluster/create-cluster.sh` - SCRIPT_DIR değişkeni eklendi

---

### 9. Linkding Login Sorunu - "CSRF cookie not set" / "user şifre giriyorum içeri almıyor"

**Sorun:**
```
WARNING Forbidden (CSRF cookie not set.): /login/
POST /login/ => HTTP/1.1 403
```

**Neden:**
- Linkding, Ingress üzerinden erişildiğinde CSRF doğrulaması başarısız oluyor
- `CSRF_TRUSTED_ORIGINS` ayarı eksikti
- Session cookie'leri düzgün çalışmıyordu

**Çözüm:**
1. ConfigMap'e `LD_CSRF_TRUSTED_ORIGINS` eklendi:
   ```yaml
   LD_CSRF_TRUSTED_ORIGINS: "http://linkding.local,http://localhost"
   ```

2. Deployment'a environment variable eklendi:
   ```yaml
   - name: LD_CSRF_TRUSTED_ORIGINS
     valueFrom:
       configMapKeyRef:
         name: linkding-config
         key: LD_CSRF_TRUSTED_ORIGINS
   ```

3. Ingress'e session affinity eklendi:
   ```yaml
   annotations:
     nginx.ingress.kubernetes.io/affinity: "cookie"
     nginx.ingress.kubernetes.io/session-cookie-name: "linkding-session"
     nginx.ingress.kubernetes.io/session-cookie-expires: "172800"
     nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"
   ```

4. Superuser şifresi otomatik reset ediliyor:
   ```bash
   kubectl exec -n linkding deployment/linkding -c linkding -- python manage.py shell -c "
   from django.contrib.auth import get_user_model
   User = get_user_model()
   user = User.objects.get(username='admin')
   user.set_password('admin')
   user.save()
   "
   ```

**Dosyalar:**
- `manifests.yaml` - ConfigMap, Deployment ve Ingress güncellendi
- `setup.sh` - Superuser password reset otomatikleştirildi

---

### 10. PostgreSQL Not Ready - Pod Başlamıyor

**Sorun:**
```
postgres pod not ready
```

**Neden:**
- PVC bind edilemedi
- PostgreSQL init script çalışmadı
- Health check başarısız

**Çözüm:**
1. PVC durumunu kontrol et:
   ```bash
   kubectl get pvc -n linkding
   kubectl describe pvc postgres-pvc -n linkding
   ```

2. Pod loglarını kontrol et:
   ```bash
   kubectl logs -n linkding deployment/postgres
   kubectl describe pod -n linkding -l app=postgres
   ```

3. StorageClass'ın default olduğundan emin ol:
   ```bash
   kubectl get storageclass
   kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
   ```

---

### 11. GitHub Actions'tan Lokal Kubernetes Cluster'a Deploy Sorunu

**Sorun:**
```
GitHub Actions runner'ları cloud'da çalışır ve lokal bilgisayarınızdaki Kind cluster'a erişemez.
KUBECONFIG secret'ı ekleseniz bile, cloud runner lokal network'e erişemez.
```

**Neden:**
- GitHub Actions runner'ları GitHub'ın cloud sunucularında çalışır
- Lokal bilgisayarınızdaki Kind cluster'a network erişimi yok
- KUBECONFIG olsa bile cluster'a bağlanamaz

**Çözüm:**
Self-hosted runner kullanın (lokal bilgisayarınızda GitHub Actions runner çalıştırın):

1. **Self-hosted runner kurulumu:**
   ```bash
   # Runner indir
   mkdir -p ~/actions-runner && cd ~/actions-runner
   curl -o actions-runner-osx-x64-2.311.0.tar.gz -L \
     https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
   tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz
   
   # GitHub'dan token al:
   # Repository → Settings → Actions → Runners → New self-hosted runner
   
   # Config et
   ./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token YOUR-TOKEN
   
   # Service olarak başlat (önerilen)
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```

2. **Workflow'u güncelleyin:**
   ```yaml
   jobs:
     build-and-deploy:
       runs-on: self-hosted  # ubuntu-latest yerine
   ```

3. **KUBECONFIG secret'ını ekleyin:**
   ```bash
   # Kind cluster için
   kind export kubeconfig --name kind-cluster | base64
   
   # GitHub → Settings → Secrets → Actions → New secret
   # Name: KUBECONFIG
   # Value: (base64 çıktısı)
   ```

**Alternatif Çözümler:**
- **Manuel Deploy**: CI/CD sadece build ve push yapar, deploy'u manuel yaparsınız
- **Cloud Cluster**: GKE, EKS, AKS gibi cloud cluster kullanın (production için)

**Dosyalar:**
- `.github/workflows/ci-cd.yml` - `runs-on: self-hosted` olarak güncellendi
- `SELF-HOSTED-RUNNER-SETUP.md` - Detaylı kurulum rehberi
- `DEPLOYMENT-OPTIONS.md` - Tüm deploy seçenekleri

**Not:** Self-hosted runner çalışırken bilgisayarınız açık olmalı.

---

## Genel Sorun Giderme Adımları

### Pod'lar Başlamıyor

```bash
kubectl get pods -n linkding

kubectl describe pod <pod-name> -n linkding


kubectl logs <pod-name> -n linkding

kubectl logs <pod-name> -n linkding --previous
```

### PVC Bind Edilemiyor

```bash
kubectl get storageclass

kubectl get pvc -n linkding

kubectl describe pvc postgres-pvc -n linkding

kubectl get pv
```

### Veritabanı Bağlantı Sorunları

```bash
kubectl exec -it deployment/postgres -n linkding -- psql -U linkding

kubectl exec deployment/postgres -n linkding -- psql -U linkding -c "\l"

kubectl exec deployment/postgres -n linkding -- psql -U linkding -d postgres -c "CREATE DATABASE linkding;"
```

### Linkding Migration Sorunları

```bash
kubectl exec deployment/linkding -n linkding -c linkding -- python manage.py showmigrations

kubectl exec deployment/linkding -n linkding -c linkding -- python manage.py migrate

kubectl exec -it deployment/linkding -n linkding -c linkding -- python manage.py createsuperuser
```

### Ingress Erişim Sorunları

```bash
kubectl get ingress -n linkding

kubectl describe ingress linkding-ingress -n linkding

kubectl get pods -n ingress-nginx

kubectl port-forward service/linkding 8080:80 -n linkding
# Sonra: curl http://localhost:8080
```

---

## ✅ Çözülen Sorunlar Özeti

| # | Sorun | Durum | Çözüm |
|---|-------|-------|-------|
| 1 | PVC bind edilemedi | ✅ Çözüldü | Local Path Provisioner kuruldu |
| 2 | PostgreSQL veritabanı yok | ✅ Çözüldü | setup.sh'e otomatik DB oluşturma eklendi |
| 3 | Django migration'ları çalışmadı | ✅ Çözüldü | setup.sh'e otomatik migration eklendi |
| 4 | Port 8080 kullanımda | ✅ Çözüldü | port-forward.sh varsayılan port 9090 |
| 5 | Ingress-Nginx kurulmuyor | ✅ Çözüldü | create-cluster.sh'e retry logic eklendi |
| 6 | Kind context hatası | ✅ Çözüldü | Dinamik context kontrolü eklendi |
| 7 | cloud-provider-kind syntax hatası | ✅ Çözüldü | Bash syntax düzeltildi |
| 8 | kind-config.yaml path sorunu | ✅ Çözüldü | SCRIPT_DIR değişkeni eklendi |
| 9 | Linkding login sorunu (CSRF) | ✅ Çözüldü | CSRF_TRUSTED_ORIGINS ve session affinity eklendi |
| 10 | PostgreSQL not ready | ✅ Çözüldü | StorageClass ve PVC kontrolleri eklendi |
| 11 | GitHub Actions lokal cluster deploy | ✅ Çözüldü | Self-hosted runner kuruldu |
| 12 | Kind cluster creation log timeout | ✅ Çözüldü | --wait 10m ve --retain parametreleri eklendi |
| 13 | Port 80/443 kullanımda | ✅ Çözüldü | Port kontrolü ve otomatik fallback eklendi |
| 14 | cloud-provider-kind temizlenmiyor | ✅ Çözüldü | cleanup.sh ve create-cluster.sh'e otomatik temizlik eklendi |

---

### 12. Kind Cluster Creation Timeout - "could not find a log line that matches"

**Sorun:**
```
ERROR: failed to create cluster: could not find a log line that matches "Reached target .*Multi-User System.*|detected cgroup v1"
```

**Neden:**
- Kind, node'un başladığını doğrulamak için belirli log satırlarını bekliyor
- Docker yavaş başlıyor veya timeout çok kısa
- macOS'ta özel durumlar (cgroup v1/v2)
- Kind versiyonu ile node image uyumsuzluğu

**Çözüm:**

1. **Wait süresini artırın:**
   ```bash
   kind create cluster --config kind-config.yaml --wait 10m
   ```

2. **--retain parametresi ekleyin:**
   ```bash
   kind create cluster --config kind-config.yaml --wait 10m --retain
   ```
   Bu sayede hata durumunda cluster silinmez, manuel kontrol edilebilir.

3. **Docker'ı kontrol edin:**
   ```bash
   docker ps
   docker system df
   ```

4. **Mevcut cluster'ları temizleyin:**
   ```bash
   kind delete clusters --all
   ```

5. **create-cluster.sh scripti güncellendi:**
   - `--wait 10m` parametresi eklendi
   - `--retain` parametresi eklendi
   - Hata durumunda cluster'ın erişilebilirliği kontrol ediliyor
   - Docker hazır olana kadar bekleniyor

**Alternatif Çözüm:**

Eğer sorun devam ederse, Kind versiyonunu kontrol edin:
```bash
kind version
# Kind v0.30.0+ için default node image v1.34.0
```

Manuel olarak node image belirtmek isterseniz (önerilmez):
```yaml
# kind-config.yaml
nodes:
- role: control-plane
  image: kindest/node:v1.31.0@sha256:...
```

**Not:** `create-cluster.sh` scripti artık bu sorunu otomatik olarak handle ediyor.

---

### 13. Port 80/443 Kullanımda - "ports are not available: address already in use"

**Sorun:**
```
ERROR: failed to create cluster: ports are not available: exposing port TCP 0.0.0.0:80 -> 127.0.0.1:0: listen tcp4 0.0.0.0:80: bind: address already in use
```

**Neden:**
- Port 80 veya 443 başka bir servis tarafından kullanılıyor
- macOS'ta genellikle AirPlay Receiver port 80'i kullanır
- `cloud-provider-kind` process'i port 80'i kullanıyor olabilir
- Apache, Nginx veya başka bir web sunucusu çalışıyor olabilir

**Çözüm:**

1. **Port 80/443'ü kullanan process'leri bulun:**
   ```bash
   sudo lsof -i :80 -P
   sudo lsof -i :443 -P
   ```

2. **cloud-provider-kind process'ini durdurun:**
   ```bash
   # Tüm cloud-provider-kind process'lerini durdur
   sudo pkill -9 cloud-provider-kind
   
   # Veya belirli bir PID ile
   sudo kill -9 <PID>
   ```

3. **Port 80/443'ü kullanan diğer process'leri durdurun:**
   ```bash
   # Port 80'i kullanan process'leri durdur
   sudo kill -9 $(sudo lsof -t -i:80)
   
   # Port 443'ü kullanan process'leri durdur (sadece LISTEN durumundakiler)
   sudo kill -9 $(sudo lsof -t -i:443 -sTCP:LISTEN)
   ```

4. **macOS AirPlay Receiver'ı kapatın:**
   - System Settings > General > AirDrop & Handoff
   - AirPlay Receiver'ı kapatın

5. **Otomatik çözüm scriptleri:**
   ```bash
   # Port durumunu kontrol et
   ./scripts/free-ports.sh
   
   # Portları serbest bırak (interaktif)
   ./scripts/kill-ports.sh
   ```

6. **create-cluster.sh otomatik fallback:**
   - Script port kontrolü yapıyor
   - Port kullanılıyorsa geçici config (port mapping olmadan) oluşturuyor
   - Port hatası alınırsa otomatik olarak port mapping olmadan tekrar deniyor

**Alternatif Erişim Yöntemleri:**

Port mapping olmadan cluster oluşturulursa:

1. **LoadBalancer IP (cloud-provider-kind):**
   ```bash
   kubectl get svc -n ingress-nginx
   # EXTERNAL-IP'i kullanın
   ```

2. **Port-forward:**
   ```bash
   kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
   # Sonra: http://localhost:8080
   ```

**Not:** `cleanup.sh` scripti artık cluster silindiğinde `cloud-provider-kind` process'ini de otomatik olarak durduruyor.

---

### 14. cloud-provider-kind Process'i Temizlenmiyor

**Sorun:**
- Cluster silindiğinde `cloud-provider-kind` process'i çalışmaya devam ediyor
- Port 80/443 kullanımda kalıyor

**Neden:**
- `cloud-provider-kind` arka planda çalışıyor ve otomatik durmuyor
- Cluster silindiğinde process temizlenmiyor

**Çözüm:**

1. **Manuel olarak durdurun:**
   ```bash
   # Tüm cloud-provider-kind process'lerini bul
   pgrep -f cloud-provider-kind
   
   # Durdur
   sudo pkill -9 cloud-provider-kind
   ```

2. **cleanup.sh scripti kullanın:**
   ```bash
   ./scripts/cleanup.sh
   # Script otomatik olarak cloud-provider-kind'ı durdurur
   ```

3. **create-cluster.sh otomatik temizlik:**
   - Mevcut cluster silinmeden önce `cloud-provider-kind` durdurulur
   - Cluster silinirken process'ler temizlenir

**Önleme:**

Cluster silmeden önce her zaman `cleanup.sh` scriptini çalıştırın:
```bash
./scripts/cleanup.sh
kind delete cluster --name kind-cluster
```

---

## 🚀 Önleyici Önlemler

### 1. Otomatik Veritabanı Oluşturma

PostgreSQL deployment'ına init container eklenebilir:
```yaml
initContainers:
- name: init-db
  image: postgres:15-alpine
  command: ['sh', '-c', 'until pg_isready -h postgres; do sleep 1; done && psql -U linkding -d postgres -c "SELECT 1 FROM pg_database WHERE datname='\''linkding'\''" | grep -q 1 || psql -U linkding -d postgres -c "CREATE DATABASE linkding;"']
```

### 2. Otomatik Migration

Linkding deployment'ına migration init container eklenebilir:
```yaml
initContainers:
- name: migrate
  image: sissbruecker/linkding:1.22.0
  command: ["python", "manage.py", "migrate", "--noinput"]
  env:
    # Tüm Linkding environment variables
```

### 3. Health Check İyileştirmeleri

PostgreSQL liveness/readiness probe'ları veritabanı varlığını kontrol edebilir:
```yaml
readinessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - 'pg_isready -U linkding -d linkding'
```
