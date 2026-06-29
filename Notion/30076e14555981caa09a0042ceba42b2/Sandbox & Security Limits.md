Bu aşamada amaç, kullanıcıdan gelen Solidity kodunun ve Slither analiz sürecinin backend sistemine zarar vermeyecek şekilde izole edilmesidir. İlk sürümde sadece tek `.sol` dosyası veya pasted code analiz edilecek olsa da, ileride GitHub repo scan ve dynamic testing ekleneceği için güvenli çalışma modeli baştan doğru kurulmalıdır.

## 1. Temel Güvenlik Kararı

Kullanıcıdan gelen kod hiçbir zaman doğrudan host sistem üzerinde çalıştırılmamalıdır.

İlk sürüm statik analiz yapacak:

```
- Contract deploy edilmeyecek
- Transaction simülasyonu yapılmayacak
- Testnet/local chain üzerinde çalıştırılmayacak
- Kod sadece parse/static analysis için kullanılacak
```

Ancak Slither gibi araçlar dosya sistemi ve compiler ile etkileşime girebildiği için sandbox içinde çalıştırılmalıdır.

---

## 2. Slither Sandbox Modeli

Slither analizi Docker sandbox içinde çalıştırılacak.

Akış:

```
1. Backend scan için temporary klasör oluşturur
2. Kullanıcı kodunu Contract.sol olarak yazar
3. Docker container başlatılır
4. Slither container içinde çalışır
5. JSON output alınır
6. Container kapatılır
7. Temporary dosyalar temizlenir
```

Bu yapı host sistemin kullanıcı inputundan izole kalmasını sağlar.

---

## 3. Docker Güvenlik Limitleri

Slither container şu kısıtlarla çalıştırılmalıdır:

```
- Network disabled
- Read-only root filesystem mümkünse aktif
- Sadece scan klasörü mount edilir
- CPU limiti uygulanır
- RAM limiti uygulanır
- Timeout uygulanır
- Container scan sonunda silinir
```

Önerilen başlangıç limitleri:

```
Max file size: 1 MB
Max lines: 5000
Slither timeout: 30-60 seconds
Container memory: 512 MB - 1 GB
CPU limit: 1 core
Network: disabled
```

İlk sürüm tek dosya analiz ettiği için bu limitler yeterli olur. İleride GitHub repo scan geldiğinde limitler ayrı değerlendirilmelidir.

---

## 4. Input Validation Limitleri

Analiz başlamadan önce backend input’u kontrol eder.

Kontroller:

```
- Dosya uzantısı .sol mu?
- İçerik Solidity’ye benziyor mu?
- Dosya boyutu limiti aşıldı mı?
- Satır sayısı limiti aşıldı mı?
- İçerik boş veya çok kısa mı?
- Binary/garip karakter içeriyor mu?
```

Önerilen error davranışları:

```
FILE_TOO_LARGE
INVALID_SOLIDITY_INPUT
EMPTY_INPUT
UNSUPPORTED_FILE_TYPE
```

Bu kontroller sayesinde gereksiz sandbox çalıştırma maliyeti azalır.

---

## 5. Fail-Soft Yaklaşımı

Slither çalışamazsa tüm scan başarısız sayılmamalı.

Önerilen davranış:

```
Rule Engine fail olursa → scan failed
Slither fail olursa → warning ekle, scan devam etsin
LLM fail olursa → explanation eksik kalabilir, scan devam etsin
Report generation fail olursa → scan failed
```

Örnek UI warning:

```
Slither analysis could not be completed. Rule Engine results are still available.
```

Böylece kullanıcı en azından deterministic rule engine sonuçlarını görebilir.

---

## 6. Temporary File Yönetimi

Her scan için izole temporary klasör oluşturulmalıdır.

Örnek yapı:

```
/tmp/scans/{scan_id}/Contract.sol
/tmp/scans/{scan_id}/slither-output.json
```

Scan tamamlandıktan sonra:

```
- Temporary Solidity dosyası silinir
- Slither output işlenir ve DB’ye kaydedilir
- Container silinir
- Temporary klasör temizlenir
```

Debug için istenirse sadece kısa süreli log tutulabilir. Kullanıcı kodunu uzun süre raw file olarak saklamak gerekmiyorsa saklanmamalıdır. Bunun yerine `source_hash` tutulabilir.

---

## 7. Rate Limit ve Abuse Protection

Ürün public hale geldiğinde kullanıcılar çok fazla scan başlatabilir. Bu yüzden basit rate limit olmalıdır.

Başlangıç önerisi:

```
Anonymous user:
- Dakikada sınırlı scan
- Günlük sınırlı scan

Authenticated user:
- Daha yüksek limit

Large input:
- Daha sıkı limit
```

İlk geliştirme aşamasında auth yoksa IP bazlı basit rate limit yeterli olabilir.

---

## 8. Logging ve Privacy

Loglarda kullanıcı contract kodunun tamamı tutulmamalıdır.

Loglanabilecek bilgiler:

```
- scan_id
- status
- duration
- error code
- analyzer step
- source_hash
```

Loglanmaması gerekenler:

```
- Full Solidity source code
- Private business logic
- Secrets veya private key benzeri değerler
```

İleride GitHub repo veya private contract desteği gelirse privacy konusu daha da önemli hale gelir.

---

## 9. Roadmap’e Hazırlık

Sandbox mimarisi sadece bugünkü Slither ihtiyacı için değil, ilerideki özellikler için de temel oluşturur.

İleride eklenecekler:

```
- GitHub repo scan
- Contract address source fetch
- Foundry/Hardhat compile
- Fuzzing
- Dynamic testing
- Local chain simulation
```

Bu özellikler geldiğinde sandbox zorunlu hale gelir. Bu yüzden ilk sürümde bile Docker tabanlı izolasyon kurulmalıdır.

---

## 10. Final Karar

Sandbox & Security modeli şu şekilde olacak:

```
Execution:
- Kullanıcı kodu host üzerinde çalıştırılmaz
- Slither Docker sandbox içinde çalışır
- Network disabled
- CPU/RAM/timeout limitleri uygulanır

Input:
- .sol veya pasted code
- Max 1 MB
- Max 5000 satır

Storage:
- Raw code uzun süre saklanmaz
- source_hash tutulur
- findings/report DB’ye kaydedilir

Failure:
- Slither fail olursa scan devam eder
- Rule Engine fail olursa scan failed
- LLM fail olursa explanation warning ile eksik kalabilir

Security:
- Temporary files cleanup
- Rate limit
- Safe logging
```

Bu yapı scanner’ın public ürüne dönüşürken güvenli, kontrollü ve genişletilebilir şekilde çalışmasını sağlar.