Bu aşamada frontend ile Rust backend’in nasıl haberleşeceğini netleştiriyoruz. Backend mimarisinde endpointleri genel olarak belirlemiştik; burada ise her endpointin ne alacağı, ne döneceği ve hata formatının nasıl olacağı tanımlanır.

## 1. Ana Endpointler

İlk sürüm için gerekli endpointler:

```
POST /api/scans
GET  /api/scans/{scan_id}
GET  /api/scans/{scan_id}/report
GET  /api/scans/{scan_id}/export/json
GET  /api/scans/{scan_id}/export/markdown
```

İlk sürümde olmayacaklar:

```
GitHub repo scan
Contract address scan
Multi-file project scan
Dynamic/fuzz test endpointleri
```

---

## 2. Scan Başlatma

Endpoint:

```
POST /api/scans
```

Amaç:

Kullanıcının yapıştırdığı Solidity kodu veya yüklediği `.sol` dosyası için yeni scan oluşturmak.

Request örneği:

```json
{
  "input_type": "pasted_code",
  "filename": "Vault.sol",
  "source_code": "pragma solidity ^0.8.20; contract Vault { ... }"
}
```

Alternatif input type:

```json
{
  "input_type": "uploaded_file",
  "filename": "Vault.sol",
  "source_code": "..."
}
```

Response örneği:

```json
{
  "scan_id": "scan_123",
  "status": "queued",
  "message": "Scan created successfully."
}
```

Bu endpoint scan sonucunu direkt dönmez. Sadece scan job oluşturur.

---

## 3. Scan Status Sorgulama

Endpoint:

```
GET /api/scans/{scan_id}
```

Amaç:

Frontend’in scan durumunu takip etmesi.

Response örneği:

```json
{
  "scan_id": "scan_123",
  "status": "analyzing_slither",
  "current_step": "Running Slither static analysis",
  "progress": 45,
  "created_at": "2026-06-22T16:00:00Z",
  "updated_at": "2026-06-22T16:00:12Z",
  "warnings": []
}
```

Scan status değerleri:

```
queued
running
analyzing_rules
analyzing_slither
analyzing_llm
scoring
report_ready
failed
```

Slither veya LLM fail olursa scan tamamen çökmeyebilir. Bu durumda warning döner:

```json
{
  "warnings": [
    "Slither analysis could not be completed. Rule Engine results are still available."
  ]
}
```

---

## 4. Report Alma

Endpoint:

```
GET /api/scans/{scan_id}/report
```

Amaç:

Scan tamamlandıktan sonra UI’da gösterilecek rapor verisini almak.

Response örneği:

```json
{
  "scan_id": "scan_123",
  "status": "report_ready",
  "summary": {
    "overall_risk": "High",
    "total_findings": 7,
    "critical": 0,
    "high": 2,
    "medium": 3,
    "low": 1,
    "informational": 1
  },
  "contract_metadata": {
    "filename": "Vault.sol",
    "language": "Solidity",
    "pragma": "^0.8.20",
    "contracts": ["Vault"],
    "functions": ["deposit", "withdraw", "setFee"],
    "imports": []
  },
  "main_risk_areas": [
    "Withdrawal logic",
    "External calls",
    "Access control"
  ],
  "findings": []
}
```

`findings` içinde her bulgu normalize edilmiş finding modelinde döner.

---

## 5. Finding Model

Her finding şu alanlara sahip olur:

```json
{
  "id": "FIND-001",
  "title": "Unsafe use of tx.origin for authorization",
  "category": "Access Control",
  "severity": "High",
  "confidence": "High",
  "status": "Confirmed",
  "sources": ["rule_engine", "llm"],
  "location": {
    "file": "Vault.sol",
    "contract": "Vault",
    "function": "withdraw",
    "line_start": 42,
    "line_end": 42
  },
  "summary": "The withdraw function uses tx.origin for authorization.",
  "technical_details": "...",
  "exploit_scenario": "...",
  "fix_suggestion": "...",
  "evidence": [
    "require(tx.origin == owner)"
  ],
  "score": {
    "base_severity": 8,
    "confidence": 0.9,
    "exploitability": 0.8,
    "asset_impact": 0.9,
    "final_score": 8.35
  }
}
```

Bu model UI, JSON export ve Markdown report için ortak temel olacaktır.

---

## 6. JSON Export

Endpoint:

```
GET /api/scans/{scan_id}/export/json
```

Amaç:

Makine tarafından okunabilir tam raporu indirmek.

Response:

```json
{
  "scan_id": "scan_123",
  "summary": {},
  "contract_metadata": {},
  "findings": []
}
```

Bu çıktı ileride CI/CD, API entegrasyonu ve dashboard için kullanılabilir.

---

## 7. Markdown Export

Endpoint:

```
GET /api/scans/{scan_id}/export/markdown
```

Amaç:

İnsan tarafından okunabilir rapor üretmek.

Response:

```json
{
  "filename": "smart-contract-security-report.md",
  "content": "# Smart Contract Security Report\n\n## Summary\n..."
}
```

Alternatif olarak backend doğrudan `text/markdown` response da dönebilir. İlk sürümde JSON içinde `content` dönmek frontend için daha kolay olabilir.

---

## 8. Error Response Format

Tüm endpointlerde ortak hata formatı kullanılmalı.

Örnek:

```json
{
  "error": {
    "code": "INVALID_SOLIDITY_INPUT",
    "message": "Input does not look like a valid Solidity contract.",
    "details": {
      "filename": "Vault.txt"
    }
  }
}
```

Önerilen error code’lar:

```
INVALID_INPUT
INVALID_SOLIDITY_INPUT
FILE_TOO_LARGE
SCAN_NOT_FOUND
SCAN_NOT_READY
SLITHER_FAILED
LLM_FAILED
REPORT_GENERATION_FAILED
INTERNAL_ERROR
```

---

## 9. Final Karar

API Contract şu şekilde konumlandırılacak:

```
POST /api/scans
- Scan oluşturur

GET /api/scans/{scan_id}
- Scan status döner

GET /api/scans/{scan_id}/report
- UI için rapor döner

GET /api/scans/{scan_id}/export/json
- JSON rapor döner

GET /api/scans/{scan_id}/export/markdown
- Markdown rapor döner
```

Bu contract sayesinde frontend ve backend aynı veri modeli üzerinden ilerler. Backend mimarisinde endpointlerin yeri belirlenmişti; bu aşamada ise bu endpointlerin request/response yapısı netleştirilmiş oldu.