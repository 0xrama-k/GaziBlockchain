Bu aşamada scanner’a Slither entegrasyonu eklenir ve Rule Engine, Slither, LLM gibi farklı kaynaklardan gelen bulgular tek bir ortak finding modeline dönüştürülür.

## 1. Slither’ın Rolü

Slither, Solidity/EVM için kullanılacak profesyonel statik analiz aracıdır. Bizim custom Rule Engine’imiz kendi deterministic kontrollerimizi çalıştırırken, Slither daha geniş ve battle-tested güvenlik kontrolleri sağlar.

Slither’ın görevi:

- Solidity dosyasını statik olarak analiz etmek

- Reentrancy, unchecked call, access control, shadowing, dangerous patterns gibi bulgular üretmek

- Her bulgu için impact, confidence, description ve location bilgisi sağlamak

Slither çıktısı kullanıcıya ham şekilde gösterilmeyecek. Önce bizim sistem formatımıza normalize edilecek.

---

## 2. Slither Execution Flow

İlk sürümde input tek `.sol` dosyası veya yapıştırılmış Solidity kodu olacak.

Akış:

```
1. Kullanıcı kodu gönderir
2. Backend kodu geçici bir scan klasörüne yazar
3. Slither sandbox içinde çalıştırılır
4. Slither JSON çıktısı alınır
5. Çıktı internal raw finding modeline dönüştürülür
6. Slither çalışamazsa scan tamamen fail olmaz
```

Slither fail olursa:

```
Rule Engine ve LLM analizi devam eder.
Raporda “Slither analysis unavailable/failed” şeklinde uyarı gösterilir.
```

Bu önemli çünkü ürün tek bir analiz aracına bağımlı kalmamalı.

---

## 3. Slither Sandbox Kararı

Slither kullanıcı kodu üzerinde çalışacağı için güvenli ortamda çalıştırılmalı.

Önerilen yapı:

```
- Docker sandbox
- Timeout
- CPU/RAM limiti
- Network disabled
- Temporary filesystem
- Scan bitince dosyalar temizlenir
```

İlk sürüm statik analiz yapacağı için kod deploy edilmez, çalıştırılmaz, transaction simülasyonu yapılmaz.

---

## 4. Slither Output Mapping

Slither’ın kendi çıktısı bizim finding modelimize map edilir.

Örnek mapping:

```
Slither impact:
High          → High
Medium        → Medium
Low           → Low
Informational → Informational

Slither confidence:
High   → High
Medium → Medium
Low    → Low
```

Slither detector isimleri category’ye çevrilir:

```
reentrancy-*         → Reentrancy
unchecked-*          → Transfer Safety
tx-origin            → Access Control
delegatecall         → Dangerous EVM
controlled-delegatecall → Dangerous EVM / Access Control
timestamp            → Randomness
assembly             → Dangerous EVM
solc-version         → Code Quality
```

---

## 5. Finding Normalizer’ın Rolü

Finding Normalizer, tüm analiz kaynaklarını tek modele dönüştüren katmandır.

Kaynaklar:

```
- Rule Engine findings
- Slither findings
- LLM observations
```

Normalizer’ın görevi:

```
- Farklı source formatlarını ortak modele çevirmek
- Severity ve confidence değerlerini standardize etmek
- Location bilgisini normalize etmek
- Aynı problemi tekrar eden bulguları birleştirmek
- Source bilgisini korumak
- Final risk scoring için hazır veri üretmek
```

---

## 6. Ortak Finding Modeli

Normalize edilmiş finding şu yapıda olmalı:

```json
{
  "id": "FIND-001",
  "title": "Unchecked low-level call",
  "category": "Transfer Safety",
  "severity": "High",
  "confidence": "High",
  "status": "Confirmed",
  "sources": ["rule_engine", "slither"],
  "location": {
    "file": "Contract.sol",
    "contract": "Vault",
    "function": "withdraw",
    "line_start": 42,
    "line_end": 45
  },
  "summary": "",
  "technical_details": "",
  "exploit_scenario": "",
  "fix_suggestion": "",
  "evidence": [
    "msg.sender.call{value: amount}(\"\")"
  ],
  "score": {}
}
```

Bu model UI, JSON export ve Markdown report için ortak temel olacak.

---

## 7. Deduplication Mantığı

Aynı bulgu Rule Engine ve Slither tarafından ayrı ayrı bulunabilir. Kullanıcıya aynı problem birden fazla kez gösterilmemeli.

Örnek:

```
Rule Engine:
Low-level call return value is not checked

Slither:
Unchecked low-level call

LLM:
External call result is ignored
```

Bunlar tek finding altında birleştirilmeli.

Deduplication key:

```
vulnerability_type + contract + function + approximate_line_range
```

Merge sonrası:

```json
{
  "title": "Unchecked low-level call",
  "sources": ["rule_engine", "slither", "llm"],
  "confidence": "High"
}
```

Birden fazla kaynak aynı bulguyu destekliyorsa confidence artırılır.

---

## 8. Source Priority

Kaynakların güvenilirlik seviyesi aynı değildir.

Önerilen öncelik:

```
Rule Engine + Slither + LLM → çok güçlü bulgu
Rule Engine + Slither       → güçlü bulgu
Slither + LLM               → güçlü bulgu
Rule Engine only            → güvenilir deterministic bulgu
Slither only                → güvenilir static analysis bulgusu
LLM only                    → Needs Review / Potential
```

LLM-only bulgular confirmed olarak gösterilmez.

---

## 9. Final Karar

Bu aşamanın sonunda sistem şu yeteneklere sahip olacak:

```
- Slither analizini sandbox içinde çalıştırma
- Slither JSON çıktısını internal modele çevirme
- Rule Engine ve Slither bulgularını aynı formatta toplama
- Duplicate bulguları merge etme
- Kaynak bilgisini koruma
- Risk scoring ve LLM explanation için temiz finding listesi üretme
```

Bu katman scanner’ın “analiz sonuçlarını güvenilir ürüne dönüştüren” ana bağlayıcı katmanı olacak.