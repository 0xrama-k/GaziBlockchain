Bu aşamada kullanıcıların scanner’ı nasıl kullanacağını ve analiz sonucunu nasıl göreceğini tasarlıyoruz. Ürün hem geliştiricilere hem de teknik bilgisi olan founder’lara hitap edeceği için arayüz sade ama fazla basitleştirilmemiş olmalı.

## 1. Ana Kullanıcı Akışı

İlk sürümde kullanıcı contract’ı iki şekilde verebilir:

```
1. Solidity kodunu doğrudan yapıştırır
2. Tek bir .sol dosyası yükler
```

İlk sürümde olmayacak inputlar:

```
- GitHub repo linki
- Contract address
- Multi-file project upload
```

Ana akış:

```
Contract input
    ↓
Scan başlat
    ↓
Progress ekranı
    ↓
Report ekranı
    ↓
JSON / Markdown export
```

---

## 2. Ana Ekran

Ana ekranda kullanıcıya iki input seçeneği sunulur:

```
- Paste Solidity Code
- Upload .sol File
```

Ana ekranda bulunacaklar:

```
- Code editor alanı
- File upload alanı
- Scan button
- Desteklenen kapsam bilgisi
- Kısa açıklama: Solidity/EVM static security scanner
```

Kullanıcı scan başlatmadan önce sistem temel validasyon yapar:

```
- Kod boş mu?
- .sol dosyası mı?
- Maksimum boyut aşıldı mı?
- Solidity’ye benzer içerik var mı?
```

---

## 3. Scan Progress Ekranı

Scan başladıktan sonra kullanıcıya analiz adımları gösterilir. Bu, ürünün ciddi ve güvenilir görünmesini sağlar.

Progress adımları:

```
1. Input validated
2. Contract metadata extracted
3. Rule Engine analysis running
4. Slither analysis running
5. LLM review running
6. Risk scoring
7. Report ready
```

Slither veya LLM fail olursa tüm scan çökmemeli. UI’da uyarı gösterilebilir:

```
Slither analysis could not be completed. Rule Engine results are still available.
```

veya:

```
LLM explanation unavailable for some findings.
```

---

## 4. Report Overview Ekranı

Report ekranının en üstünde scan özeti olmalı.

Gösterilecek bilgiler:

```
- Overall Risk
- Total Findings
- Critical / High / Medium / Low / Informational sayıları
- Analiz edilen dosya adı
- Tespit edilen contract isimleri
- Compiler pragma bilgisi
- Main risk areas
```

Örnek:

```
Overall Risk: High
Total Findings: 7

Critical: 0
High: 2
Medium: 3
Low: 1
Informational: 1

Detected Contracts: Vault, OwnableLite
Main Risk Areas: Withdrawal logic, External calls, Access control
```

---

## 5. Findings List

Bulgular kart yapısında gösterilmelidir.

Her finding card şu bilgileri göstermeli:

```
- Title
- Severity
- Confidence
- Status
- Source badges
- Contract / Function / Line
- Kısa summary
```

Örnek finding card:

```
[High] Unsafe use of tx.origin for authorization

Status: Confirmed
Confidence: High
Sources: Rule Engine, LLM
Location: Vault.withdraw, line 42

The withdraw function uses tx.origin for authorization, which can create phishing-style authorization risks.
```

Bulgular severity’ye göre sıralanmalı:

```
Critical
High
Medium
Low
Informational
```

---

## 6. Finding Detail

Kullanıcı bir finding’e tıkladığında detay açılmalıdır.

Detayda bulunacak alanlar:

```
- Summary
- Technical Details
- Exploit Scenario
- Fix Suggestion
- Evidence
- Source
- Score breakdown
```

Kod üzerinde satır satır annotation ilk sürümde zorunlu değil. Bunun yerine sorunlu contract, function ve line bilgisi verilmesi yeterli.

Örnek:

```
Location:
Contract: Vault
Function: withdraw
Line: 42

Evidence:
require(tx.origin == owner)
```

---

## 7. Export Alanı

Report ekranında iki export seçeneği olmalı:

```
- Export JSON
- Export Markdown
```

JSON export:

```
- API/CI/CD entegrasyonları için makine tarafından okunabilir format
```

Markdown export:

```
- GitHub issue
- Audit note
- Takım içi dokümantasyon
- Rapor paylaşımı
```

PDF ilk sürümde gerekli değil, roadmap’e alınabilir.

---

## 8. UI Tasarım Prensipleri

Arayüz şu prensiplere göre tasarlanmalı:

```
- Teknik ama okunabilir
- Finding odaklı
- Gereksiz metin kalabalığı yok
- Severity renkleri net
- Source badge’leri görünür
- Kullanıcı hangi tool’un ne bulduğunu anlayabilmeli
- Founder da okuyabilmeli, developer da aksiyon alabilmeli
```

Önerilen ana sayfalar:

```
/scans/new
/scans/{scan_id}
/scans/{scan_id}/report
```

---

## 9. Final Karar

Frontend ilk sürümde şu özelliklere sahip olacak:

```
Input:
- Paste Solidity code
- Upload .sol file

Progress:
- Scan step tracking
- Fail-soft warning messages

Report:
- Overall risk summary
- Severity distribution
- Contract metadata
- Main risk areas
- Finding cards
- Finding detail view
- JSON export
- Markdown export

Not included initially:
- GitHub repo scan
- Contract address scan
- Code editor line annotation
- PDF export
- Dynamic test visualization
```