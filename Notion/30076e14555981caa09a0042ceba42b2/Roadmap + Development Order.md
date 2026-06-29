Bu dokümanda ürünün fazlara bölünmüş roadmap’i ve geliştirme sırası tanımlanır. İlk geliştirme odağı backend olacaktır. Frontend daha sonra backend API contract oturduktan sonra bağlanacaktır.

## 1. Genel Geliştirme Yaklaşımı

Ürün “çok basit MVP” olarak değil, gerçek ürüne evrilebilecek sağlam bir çekirdek olarak geliştirilecek. Ancak ilk aşamada kapsam kontrollü tutulacak.

İlk sürümde odak:

```
- Solidity / EVM
- Tek .sol dosyası veya pasted code
- Static analysis
- Rule Engine
- Slither integration
- LLM explanation layer
- UI / JSON / Markdown report
```

İlk sürümde olmayacaklar:

```
- GitHub repo scan
- Contract address scan
- Multi-file project analysis
- Dynamic testing
- Fuzzing
- Auto code rewrite
```

---

## 2. Phase 1 — Backend Core

İlk olarak Rust backend geliştirilecek.

Amaç:

```
Scanner’ın analiz pipeline’ını backend tarafında çalışır hale getirmek.
```

Bu fazda yapılacaklar:

```
- Axum backend kurulumu
- PostgreSQL + SQLx bağlantısı
- Scan oluşturma endpointi
- Scan status endpointi
- Report endpointi
- Input validation
- Scan job lifecycle
- Basic database tables
- Analyzer pipeline iskeleti
```

Backend endpointleri:

```
POST /api/scans
GET  /api/scans/{scan_id}
GET  /api/scans/{scan_id}/report
GET  /api/scans/{scan_id}/export/json
GET  /api/scans/{scan_id}/export/markdown
```

Bu fazın sonunda kullanıcı henüz tam güvenlik analizi görmeyebilir ama backend scan job oluşturup durum takip edebilir hale gelmelidir.

---

## 3. Phase 2 — Rule Engine

Backend iskeleti kurulduktan sonra custom Rule Engine geliştirilecek.

Amaç:

```
Solidity kodu üzerinde deterministic güvenlik kontrolleri çalıştırmak.
```

İlk rule set:

```
- tx.origin usage
- selfdestruct usage
- delegatecall usage
- inline assembly
- floating pragma
- outdated pragma
- hardcoded address
```

Sonraki rule set:

```
- unprotected admin-like functions
- unchecked low-level call
- unsafe ERC20 transfer
- missing events
- external call before state update
- missing reentrancy guard
- initializer / upgrade function protection
```

Bu fazın sonunda backend, LLM veya Slither olmadan da temel güvenlik bulguları üretebilmelidir.

---

## 4. Phase 3 — Finding Model + Risk Scoring

Rule Engine bulguları üretildikten sonra ortak finding modeli ve risk scoring sistemi tamamlanacak.

Amaç:

```
Tüm bulguları standart formata çevirmek ve severity hesaplamak.
```

Yapılacaklar:

```
- Finding model
- Finding status
- Severity mapping
- Confidence mapping
- Exploitability score
- Asset impact score
- Final score calculation
- Overall contract risk calculation
```

Final scoring modeli:

```
Final Risk = Base Severity + Confidence + Exploitability + Asset Impact
```

Bu fazın sonunda her finding için şu bilgiler hazır olmalı:

```
- title
- category
- severity
- confidence
- status
- location
- evidence
- score
```

---

## 5. Phase 4 — Slither Integration

Bu fazda Slither backend’e entegre edilecek.

Amaç:

```
Custom Rule Engine yanında profesyonel statik analiz çıktısı almak.
```

Yapılacaklar:

```
- Docker sandbox runner
- Temporary file manager
- Slither command execution
- Slither JSON output parsing
- Slither finding mapping
- Slither fail-soft behavior
```

Slither başarısız olursa scan tamamen fail olmamalı. Rule Engine sonuçları yine kullanıcıya gösterilmelidir.

Bu fazın sonunda scanner iki analiz kaynağına sahip olur:

```
- Custom Rule Engine
- Slither
```

---

## 6. Phase 5 — Finding Normalizer + Deduplication

Rule Engine ve Slither farklı formatlarda bulgu üreteceği için bunlar tek modele dönüştürülecek.

Amaç:

```
Aynı güvenlik problemini tek finding altında toplamak.
```

Yapılacaklar:

```
- Rule Engine findings normalize edilir
- Slither findings normalize edilir
- Duplicate findings merge edilir
- Source badges oluşturulur
- Confidence source sayısına göre güncellenir
```

Deduplication mantığı:

```
vulnerability_type + contract + function + approximate_line_range
```

