# LLM Tabanlı Otomasyon Nedir? Basitten Karmaşığa Bir Bakış

## 1. Önce otomasyon nedir, hatırlayalım

Otomasyon, bir işin insan eli değmeden, belirli kurallara göre kendiliğinden yapılmasıdır. Klasik örnekler:

- Bir dosya belirli bir klasöre düşünce otomatik olarak başka bir yere taşınması

- Her sabah saat 9'da otomatik rapor gönderilmesi

- Bir form doldurulunca otomatik e-posta gitmesi

Bu sistemlerin hepsinde akış aynıdır:

```
Girdi gelir → Kural çalışır → İşlem yapılır → Çıktı üretilir
```

Yani sistem önceden ne yapacağını tam olarak bilir. Sürpriz yoktur.

## 2. LLM'ler bu resme ne ekliyor?

LLM (Large Language Model — yani ChatGPT, Gemini, Claude gibi büyük dil modelleri), klasik otomasyona "anlama" ve "yorumlama" yeteneği ekliyor.

Klasik otomasyonda "bu metni özetle" diye bir görev için sabit bir fonksiyon yazılır. LLM tabanlı sistemde ise model sadece özet çıkarmaz; metnin ne tür bir metin olduğunu anlar, önemli noktaları kendi seçer, eksik veya riskli gördüğü yerleri belirtebilir, çıktıyı kime göre yazacağını ayarlayabilir.

Yani artık sistemde sadece "komut çalıştıran" bir mekanizma yok; aynı zamanda **görevi anlamaya çalışan bir model**, bu modeli yöneten bir **orkestrasyon (yönetim) katmanı** ve modelin sınırlarını çizen **roller/yetkiler** var.

## 3. En basit hâli: tek bir prompt

LLM otomasyonunun en ilkel hâli şudur — bir metin (prompt) hazırlanır, modele gönderilir, cevap alınır:

```python
prompt = "Bu metni özetle: " + text
result = call_llm(prompt)
```

Bu çalışır ama çok sınırlıdır. Çünkü model hangi tonda, hangi formatta, kimin için cevap vereceğini bilmiyor. Her seferinde biraz farklı davranabilir.

## 4. "Rol" kavramı: aynı model, farklı görev tanımları

Burada işin en kritik noktasına geliyoruz, o yüzden bir benzetmeyle anlatalım.

Bir restoranı düşünün. "Aşçı", "garson" ve "müdür" birer **görev tanımıdır** (rol). Bu görev tanımları, o kişinin ne yapacağını, hangi kurallara uyacağını, hangi araçları kullanacağını belirler. Ama bu görevi _kim_ yapıyor — yani hangi insan — ayrı bir konudur. Aynı kişi bugün aşçı, yarın başka bir restoranda müdür olabilir. Rol sabit kalır, kişi değişebilir; ya da kişi sabit kalır, rolü değişebilir.

LLM dünyasında da aynı mantık var:

- **Rol / profil**: Modelin nasıl davranacağını, neye odaklanacağını, çıktıyı hangi formatta vereceğini tanımlayan bir talimat seti (sistem promptu).

- **Model / motor**: Bu talimatları okuyup gerçek cevabı üreten yapay zekâ (Gemini, GPT, Claude, yerel bir model vs.).

Örnek bir rol tanımı, "analyst" (analiz) rolü için şöyle olabilir:

```
Sen analiz yapan bir AI profilisin.

Görevin:
- Verilen problemi anlamak
- Önemli noktaları ayırmak
- Riskleri ve fırsatları belirlemek
- Sonucu karar verilebilir bir formatta sunmak

Kurallar:
- Bilmediğin şeyi kesinmiş gibi yazma
- Varsayımlarını açıkça belirt
- Cevabı yapılandırılmış ver

Çıktı formatı:
1. Özet
2. Bulgular
3. Riskler
4. Önerilen sonraki adım
```

Bu metin bir dosyada saklanır (örneğin `analyst.md`) ve görev geldiğinde otomatik olarak modele eklenir.

## 5. Aynı motoru farklı rollerle, aynı rolü farklı motorlarla kullanabilirsiniz

Bu ayrımın gücü tam olarak burada ortaya çıkıyor:

```
Gemini + "analiz" rolü   → analiz yapan bir profil
Gemini + "yazar" rolü    → metin üreten bir profil
Gemini + "kontrolcü" rolü → hata/eksik arayan bir profil
```

Burada **aynı model**, farklı talimatlarla farklı görevler üstleniyor.

Ya da tam tersi:

```
"Analiz" rolü + Gemini
"Analiz" rolü + GPT
"Analiz" rolü + Claude
```

Burada **aynı görev tanımı**, farklı modellerle çalıştırılıyor.

Bu sayede bir rolün davranışını bozmadan arkasındaki modeli değiştirebilirsiniz, ya da aynı modeli birçok farklı iş için yeniden kullanabilirsiniz. İyi tasarlanmış sistemlerde "rol" ve "model" birbirinden tamamen bağımsız tutulur.

## 6. Bunlar pratikte nasıl birleşiyor?

Bir görev geldiğinde sistem şu üç parçayı birleştirip modele tek bir paket olarak gönderir:

1. **Rol talimatı** (sistem promptu — "sen kimsin, nasıl davranacaksın")

1. **Bağlam** (görevle ilgili ek bilgi, varsa dosya/önceki konuşma)

1. **Görev** (kullanıcının asıl isteği)

Ortaya çıkan birleşik metin yaklaşık şöyle görünür:

