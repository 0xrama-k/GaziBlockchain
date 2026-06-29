# Smart Contract Security Scanner — Rule Engine Mimarisi Özeti

Bu projede geliştireceğimiz security scanner’ın temel parçalarından biri **Rule Engine** olacak. Rule Engine, Solidity/EVM tabanlı akıllı kontratları deterministik kurallarla analiz eden ve güvenlik riski oluşturabilecek patternleri tespit eden çekirdek analiz katmanıdır.

## 1. Rule Engine’in Amacı

Rule Engine’in görevi, kullanıcı tarafından verilen tek bir `.sol` dosyasını veya doğrudan yapıştırılan Solidity kodunu statik olarak incelemektir. Bu analiz sırasında kod çalıştırılmaz, deploy edilmez ve herhangi bir dış sistemle etkileşime girilmez.

Rule Engine şunları yapar:

- Bilinen güvenlik risklerini deterministic şekilde tespit eder.

- Her bulgu için lokasyon, risk kategorisi, severity ve confidence üretir.

- Slither ve LLM analizinden bağımsız çalışır.

- Final raporu doğrudan üretmez; bunun yerine normalize edilecek ham bulgular üretir.

- LLM’in tek başına karar vermesini engelleyen güvenilir analiz tabanını oluşturur.

Bu yapı sayesinde scanner sadece “LLM kod okudu ve yorumladı” mantığında çalışmaz. Önce deterministic analiz yapılır, daha sonra LLM bu bulguları açıklamak, bağlamlandırmak ve kullanıcıya anlaşılır hale getirmek için kullanılır.

---

## 2. Genel Akış

Rule Engine’in çalışacağı genel akış şu şekildedir:

```
Solidity Code / .sol File
        |
Preprocessing
        |
Parser / Metadata Extractor
        |
Rule Engine
        |
Raw Findings
        |
Finding Normalizer
        |
LLM Explanation Layer
        |
Final Report
```

Rule Engine, analiz pipeline’ının erken aşamasında çalışır. Kullanıcıdan alınan kod önce parse edilir, contract ve function bilgileri çıkarılır. Daha sonra her rule bu context üzerinde çalışarak potansiyel güvenlik problemlerini tespit eder.

---

## 3. AST-First, Pattern-Fallback Yaklaşımı

Rule Engine’de önerilen analiz yaklaşımı:

```
Önce AST tabanlı analiz denenir.
AST parse başarılıysa daha sağlam analiz yapılır.
AST parse başarısız olursa regex/pattern tabanlı fallback analiz devam eder.
```

Bunun sebebi, kullanıcıların her zaman tam ve derlenebilir contract göndermeyebilmesidir. Örneğin eksik importlar, yarım contractlar veya tek dosyalık izole kod parçaları olabilir. Scanner bu durumda tamamen hata vermemeli, mümkün olan kontrolleri yine de çalıştırmalıdır.

Bu yüzden iki katmanlı bir yapı kullanacağız:

1. **AST-based analysis:** Daha doğru lokasyon, function, modifier ve state değişimi tespiti.

1. **Pattern-based fallback:** Daha basit ama dayanıklı string/regex tabanlı kontroller.

---

## 4. Rule Engine Context Modeli

Her rule aynı context üzerinden çalışmalıdır. Bu context, contract hakkında analiz sırasında kullanılacak bilgileri içerir.

Örnek context yapısı:

```json
{
  "filename": "Contract.sol",
  "source_code": "...",
  "lines": [],
  "pragma": "^0.8.20",
  "contracts": [],
  "functions": [],
  "imports": [],
  "ast": {}
}
```

Function metadata örneği:

```json
{
  "contract": "Vault",
  "name": "withdraw",
  "visibility": "public",
  "modifiers": ["nonReentrant"],
  "line_start": 42,
  "line_end": 58
}
```

