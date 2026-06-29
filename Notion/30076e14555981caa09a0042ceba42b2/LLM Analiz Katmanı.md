Bu aşamada scanner’ın LLM katmanını tasarlıyoruz. LLM, sistemde tek başına güvenlik kararı veren ana analiz motoru olmayacak. Ana güvenlik kanıtı Rule Engine ve Slither gibi deterministic/statik analiz kaynaklarından gelecek. LLM ise bu bulguları açıklamak, bağlamlandırmak, risk senaryosu üretmek ve fix önerisi vermek için kullanılacak.

## 1. LLM Katmanının Amacı

LLM’in temel görevleri:

- Contract’ın genel amacını özetlemek

- Rule Engine ve Slither bulgularını açıklamak

- Her finding için developer-friendly summary üretmek

- Exploit/abuse scenario yazmak

- Fix suggestion vermek

- False-positive ihtimalini yorumlamak

- Teknik ama okunabilir rapor dili oluşturmak

LLM şunları yapmamalı:

- Tek başına nihai güvenlik kararı vermemeli

- Kanıtsız Critical/High finding üretmemeli

- Contract’ı baştan yazmamalı

- Emin olmadığı bulguları kesinmiş gibi göstermemeli

---

## 2. LLM Kullanım Noktaları

LLM iki aşamada kullanılacak.

### A) Contract-Level Review

Bu aşamada LLM’e contract metadata ve kaynak kodun ilgili bölümleri verilir.

Amaç:

- Contract ne yapıyor?

- Hangi fonksiyonlar kritik?

- Para/token transferi var mı?

- Admin/owner/proxy mantığı var mı?

- Ana risk yüzeyleri neler?

Örnek çıktı:

```json
{
  "contract_summary": "This contract appears to be a vault that allows users to deposit and withdraw ETH.",
  "main_risk_areas": [
    "withdrawal logic",
    "external calls",
    "owner-controlled configuration"
  ]
}
```

Bu çıktı doğrudan vulnerability olarak kullanılmaz. Sadece raporun genel özetini ve finding yorumlarını destekler.

---

### B) Finding-Level Explanation

Rule Engine ve Slither’dan gelen her normalize finding için LLM’den açıklama üretilir.

Her finding için LLM şu alanları doldurur:

```
- summary
- technical_details
- exploit_scenario
- fix_suggestion
- false_positive_note
```

Örnek:

```json
{
  "summary": "The withdraw function performs an external ETH transfer before updating user balance.",
  "technical_details": "External calls can transfer control to another contract. If state is updated after the call, an attacker may re-enter the function before their balance is reduced.",
  "exploit_scenario": "An attacker could deploy a malicious receiver contract and repeatedly call withdraw before the balance update happens.",
  "fix_suggestion": "Update internal balances before making the external call and consider using a reentrancy guard.",
  "false_positive_note": "If the external call target is fully trusted or protected by another mechanism, the practical risk may be lower."
}
```

---

## 3. LLM-Only Bulgular

LLM bazen Rule Engine veya Slither’ın yakalamadığı bir risk gözlemleyebilir. Ancak bu bulgular doğrudan confirmed olarak gösterilmemeli.

LLM-only finding policy:

```
LLM-only finding → Needs Review veya Potential
LLM-only Critical → izin verilmez
LLM-only High → ancak güçlü evidence varsa Potential High olabilir
Confirmed finding → Rule Engine veya Slither kanıtı gerektirir
```

Bu yaklaşım hallucination riskini azaltır.

---

## 4. Prompt Güvenliği

LLM’e verilecek prompt net kurallara sahip olmalı:

```
- Only analyze the provided Solidity code.
- Do not invent missing files or dependencies.
- Do not assume hidden business logic.
- Do not mark an issue as confirmed without evidence.
- Do not rewrite the full contract.
- Provide fix suggestions, not full patched code.
- Return structured JSON only.
```

Bu sayede LLM çıktısı backend tarafından parse edilebilir ve rapora kontrollü şekilde eklenir.

---

## 5. Final Karar

LLM Analysis Layer şu şekilde konumlandırılacak:

```
Role:
- Explanation and contextual reasoning layer

Input:
- Solidity code
- Contract metadata
- Rule Engine findings
- Slither findings

Output:
- Contract summary
- Main risk areas
- Finding explanations
- Exploit scenarios
- Fix suggestions
- False-positive notes

Decision Model:
- Rule Engine + Slither = primary evidence
- LLM = assistant/judge/explanation layer
- LLM-only findings = Needs Review / Potential
```

Bu yapı scanner’ın hem güvenilir hem de kullanıcı açısından anlaşılır rapor üretmesini sağlar.