```
SYSTEM:
Sen analiz yapan bir AI profilisin. Riskleri, varsayımları
ve önerileri net şekilde ayırmaktır görevin.

CONTEXT:
Bu proje bir web uygulaması. Kullanıcı yönetimi, ödeme
sistemi ve admin paneli içeriyor.

TASK:
Bu projenin production'a çıkmadan önceki teknik risklerini analiz et.

OUTPUT FORMAT:
1. Özet
2. Kritik riskler
3. Eksik bilgiler
4. Önerilen sonraki adım
```

Bu paket, seçilen modele gönderilir ve cevap geri gelir. Modelin API üzerinden mi yoksa bir terminal komutu (CLI) üzerinden mi çağrıldığı, kullanıcı için pratikte fark etmez — bu sadece "motora nasıl ulaşıyoruz" sorusunun teknik cevabıdır.

## 7. Orkestrasyon katmanı: işin trafik polisi

Sistemde rolü ve modeli birleştiren, sonucu işleyen, gerektiğinde başka bir role yönlendiren bir yönetim katmanı vardır. Buna **orkestrasyon katmanı** (veya orkestratör) denir.

Restoran benzetmesine dönersek: orkestratör, restoranın müdürüdür. Siparişi (görevi) alır, hangi aşçının (modelin) hangi tarife (role) göre çalışacağını belirler, gerekirse garsona (başka bir role) devreder, sonunda müşteriye (kullanıcıya) servis eder.

Orkestratörün yaptığı işler özetle:

1. Görevi al

1. Uygun rolü seç

1. Rol talimatını hazırla

1. Bağlamı ekle

1. Doğru modeli çağır

1. Cevabı al

1. Gerekirse başka bir role gönder

1. Sonucu kullanıcıya sun

Bu katman basit bir Python betiği olabilir, bir backend servisi olabilir, ya da Hermes gibi roller/modeller/araçları görsel bir panelden yönetmeye izin veren daha hazır sistemlerden biri olabilir. Aralarındaki fark, ne kadar kendi yazdığınız mı yoksa hazır bir yapı mı kullandığınızdır — temel mantık aynıdır.

**Önemli nokta:** orkestratör cevabı _üretmez_. Cevabı her zaman model üretir. Orkestratör sadece "hangi rol, hangi model, hangi bağlamla, hangi sınırlar içinde" sorularının cevabını organize eder.

## 8. İş büyüyünce: çok rollü sistemler

Tek bir görev için tek bir rol yeterlidir. Ama bir proje büyüdükçe — örneğin bir yazılım projesinde analiz, tasarım, kod yazımı, test, dokümantasyon gibi birçok farklı iş aynı anda gerekiyorsa — bunların hepsini tek bir "genel amaçlı asistana" yıkmak yerine, her iş için ayrı bir rol tanımlamak daha kontrollü olur:

```
analyst  → analiz ve karar desteği
writer   → metin üretimi
reviewer → kontrol ve eleştiri
coder    → kod üretimi
qa       → test ve kalite kontrol
```

Bunlar "özel isimler" değil, sadece görev tanımlarıdır. Hangi modelin hangi rolü üstleneceği ayrı bir karardır ve değiştirilebilir.

Bu noktada bir de **görev devretme (delegation)** kavramı devreye girer: bir rol işini bitirince, sonucu doğrudan başka bir role aktarabilir (örneğin "tasarımcı" rolü işini bitirince "yazar" rolüne metin yazdırması için devreder). Sistemler büyüdükçe bu devretme zincirlerinin nereye kadar gidebileceği de sınırlandırılır — yoksa kontrolü kaybetmek kolaylaşır.

## 9. Genel akışın özeti

Tüm bu yapının özeti şu şekildedir:

```
Kullanıcı görevi
   ↓
Orkestrasyon katmanı görevi yorumlar
   ↓
Uygun rol seçilir
   ↓
Rol talimatı + bağlam + görev birleştirilir
   ↓
Seçilen model (LLM) çalıştırılır
   ↓
Cevap alınır
   ↓
Gerekirse başka bir role gönderilir
   ↓
Son çıktı kullanıcıya sunulur
```

## 10. Sonuç: Üç şeyi birbirinden ayırın

Bu konuyu anlamanın en kolay yolu, üç farklı kavramı kafanızda ayrı tutmaktır:

- **Rol**, davranışı tanımlar — "ne yapacaksın, nasıl yapacaksın, hangi formatta cevap vereceksin?"

- **Model**, cevabı üretir — "gerçek zekâ burada."

- **Orkestratör**, süreci yönetir — "hangi rol, hangi modelle, ne zaman, hangi bağlamla çalışacak?"

Bu üçü birbirine karıştığında sistem hem anlaşılması hem de kontrol edilmesi zor bir kara kutuya dönüşür. Ayrı tutulduğunda ise oldukça esnek bir yapı ortaya çıkar: aynı modeli farklı işlerde kullanabilir, bir işin arkasındaki modeli değiştirebilir, yeni roller ekleyebilir ya da var olanları kolayca düzenleyebilirsiniz.

Kısacası, yapay zekâyı "tek bir sohbet botu" gibi kullanmaktan çıkıp, her biri kendi görevine odaklanmış, birbirine devredebilen, kontrollü bir "uzmanlar ekibi" gibi kullanmanın temel mantığı budur.

---

### Mini Sözlük

- **LLM (Large Language Model):** Metin üreten büyük yapay zekâ modeli (GPT, Gemini, Claude vb.)

- **Prompt:** Modele verilen yazılı talimat/girdi

- **Sistem promptu:** Modelin genel davranışını belirleyen, görevden önce verilen talimat

- **API:** Bir yazılımın başka bir yazılımla (burada: modelle) konuşma yöntemi

- **CLI:** Terminal üzerinden komutla çalıştırılan araç

- **Orkestrasyon:** Birden fazla parçayı (rol, model, araç) koordine eden yönetim katmanı