Bu context sayesinde rule’lar sadece metin araması yapmaz; mümkün olduğunda function ismi, visibility, modifier, satır aralığı ve contract bağlamına göre daha doğru karar verir.

---

## 5. Rule Formatı

Her rule bağımsız bir modül gibi tasarlanmalıdır. Bir rule’un temel yapısı şu şekilde olabilir:

```json
{
  "rule_id": "RE-ACCESS-001",
  "name": "tx.origin used for authorization",
  "category": "Access Control",
  "default_severity": "High",
  "default_confidence": "High",
  "description": "Detects tx.origin usage in authorization checks.",
  "tags": ["authorization", "phishing-risk", "evm"]
}
```

Backend tarafında her rule kendi detector fonksiyonuna sahip olur:

```
Rule: RE-ACCESS-001
Detector: detectTxOriginAuthorization(context)
Output: RawFinding veya null
```

Rule bir problem bulursa ham finding üretir. Problem bulamazsa hiçbir şey döndürmez.

---

## 6. Rule Engine Çıktısı

Rule Engine final kullanıcı raporunu üretmez. Onun yerine ham bulgu üretir. Bu ham bulgular daha sonra normalizer, deduplication, risk scoring ve LLM explanation katmanlarından geçer.

Raw finding örneği:

```json
{
  "source": "rule_engine",
  "rule_id": "RE-ACCESS-001",
  "title": "tx.origin used for authorization",
  "category": "Access Control",
  "base_severity": "High",
  "confidence": "High",
  "status": "Confirmed",
  "location": {
    "file": "Contract.sol",
    "contract": "Vault",
    "function": "withdraw",
    "line_start": 42,
    "line_end": 42
  },
  "evidence": "require(tx.origin == owner)",
  "tags": ["authorization", "phishing-risk", "evm"]
}
```

Bu format sayesinde Slither ve LLM’den gelen bulgularla aynı modele normalize etmek kolaylaşır.

---

## 7. Rule Kategorileri

İlk ürün çekirdeğinde Rule Engine şu ana kategorilere ayrılmalıdır:

### 7.1 Access Control Rules

Erişim kontrolü eksikliği veya hatalı authorization patternleri tespit edilir.

Örnek kontroller:

- `tx.origin` ile authorization yapılması

- Admin/owner fonksiyonlarının public veya external olup access control içermemesi

- `transferOwnership`, `setOwner`, `setAdmin` gibi fonksiyonların korumasız olması

- `mint`, `burn`, `pause`, `upgradeTo`, `withdraw`, `sweep` gibi kritik fonksiyonların modifier veya `require(msg.sender == owner)` benzeri kontrol içermemesi

Örnek risk:

```solidity
function transferOwnership(address newOwner) public {
    owner = newOwner;
}
```

Bu fonksiyon public ve korumasızsa High severity finding üretilmelidir.

---

### 7.2 Reentrancy Rules

External call ve state update sırası incelenir.

Örnek kontroller:

- External call’ın state update’ten önce yapılması

- `withdraw`, `claim`, `redeem`, `unstake` gibi fonksiyonlarda low-level call kullanılması

- External call + state mutation varken `nonReentrant` benzeri guard bulunmaması

Riskli örnek:

```solidity
(bool ok, ) = msg.sender.call{value: amount}("");
balances[msg.sender] -= amount;
```

Bu yapıda external call önce, state update sonra geldiği için reentrancy riski oluşabilir.

---

### 7.3 Dangerous EVM Feature Rules

EVM seviyesinde tehlikeli veya audit gerektiren özellikler tespit edilir.

Örnek kontroller:

- `delegatecall`

- `selfdestruct`

- inline `assembly`

- arbitrary external call patternleri

Örnek:

```solidity
(bool success, ) = target.delegatecall(data);
```

`delegatecall` tek başına her zaman açık değildir, fakat yüksek riskli bir pattern olduğu için en azından Needs Review veya High severity finding olarak işaretlenmelidir. Eğer target kullanıcıdan geliyorsa risk seviyesi daha da artırılmalıdır.