Bu fazın sonunda kullanıcı aynı problemi üç farklı bulgu olarak görmez.

---

## 7. Phase 6 — LLM Analysis Layer

Bu fazda LLM destek katmanı eklenecek.

Amaç:

```
Bulguları açıklamak, exploit scenario ve fix suggestion üretmek.
```

LLM görevleri:

```
- Contract summary
- Main risk areas
- Finding summary
- Technical details
- Exploit scenario
- Fix suggestion
- False-positive note
```

LLM karar modeli:

```
- LLM tek başına nihai karar vermez
- LLM-only bulgular Confirmed olmaz
- LLM-only bulgular Potential veya Needs Review olur
- Full contract rewrite yapılmaz
- Sadece fix suggestion verilir
```

Bu fazın sonunda raporlar teknik ama okunabilir hale gelir.

---

## 8. Phase 7 — Report Generation

Bu fazda UI, JSON ve Markdown rapor çıktıları tamamlanır.

Amaç:

```
Scan sonucunu kullanıcıya profesyonel ve paylaşılabilir formatta sunmak.
```

Çıktılar:

```
- UI report response
- JSON export
- Markdown export
```

Report içeriği:

```
- Scan summary
- Overall risk
- Severity distribution
- Contract metadata
- Main risk areas
- Finding list
- Finding details
- Evidence
- Fix suggestions
```

Bu faz backend tarafında tamamlandıktan sonra frontend geliştirme daha rahat ilerler.

---

## 9. Phase 8 — Frontend Integration

Backend API ve report modeli oturduktan sonra frontend geliştirilecek.

Amaç:

```
Kullanıcının contract yükleyip scan başlatabileceği ve rapor görebileceği arayüzü oluşturmak.
```

Frontend ekranları:

```
- New Scan screen
- Scan Progress screen
- Report Overview screen
- Finding Detail view
- Export JSON / Markdown actions
```

İlk UI özellikleri:

```
- Paste Solidity code
- Upload .sol file
- Scan progress
- Overall risk badge
- Finding cards
- Source badges
- JSON export
- Markdown export
```

Kod üzerinde line-by-line annotation ilk sürümde zorunlu değildir. Finding içinde contract, function ve line bilgisi gösterilmesi yeterlidir.

---

## 10. Phase 9 — Sandbox Hardening + Public Readiness

Ürün public kullanıma yaklaşırken sandbox ve güvenlik limitleri sıkılaştırılacak.

Yapılacaklar:

```
- Docker security hardening
- Network disabled execution
- CPU/RAM limits
- Timeout limits
- Temporary file cleanup
- Rate limiting
- Safe logging
- Raw code storage policy
```

Başlangıç limitleri:

```
Max file size: 1 MB
Max lines: 5000
Slither timeout: 30-60 seconds
Container memory: 512 MB - 1 GB
CPU limit: 1 core
Network: disabled
```

---

## 11. Phase 10 — Future Roadmap

İlk ürün çekirdeği tamamlandıktan sonra roadmap genişletilecek.

Sonraki özellikler:

```
- GitHub repo scan
- Multi-file project analysis
- Contract address scan
- Explorer source code fetch
- Foundry / Hardhat project support
- Dynamic testing
- Fuzzing
- CI/CD integration
- Team dashboard
- Historical scan comparison
- PDF report
```

Dinamik test roadmap’te sonraya bırakılacak. İlk sürüm tamamen statik analiz odaklı olacak.

---

## 12. Önerilen Development Order

Backend-first geliştirme sırası:

```
1. Rust backend project setup
2. Axum API skeleton
3. PostgreSQL + SQLx setup
4. Scan database model
5. POST /api/scans
6. GET /api/scans/{scan_id}
7. Basic scan job lifecycle
8. Input validation
9. Solidity preprocessing
10. Rule Engine v1
11. Finding model
12. Risk scoring
13. JSON report generation
14. Markdown report generation
15. Slither Docker integration
16. Slither output normalization
17. Deduplication
18. LLM analysis layer
19. Full report endpoint
20. Frontend integration
21. Sandbox hardening
22. Roadmap features
```

Bu sıra backend’i önce ayağa kaldırır, ardından analiz kalitesini parça parça artırır. Frontend, backend contract ve report modeli netleştikten sonra bağlanacağı için daha az yeniden yazma gerektirir.

---

## 13. Final Karar

Geliştirme stratejisi:

```
Önce backend.
Sonra Rule Engine.
Sonra risk scoring ve report.
Sonra Slither.
Sonra LLM.
Sonra frontend.
En son public readiness ve roadmap özellikleri.
```

Bu yaklaşım, ürünü erken aşamada çalışır hale getirirken mimariyi ileride büyüyebilecek şekilde korur.