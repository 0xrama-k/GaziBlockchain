Backend Rust ile yazılacak ve katmanlı mimari kullanılacak. Ama katman sayısı gereksiz artırılmayacak. Amaç; okunabilir, test edilebilir, ileride GitHub scan / contract address scan / dynamic testing gibi özelliklere genişleyebilir bir yapı kurmak.

## 1. Önerilen Backend Stack

Başlangıç için önerilen stack:

```
Rust
Axum veya Actix Web
Tokio async runtime
SQLx
PostgreSQL
Docker sandbox runner
LLM provider adapter
Slither CLI adapter
```

Benim önerim: **Axum + SQLx + PostgreSQL**.

Sebep:

- Axum modern ve sade.

- Tokio ile async işler doğal ilerler.

- SQLx compile-time query kontrolü sağlar.

- PostgreSQL scan/job/report saklamak için yeterli.

---

## 2. Katmanlı Mimari

Optimal katman sayısı şu olsun:

```
API Layer
Service Layer
Repository Layer
Analyzer Layer
Infrastructure Layer
```

Çok fazla parçalamıyoruz ama sorumlulukları net ayırıyoruz.

---

## 3. API Layer

HTTP endpointlerin bulunduğu katmandır.

Görevi:

- Request almak

- Input validation başlatmak

- Service katmanını çağırmak

- Response dönmek

Örnek endpointler:

```
POST /api/scans
GET  /api/scans/{scan_id}
GET  /api/scans/{scan_id}/report
GET  /api/scans/{scan_id}/export/json
GET  /api/scans/{scan_id}/export/markdown
```

İlk sürüm için `POST /api/scans` yeterince kritik endpointtir.

Input tipleri:

```
- pasted Solidity code
- uploaded .sol file
```

---

## 4. Service Layer

İş akışının yönetildiği ana katmandır.

Görevleri:

- Scan oluşturmak

- Scan durumunu güncellemek

- Analyzer pipeline’ını çalıştırmak

- Hata durumlarını yönetmek

- Report üretimini tetiklemek

Örnek servisler:

```
ScanService
ReportService
ExportService
```

Bu katman backend’in ana orchestration yeridir.

---

## 5. Repository Layer

Database işlemlerinin bulunduğu katmandır.

Görevleri:

- Scan kaydı oluşturmak

- Scan status güncellemek

- Finding kayıtlarını saklamak

- Report verisini çekmek

Örnek repository’ler:

```
ScanRepository
FindingRepository
ReportRepository
```

Başlangıçta çok bölmek istemezsek tek `ScanRepository` altında da tutulabilir. Ama finding’ler büyüyeceği için `FindingRepository` ayrı mantıklı olur.

---

## 6. Analyzer Layer

Analiz motorlarının bulunduğu katmandır.

Bu katman scanner’ın çekirdeğidir.

Alt parçalar:

```
InputProcessor
SolidityPreprocessor
RuleEngine
SlitherAdapter
LlmAnalyzer
FindingNormalizer
RiskScorer
ReportGenerator
```

Bu parçalar service layer tarafından sırayla çağrılır.

Pipeline:

```
Input
  ↓
Validation / Preprocessing
  ↓
Rule Engine
  ↓
Slither Adapter
  ↓
LLM Review
  ↓
Finding Normalizer
  ↓
Risk Scoring
  ↓
Report Generation
```

---

## 7. Infrastructure Layer

Dış sistemlerle konuşan katmandır.

Görevleri:

```
- Slither’ı Docker sandbox içinde çalıştırmak
- LLM API çağrısı yapmak
- Geçici dosya sistemi yönetmek
- Timeout / resource limit uygulamak
- Config/env okumak
```

Örnek modüller:

```
DockerRunner
SlitherRunner
LlmClient
TempFileManager
Config
```

Bu katman sayesinde analyzer logic direkt Docker veya LLM API detaylarına bağımlı olmaz.

---

## 8. Scan Job Lifecycle

Her scan bir job gibi ele alınmalı.

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

İlk sürümde queue sistemi şart değil. Basit başlamak için scan request geldiğinde backend job oluşturur ve async task olarak çalıştırır.

Başlangıç modeli:

```
POST /api/scans
  ↓
scan kaydı oluşturulur
  ↓
status = queued
  ↓
background tokio task başlatılır
  ↓
status adım adım güncellenir
  ↓
rapor hazır olunca status = report_ready
```

İleride büyüyünce şu yapıya geçilebilir:

```
API Service
  ↓
Queue
  ↓
Worker Service
  ↓
Analyzer Sandbox
```

Ama ilk gerçek ürün çekirdeği için tek backend + async worker yeterli.

---

## 9. Database Model

Başlangıç için üç ana tablo yeterli:

```
scans
findings
reports
```

### scans

```
id
status
input_type
filename
source_hash
overall_risk
created_at
updated_at
error_message
```

### findings

```
id
scan_id
title
category
severity
confidence
status
sources
contract_name
function_name
line_start
line_end
summary
technical_details
exploit_scenario
fix_suggestion
evidence
score
created_at
```

### reports

```
id
scan_id
json_report
markdown_report
created_at
```

İlk sürümde report JSON olarak saklanabilir. Daha sonra finding tablosundan yeniden üretilebilir.

---

## 10. Error Handling

Scan herhangi bir aşamada tamamen çökmemeli. Özellikle Slither veya LLM hatasında fail-soft yaklaşım kullanılmalı.

Önerilen davranış:

```
Rule Engine fail olursa → scan failed
Slither fail olursa → warning ekle, devam et
LLM fail olursa → finding açıklamaları eksik kalabilir, scan devam eder
Report generation fail olursa → scan failed
```

Slither hatası örneği:

```
Slither analysis could not be completed. Rule Engine and LLM analysis were still performed.
```

LLM hatası örneği:

```
LLM explanation unavailable for this finding.
```

---

## 11. Önerilen Rust Klasör Yapısı

```
src/
  main.rs
  app.rs

  api/
    mod.rs
    scan_routes.rs
    report_routes.rs

  services/
    mod.rs
    scan_service.rs
    report_service.rs

  repositories/
    mod.rs
    scan_repository.rs
    finding_repository.rs

  analyzers/
    mod.rs
    input_processor.rs
    solidity_preprocessor.rs
    rule_engine/
      mod.rs
      rules/
        access_control.rs
        reentrancy.rs
        evm.rs
        randomness.rs
        transfer.rs
        upgradeability.rs
        quality.rs
    slither_adapter.rs
    llm_analyzer.rs
    finding_normalizer.rs
    risk_scorer.rs
    report_generator.rs

  infra/
    mod.rs
    config.rs
    docker_runner.rs
    slither_runner.rs
    llm_client.rs
    temp_files.rs

  models/
    mod.rs
    scan.rs
    finding.rs
    report.rs
    dto.rs

  error/
    mod.rs
```

Bu yapı yeterince temiz ama gereksiz karmaşık değil.

---

## 12. Final Karar

Backend mimarisi şu şekilde olacak:

```
Language:
- Rust

Framework:
- Axum

Database:
- PostgreSQL + SQLx

Architecture:
- API Layer
- Service Layer
- Repository Layer
- Analyzer Layer
- Infrastructure Layer

Execution:
- İlk sürümde tek backend servis
- Scan işlemleri async background task
- İleride queue + worker mimarisine geçilebilir

Analyzer:
- Rule Engine
- Slither Adapter
- LLM Analyzer
- Finding Normalizer
- Risk Scorer
- Report Generator

Output:
- UI için scan report
- JSON export
- Markdown export
```