---

### 7.4 Randomness Rules

Blockchain üzerinde manipüle edilebilir değerlerin randomness amacıyla kullanılması tespit edilir.

Örnek riskli kaynaklar:

- `block.timestamp`

- `block.number`

- `blockhash`

- `prevrandao`

Bu değerlerin her kullanımı açık değildir. Rule özellikle randomness context aramalıdır.

Randomness context örnekleri:

```
random
rand
winner
lottery
seed
roll
draw
shuffle
```

Örnek:

```solidity
uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
```

Bu tarz kullanım lottery, game veya winner seçimi gibi bir bağlamda geçiyorsa Medium/High severity olarak işaretlenmelidir.

---

### 7.5 Transfer Safety Rules

ETH veya token transferlerinde güvensiz patternler tespit edilir.

Örnek kontroller:

- Unchecked low-level call

- `call{value: ...}` sonucunun kontrol edilmemesi

- ERC20 `transfer` / `transferFrom` return value kontrolünün yapılmaması

- SafeERC20 kullanılmaması

Riskli örnek:

```solidity
msg.sender.call{value: amount}("");
```

Return value kontrol edilmiyorsa High severity finding üretilebilir.

ERC20 için örnek:

```solidity
token.transfer(to, amount);
```

Bazı tokenlar standart dışı davranabildiği için SafeERC20 kullanımı önerilmelidir.

---

### 7.6 Upgradeability Rules

Upgradeable contract yapılarında kritik hatalar tespit edilir.

Örnek kontroller:

- `initialize` fonksiyonunun korumasız olması

- `initializer` modifier bulunmaması

- `upgradeTo`, `upgradeToAndCall`, `setImplementation` gibi fonksiyonların access control içermemesi

- Proxy implementation değiştirme fonksiyonlarının public/external ve korumasız olması

Riskli örnek:

```solidity
function initialize(address _owner) public {
    owner = _owner;
}
```

Bu fonksiyon birden fazla kez çağrılabiliyorsa veya access control/initializer koruması yoksa High severity finding üretilmelidir.

---

### 7.7 Code Quality / Hygiene Rules

Doğrudan exploit olmayabilecek ama production güvenliği ve audit kalitesi açısından önemli noktalar tespit edilir.

Örnek kontroller:

- Floating pragma

- Eski Solidity compiler versiyonu

- Hardcoded address

- Kritik fonksiyonlarda event emit edilmemesi

- Gereksiz veya riskli fallback/receive fonksiyonları

Örnek:

```solidity
pragma solidity ^0.8.20;
```

Bu floating pragma olarak Low severity veya Informational finding olabilir. Production deploy için exact compiler version önerilir.

---

## 8. Severity ve Confidence Mantığı

Her rule’un default severity ve confidence değeri olmalıdır. Ancak bu değerler context’e göre değişebilir.

Örnek:

```
delegatecall kullanımı → High
delegatecall target kullanıcıdan geliyorsa → Critical/High
delegatecall onlyOwner ile korunuyorsa → High ama exploitability daha düşük
```

Başka örnek:

```
hardcoded address → Low
hardcoded address oracle/admin/treasury context’indeyse → Medium
```

Yani Rule Engine sadece pattern yakalamamalı, mümkün olduğunda bağlama göre risk seviyesini ayarlamalıdır.

Severity seviyeleri:

```
Critical
High
Medium
Low
Informational
```

Confidence seviyeleri:

```
High
Medium
Low
```

---

## 9. Finding Status Mantığı

Her bulgunun status alanı olmalıdır.

Önerilen status değerleri:

```
Confirmed
Potential
Needs Review
Informational
False Positive
```

Rule Engine için örnek eşleştirme:

```
Confirmed:
- tx.origin authorization
- selfdestruct usage
- unchecked low-level call
- unprotected admin function

Potential:
- external call before state update
- missing reentrancy guard
- unsafe ERC20 transfer

Needs Review:
- delegatecall
- inline assembly
- complex access control
- proxy pattern

Informational:
- floating pragma
- missing event
```

