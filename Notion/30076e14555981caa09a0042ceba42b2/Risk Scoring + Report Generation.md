Bu aşamada amaç, Rule Engine, Slither ve LLM katmanlarından gelen bulguları anlaşılır bir risk skoruna dönüştürmek ve kullanıcıya profesyonel bir rapor sunmaktır.

## 1. Risk Scoring’in Amacı

Her finding için sadece “High” veya “Medium” demek yeterli değildir. Risk seviyesi şu faktörlere göre hesaplanmalıdır:

```
Final Risk = Base Severity + Confidence + Exploitability + Asset Impact
```

Bu sayede aynı tipteki bulgular bağlama göre farklı seviyede değerlendirilebilir.

Örnek:

```
delegatecall var → High
delegatecall target kullanıcıdan geliyorsa → Critical/High
delegatecall onlyOwner arkasındaysa → High ama exploitability daha düşük
```

---

## 2. Skor Bileşenleri

Her finding için 4 temel değer hesaplanır.

### Base Severity

Bulgunun temel güvenlik etkisidir.

```
Critical = 10
High = 8
Medium = 5
Low = 3
Informational = 1
```

Örnek:

```
Reentrancy → High
tx.origin authorization → High
Floating pragma → Low
Missing event → Informational
```

### Confidence

Bulgudan ne kadar eminiz?

```
High = 0.9
Medium = 0.6
Low = 0.3
```

Kaynağa göre confidence artabilir:

```
Rule Engine + Slither → High
Rule Engine only → Medium/High
Slither only → Medium/High
LLM only → Low/Medium, Needs Review
```

### Exploitability

Açığın pratikte istismar edilme ihtimalidir.

```
High = 0.9
Medium = 0.6
Low = 0.3
```

Örnek:

```
Public withdraw + external call → High
OnlyOwner dangerous function → Medium
Internal-only risky function → Low
```

### Asset Impact

Açık gerçekleşirse ne zarar verir?

```
High = 0.9
Medium = 0.6
Low = 0.3
None = 0.1
```

Örnek:

```
ETH/token transferi → High
Ownership/admin kontrolü → High
Metadata/config değişimi → Medium
Missing event → Low
```

---

## 3. Final Score Formülü

Önerilen formül:

```
final_score =
(base_severity * 0.45)
+ (confidence * 10 * 0.20)
+ (exploitability * 10 * 0.20)
+ (asset_impact * 10 * 0.15)
```

Score mapping:

```
9.0 - 10.0 → Critical
7.0 - 8.9  → High
4.0 - 6.9  → Medium
2.0 - 3.9  → Low
0.0 - 1.9  → Informational
```

Örnek:

```
tx.origin authorization:
base_severity = 8
confidence = 0.9
exploitability = 0.8
asset_impact = 0.9

final_score = 8.35
severity = High
```

---

## 4. Scan-Level Overall Risk

Sadece finding bazlı skor değil, tüm contract için genel risk seviyesi de hesaplanmalıdır.

Önerilen mantık:

```
Critical finding varsa → Overall Risk: Critical
2 veya daha fazla High varsa → Overall Risk: High
1 High varsa → Overall Risk: High
3 veya daha fazla Medium varsa → Overall Risk: Medium
Sadece Low/Info varsa → Overall Risk: Low
Hiç ciddi bulgu yoksa → No major issues found
```

Scan summary örneği:

```
Overall Risk: High
Total Findings: 7

Critical: 0
High: 2
Medium: 3
Low: 1
Informational: 1
```

---

## 5. Report İçeriği

Her raporda şu ana bölümler olmalı:

```
1. Scan Summary
2. Contract Metadata
3. Overall Risk
4. Main Risk Areas
5. Findings List
6. Per-Finding Details
7. Export Data
```

### Scan Summary

```
Contract: Vault.sol
Detected Contracts: Vault, OwnableLite
Total Findings: 7
Overall Risk: High
```

### Contract Metadata

```
Language: Solidity
Compiler Version: ^0.8.20
Detected Imports: OpenZeppelin Ownable
Detected Functions: deposit, withdraw, setFee
```

### Main Risk Areas

LLM contract-level review’dan gelebilir:

```
- Withdrawal logic
- Owner-controlled configuration
- External calls
```

### Finding Detail

Her finding şu formatta gösterilir:

```
Title: Unsafe use of tx.origin for authorization
Severity: High
Confidence: High
Status: Confirmed
Sources: Rule Engine, Slither
Location: Vault.withdraw, line 42
Summary: ...
Technical Details: ...
Exploit Scenario: ...
Fix Suggestion: ...
Evidence: require(tx.origin == owner)
```

---

## 6. UI Report

UI tarafında rapor kart bazlı gösterilebilir.

Önerilen UI bölümleri:

```
- Overall risk badge
- Finding count summary
- Severity distribution
- Contract summary
- Main risk areas
- Finding cards
- Source badges: Rule Engine / Slither / LLM
- Export JSON
- Export Markdown
```

Finding card örneği:

```
[High] Unsafe use of tx.origin
Status: Confirmed
Source: Rule Engine + LLM
Location: Vault.withdraw, line 42

The function uses tx.origin for authorization...
```

Kod üzerinde satır satır annotation ilk sürümde zorunlu değil. Bunun yerine finding içinde contract, function ve line bilgisi verilmesi yeterli.

---

## 7. JSON Export

JSON export makine tarafından okunabilir olmalı. İleride API, CI/CD entegrasyonu ve dashboard için kullanılabilir.

Örnek yapı:

```json
{
  "scan_id": "scan_123",
  "status": "completed",
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
    "functions": ["deposit", "withdraw", "setFee"]
  },
  "findings": []
}
```

---

## 8. Markdown Export

Markdown export insan tarafından okunabilir rapor olacak. Kullanıcı bunu GitHub issue, audit note veya ekip içi dokümana koyabilir.

Örnek yapı:

```markdown
# Smart Contract Security Report

## Summary

Overall Risk: High
Total Findings: 7

| Severity | Count |
|---|---:|
| Critical | 0 |
| High | 2 |
| Medium | 3 |
| Low | 1 |
| Informational | 1 |

## Findings

### FIND-001 — Unsafe use of tx.origin

Severity: High
Confidence: High
Status: Confirmed
Location: Vault.withdraw, line 42
Sources: Rule Engine, LLM

#### Summary
...

#### Exploit Scenario
...

#### Fix Suggestion
...
```

---

## 9. Final Karar

Risk Scoring + Report Generation katmanı şu şekilde tasarlanacak:

```
Input:
- Normalized findings
- Contract metadata
- LLM explanations

Processing:
- Her finding için final_score hesapla
- Severity seviyesini belirle
- Overall contract risk üret
- Findings’i severity’ye göre sırala
- UI, JSON ve Markdown raporlarını oluştur

Output:
- Web UI report
- JSON export
- Markdown export
```

Bu yapı scanner’ın çıktısını profesyonel, okunabilir ve geliştirici açısından aksiyon alınabilir hale getirir.