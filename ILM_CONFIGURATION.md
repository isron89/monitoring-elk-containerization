# ILM (Index Lifecycle Management) Configuration

## 📋 Ringkasan

ILM telah dikonfigurasi untuk otomatis menghapus data lama berdasarkan environment:

| Environment | Pattern Index | Retention Period |
|-------------|---------------|------------------|
| **Development** | `mypertamina-dev-*` | **7 hari** |
| **Staging** | `mypertamina-staging-*` | **30 hari** |
| **Production** | `mypertamina-prod-*` | **90 hari** |

---

## 🚀 Cara Mengaktifkan ILM

### 1. Start Docker dan Services

```bash
# Start Docker Desktop (jika belum running)
open -a Docker

# Tunggu Docker ready, lalu start services
docker-compose up -d

# Wait for Elasticsearch to be healthy
docker-compose ps
```

### 2. Update Logstash User Permissions

```bash
# Update role permissions untuk ILM
curl -X POST -u elastic:pertamina 'http://localhost:9200/_security/role/logstash_writer' \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["manage_index_templates", "monitor", "manage_ilm", "read_ilm"],
    "indices": [
      {
        "names": ["telemetry-*", "logstash-*", "mypertamina-*"],
        "privileges": ["write", "create", "create_index", "manage", "manage_ilm", "view_index_metadata"]
      }
    ]
  }'
```

### 3. Setup ILM Policies dan Templates

```bash
./setup-ilm-policies.sh
```

Script ini akan:
- ✅ Membuat 3 ILM policies (dev: 7d, staging: 30d, prod: 90d)
- ✅ Membuat index templates dengan mapping fields
- ✅ Mengaitkan templates dengan ILM policies

### 4. Restart Logstash

```bash
docker-compose restart logstash
```

### 5. Verifikasi ILM

```bash
# Check ILM policies
curl -u elastic:pertamina 'http://localhost:9200/_ilm/policy?pretty'

# Check index templates
curl -u elastic:pertamina 'http://localhost:9200/_index_template?pretty'

# Check indices dengan ILM info
curl -u elastic:pertamina 'http://localhost:9200/mypertamina-*/_ilm/explain?pretty'
```

---

## 📊 ILM Lifecycle Phases

### 🔥 HOT Phase (All Environments)
**Timing:** Immediate (0 days)

**Actions:**
- Data aktif, bisa ditulis dan dibaca
- Rollover otomatis setelah:
  - **1 hari**, atau
  - **50GB** ukuran shard
- Priority: **100** (highest)

---

### 🌡️ WARM Phase (Staging & Production)
**Timing:**
- **Staging:** 7 hari setelah index dibuat
- **Production:** 7 hari setelah index dibuat

**Actions:**
- Index menjadi **read-only**
- Data masih dapat dicari dengan cepat
- Priority: **50** (medium)
- Cocok untuk data yang jarang diubah tapi masih perlu diakses

---

### ❄️ COLD Phase (Production Only)
**Timing:** 30 hari setelah index dibuat

**Actions:**
- Data archived
- Priority: **0** (lowest)
- Cocok untuk compliance/audit logs
- Performa query lebih lambat

---

### 🗑️ DELETE Phase
**Timing berdasarkan environment:**
- **Dev:** 7 hari
- **Staging:** 30 hari
- **Production:** 90 hari

**Actions:**
- Index **dihapus otomatis**
- Data tidak dapat di-recover
- Storage dibebaskan

---

## 🔍 Monitoring ILM

### Check Status ILM di Specific Index

```bash
# Dev environment
curl -u elastic:pertamina 'http://localhost:9200/mypertamina-dev-2026.03.16/_ilm/explain?pretty'

# Staging environment
curl -u elastic:pertamina 'http://localhost:9200/mypertamina-staging-2026.03.16/_ilm/explain?pretty'

# Production environment
curl -u elastic:pertamina 'http://localhost:9200/mypertamina-prod-2026.03.16/_ilm/explain?pretty'
```

### Check Semua Indices dengan ILM

```bash
curl -u elastic:pertamina 'http://localhost:9200/mypertamina-*/_ilm/explain?pretty'
```

### Lihat ILM di Kibana

1. Open Kibana: http://localhost:5601
2. Go to **Stack Management** → **Index Lifecycle Policies**
3. Lihat policies: `mypertamina-dev-policy`, `mypertamina-staging-policy`, `mypertamina-prod-policy`

---

## 📈 Contoh Timeline

### Development Index (`mypertamina-dev-2026.03.16`)

```
Day 0:  ✅ Index created (HOT phase)
Day 1:  ✅ Rollover ke index baru
Day 7:  🗑️ Index dihapus otomatis
```

### Staging Index (`mypertamina-staging-2026.03.16`)