Bu status alanı UI tarafında kullanıcıya bulgunun kesinlik seviyesini anlatmak için kullanılabilir.

---

## 10. Deduplication İhtiyacı

Aynı problem birden fazla kaynak tarafından bulunabilir. Örneğin:

```
Rule Engine: low-level call detected
Slither: unchecked low-level call
LLM: external call return value is not handled
```

Bunlar kullanıcıya üç ayrı bulgu olarak gösterilmemelidir. Finding Normalizer aşamasında tek finding altında birleştirilmelidir.

Deduplication key önerisi:

```
vulnerability_type + contract + function + approximate_line_range
```

Birleştirme sonrası finding kaynakları şu şekilde gösterilebilir:

```json
{
  "title": "Unchecked low-level call",
  "sources": ["rule_engine", "slither", "llm"],
  "confidence": "High"
}
```

Birden fazla kaynak aynı bulguyu doğruluyorsa confidence artırılabilir.

---

## 11. Rule Engine Geliştirme Sırası

Rule Engine’i tek seferde çok karmaşık hale getirmek yerine aşamalı geliştirmek daha doğru olur.

### Sprint 1 — Basit Deterministic Rules

İlk etapta kolay ve net yakalanan patternler eklenir:

```
- tx.origin
- selfdestruct
- delegatecall
- assembly
- floating pragma
- outdated pragma
- hardcoded address
```

Bu kurallar ürünün temel deterministic analiz katmanını hızlıca ayağa kaldırır.

### Sprint 2 — Function / Context-Aware Rules

İkinci aşamada function metadata ve modifier bilgisi kullanan kurallar eklenir:

```
- admin-like public functions
- unprotected ownership transfer
- unchecked low-level call
- unsafe ERC20 transfer
- missing events
```

Bu aşamada parser/metadata extractor daha önemli hale gelir.

### Sprint 3 — Flow-Sensitive Rules

Üçüncü aşamada daha gelişmiş analiz isteyen kurallar eklenir:

```
- external call before state update
- missing reentrancy guard
- initializer protection
- upgrade function protection
- randomness context detection
```

Bu kurallar daha karmaşıktır çünkü sadece pattern değil, fonksiyon içindeki işlem sırası ve bağlam da analiz edilmelidir.

---

## 12. Ürün İçindeki Rolü

Rule Engine, sistemin güvenilir ve deterministik temelini oluşturur. Slither profesyonel statik analiz çıktısı sağlar, LLM ise açıklama, exploit scenario ve fix suggestion üretir. Ancak LLM nihai karar verici olmamalıdır.

Önerilen karar modeli:

```
Rule Engine + Slither bulguları ana güvenlik kanıtıdır.
LLM bulguları açıklar, bağlamlandırır ve kullanıcıya anlaşılır hale getirir.
LLM-only bulgular Confirmed olarak gösterilmez; Needs Review veya Potential olarak işaretlenir.
```

Bu yaklaşım hallucination riskini azaltır ve scanner’ın güvenilirliğini artırır.

---

## 13. Özet Karar

Rule Engine şu şekilde tasarlanmalıdır:

```
Type:
- Modular deterministic static analyzer

Approach:
- AST-first
- Pattern fallback

Input:
- Single Solidity file or pasted Solidity code

Output:
- Raw findings only

Categories:
- Access Control
- Reentrancy
- Dangerous EVM Features
- Randomness
- Transfer Safety
- Upgradeability
- Code Quality / Hygiene

Scoring:
- Default severity + context modifiers
- Confidence based on evidence strength
- Status: Confirmed / Potential / Needs Review / Informational

Integration:
- Slither ve LLM’den bağımsız çalışır
- Sonrasında Finding Normalizer ile diğer kaynaklardan gelen bulgularla birleştirilir
```