# SSL Session Cache - Detailed Explanation

## 🔐 Apa itu SSL Session Cache?

Ketika client (browser) connect ke HTTPS server, mereka harus melakukan SSL/TLS handshake:

### Tanpa Session Cache (SLOW):
```
Client                           Server
  |                                |
  |-----> ClientHello ----------->|
  |<----- ServerHello, Cert ------|
  |-----> KeyExchange ----------->|
  |<----- ChangeCipherSpec -------|
  |-----> Finished --------------->|
  |<----- Finished ----------------|
  |                                |
  | 🕐 ~100-200ms full handshake  |
```

### Dengan Session Cache (FAST):
```
Client (punya session ID)        Server
  |                                |
  |-----> ClientHello (ID) ------>|
  |       "I was here before"      |
  |                                |
  |<----- "OK, reuse session" ----|
  |                                |
  | 🚀 ~10-20ms resume handshake  |
```

---

## 📊 Syntax Breakdown

```apache
SSLSessionCache shmcb:/usr/local/apache2/logs/ssl_scache(512000)
                │      │                                   │
                │      │                                   └─ Buffer size
                │      └─ File path untuk cache storage
                └─ Cache method (Shared Memory Cyclic Buffer)
```

### Cache Methods Available:

| Method | Syntax Example | Use Case |
|--------|---------------|----------|
| **shmcb** (Recommended) | `shmcb:/path(512000)` | Production - fast, thread-safe |
| dbm | `dbm:/path` | Legacy - slow, file-based |
| dc | `dc:UNIX:/path` | Distributed - multi-server |
| memcache | `memcache:host:port` | External cache server |
| nonenotnull | `nonenotnull` | Session IDs tanpa cache (testing) |
| none | `none` | No session resumption (very slow) |

---

## ⚙️ Tuning Buffer Size

**Default kamu: 512000 bytes (512 KB)**

### Sizing Guide:
```
Buffer Size (bytes)  ≈ SSL Sessions
-------------------------------------------
  51200  (50 KB)     ~1,000 sessions
 102400  (100 KB)    ~2,000 sessions
 512000  (500 KB)    ~10,000 sessions  ← Your setting
1048576  (1 MB)      ~20,000 sessions
5242880  (5 MB)      ~100,000 sessions
```

### Calculation Formula:
```
Sessions ≈ (Buffer Size) / 50 bytes
```

**Rule of thumb:**
- Small server (<100 concurrent users): 100KB
- Medium server (100-1000 users): 512KB ← Your setting ✅
- Large server (1000-10000 users): 1-5MB
- Very large (>10000 users): 5-10MB

---

## 🎯 Verification Commands

### 1. Check if module loaded:
```bash
docker exec l-e-a-p_apache2 httpd -M | grep socache_shmcb
# Output: socache_shmcb_module (shared)
```

### 2. Check cache configuration:
```bash
docker exec l-e-a-p_apache2 httpd -t -D DUMP_CONFIG | grep SSLSessionCache
# Output: SSLSessionCache shmcb:/usr/local/apache2/logs/ssl_scache(512000)
```

### 3. Monitor cache usage (requires mod_status):
```bash
# Access https://10.20.0.2/server-status (if enabled)
# Look for: SSL/TLS Session Cache Status
```

### 4. Check cache file created:
```bash
docker exec l-e-a-p_apache2 ls -lh /usr/local/apache2/logs/ssl_scache*
# Will show cache file after first SSL connection
```

---

## 🔧 Alternative Configurations

### 1. Basic (minimal caching):
```apache
SSLSessionCache shmcb:/usr/local/apache2/logs/ssl_scache(102400)
```

### 2. High-traffic (banyak user):
```apache
SSLSessionCache shmcb:/usr/local/apache2/logs/ssl_scache(5242880)
SSLSessionCacheTimeout 300  # 5 minutes (default)
```

### 3. Multi-server (dengan Memcached):
```apache
SSLSessionCache memcache:memcached-server:11211
SSLSessionCacheTimeout 600
```

### 4. Testing only (no cache):
```apache
SSLSessionCache nonenotnull
# WARNING: Every connection = full handshake (very slow)
```

---

## 📈 Performance Impact

### Test scenario: 1000 HTTPS requests

**Without session cache:**
```
Total time: ~150 seconds
Average per request: 150ms
SSL handshakes: 1000 (all full)
CPU usage: High (crypto operations)
```

**With session cache (512KB):**
```
Total time: ~20 seconds
Average per request: 20ms
SSL handshakes: 1 full + 999 resumed
CPU usage: Low (cache lookups only)
```

**Improvement: 7.5x faster! 🚀**

---

## 🐛 Troubleshooting

### Error: "SSLSessionCache: 'shmcb' session cache not supported"
**Fix:** Enable `socache_shmcb_module`
```dockerfile
RUN sed -i 's/^#\(LoadModule socache_shmcb_module .*\)/\1/' /usr/local/apache2/conf/httpd.conf
```

### Warning: "Cache too small"
**Symptom:** Cache file size = buffer size (always full)
**Fix:** Increase buffer size:
```apache
SSLSessionCache shmcb:/path(1048576)  # Increase to 1MB
```

### Error: Permission denied on cache file
**Fix:** Ensure Apache can write to logs directory:
```bash
docker exec l-e-a-p_apache2 chown -R www-data:www-data /usr/local/apache2/logs
```

---

## 🎓 Best Practices

1. ✅ **Always use shmcb** (fastest, most reliable)
2. ✅ **Size appropriately** (don't over-allocate memory)
3. ✅ **Monitor cache hit ratio** (via mod_status if enabled)
4. ✅ **Use session timeout** (default 300s is good)
5. ❌ **Don't disable** unless debugging SSL issues

---

## 📚 Related Directives

```apache
# Session cache timeout (seconds)
SSLSessionCacheTimeout 300

# Disable session tickets (optional - for PFS)
SSLSessionTickets off

# SSL protocol versions
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1

# Cipher suites (example - strong ciphers only)
SSLCipherSuite HIGH:!aNULL:!MD5
```

---

**Summary untuk setup kamu:**
- ✅ Method: `shmcb` (optimal)
- ✅ Size: `512KB` (good untuk medium traffic)
- ✅ Path: `/usr/local/apache2/logs/ssl_scache` (standard location)
- ✅ Module loaded: `socache_shmcb_module` (line 11 Dockerfile)

**Tidak perlu diubah** kecuali kamu punya traffic sangat tinggi (>1000 concurrent HTTPS connections).