```
Day 0:  ✅ Index created (HOT phase)
Day 1:  ✅ Rollover ke index baru
Day 7:  🌡️ Move to WARM phase (read-only)
Day 30: 🗑️ Index dihapus otomatis
```

### Production Index (`mypertamina-prod-2026.03.16`)

```
Day 0:  ✅ Index created (HOT phase)
Day 1:  ✅ Rollover ke index baru
Day 7:  🌡️ Move to WARM phase (read-only)
Day 30: ❄️ Move to COLD phase (archived)
Day 90: 🗑️ Index dihapus otomatis
```

---

## ⚙️ Konfigurasi Custom

### Mengubah Retention Period

Edit file `setup-ilm-policies.sh` dan ubah nilai `min_age` di delete phase:

```json
"delete": {
  "min_age": "7d",    // Ubah ke "14d", "30d", "365d", dst
  "actions": {
    "delete": {}
  }
}
```

Lalu jalankan ulang:
```bash
./setup-ilm-policies.sh
```

### Menonaktifkan ILM untuk Specific Environment

Hapus policy dari index template:

```bash
# Contoh: disable ILM untuk dev
curl -X PUT -u elastic:pertamina 'http://localhost:9200/_index_template/mypertamina-dev-template' \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["mypertamina-dev-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1
      // Hapus baris: "index.lifecycle.name": "mypertamina-dev-policy"
    }
  }
}'
```

---

## 🔧 Troubleshooting

### Issue: ILM tidak berjalan

**Check:**
```bash
# Verifikasi ILM service running
curl -u elastic:pertamina 'http://localhost:9200/_ilm/status?pretty'
```

**Expected output:**
```json
{
  "operation_mode" : "RUNNING"
}
```

**Fix jika STOPPED:**
```bash
curl -X POST -u elastic:pertamina 'http://localhost:9200/_ilm/start'
```

---

### Issue: Index tidak menggunakan policy

**Cause:** Index dibuat sebelum template ada

**Fix:** Apply policy secara manual:

```bash
# Dev indices
curl -X PUT -u elastic:pertamina 'http://localhost:9200/mypertamina-dev-*/_settings' \
  -H "Content-Type: application/json" \
  -d '{
    "index.lifecycle.name": "mypertamina-dev-policy"
  }'
```

---

### Issue: Data tidak terhapus otomatis

**Check index age:**
```bash
curl -u elastic:pertamina 'http://localhost:9200/_cat/indices/mypertamina-*?v&h=index,creation.date.string,docs.count'
```

**Check ILM explain:**
```bash
curl -u elastic:pertamina 'http://localhost:9200/mypertamina-*/_ilm/explain?pretty'
```

---

## 💡 Best Practices

### 1. Monitor Storage Usage

```bash
# Check total storage per environment
curl -u elastic:pertamina 'http://localhost:9200/_cat/indices/mypertamina-dev-*?v&h=index,store.size,docs.count'
curl -u elastic:pertamina 'http://localhost:9200/_cat/indices/mypertamina-staging-*?v&h=index,store.size,docs.count'
curl -u elastic:pertamina 'http://localhost:9200/_cat/indices/mypertamina-prod-*?v&h=index,store.size,docs.count'
```

### 2. Backup Data Penting

Sebelum data dihapus otomatis, backup jika diperlukan:

```bash
# Snapshot important production data
# (Setup snapshot repository terlebih dahulu)
```

### 3. Test ILM di Dev Environment

Gunakan retention 1-2 hari di dev untuk test ILM berjalan dengan baik.

### 4. Alert untuk Storage

Setup alert di Kibana jika storage mencapai threshold tertentu.

---

## 📝 Summary Commands

```bash
# Complete setup dari awal
docker-compose up -d
sleep 30  # Wait for Elasticsearch
./setup-ilm-policies.sh
docker-compose restart logstash

# Verify setup
curl -u elastic:pertamina 'http://localhost:9200/_ilm/policy?pretty'
curl -u elastic:pertamina 'http://localhost:9200/_index_template?pretty'

# Monitor indices
curl -u elastic:pertamina 'http://localhost:9200/_cat/indices/mypertamina-*?v'

# Check ILM status
curl -u elastic:pertamina 'http://localhost:9200/mypertamina-*/_ilm/explain?pretty'
```

---

## 🎯 Expected Results

Setelah setup berhasil:

✅ **Old data terhapus otomatis**
- Dev: after 7 days
- Staging: after 30 days
- Production: after 90 days

✅ **Storage terkelola dengan baik**
- Indices lama terhapus
- Space tersedia untuk data baru

✅ **Performance optimal**
- Hot data: fast queries
- Old data: archived or deleted

✅ **Compliance**
- Data retention sesuai policy
- Audit trail tersimpan di production (90 hari)
