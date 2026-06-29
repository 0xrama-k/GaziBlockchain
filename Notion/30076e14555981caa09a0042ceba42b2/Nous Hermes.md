**Nous Hermes — Genel Bakış**

Hermes, açık kaynaklı yapay zeka laboratuvarı Nous Research tarafından geliştirilen ve birbiriyle ilişkili iki ürünü kapsayan bir markadır:

1. **Hermes dil modelleri:** Meta'nın Llama modelleri ince ayarlanarak (fine-tuning) oluşturulmuş açık kaynaklı büyük dil modelleri. Az "ders veren", yönlendirilebilir ve sistem komutlarına uyum önceliğiyle tasarlanmış bir aile.

1. **Hermes Agent:** Şubat 2026'da MIT lisansıyla yayınlanan açık kaynaklı otonom yapay zeka ajanı.

**Mimari ilkesi — model-agnostik tasarım**

Ajanın çerçevesi (iskeleti) yerel makinede çalışır; ancak akıl yürütmeyi yapan dil modeli ayrı bir bileşendir ve çalışma yeri kullanıcı tarafından seçilir. İki dağıtım senaryosu mevcuttur:

- **Bulut modeli:** Model uzaktaki sunucularda (OpenAI, Anthropic Claude, Nous Portal vb.) çalışır. Her adımda API isteği gönderilir, veri kısmen dış ortama çıkar. Sistem gereksinimi düşüktür; ağır hesaplama uzak GPU'larda yapılır.

- **Yerel model:** Model, Ollama/vLLM/llama.cpp aracılığıyla kullanıcının kendi cihazında çalışır. Veri makineden çıkmaz, tam gizlilik sağlanır. Buna karşılık donanım yükü kullanıcıya geçer (70B+ parametreli modeller için güçlü GPU ve yüksek VRAM gerekir).

**Özelleştirme mantığı**

Özelleştirme, modelin ağırlıklarının yeniden eğitilmesiyle değil; ajanın deneyimden ürettiği yeniden kullanılabilir "skill" dosyaları, kalıcı hafıza ve yapılandırmanın yerel diskte birikmesiyle gerçekleşir. Bu öğrenme döngüsü model-agnostiktir.

**Ajan ile düz model arasındaki fark**

Doğrudan bir dil modeline (ör. ChatGPT API) soru göndermek tek seferlik, hafızasız bir metin üretimidir. Hermes Agent ise modeli bir motor olarak kullanıp üzerine yetenek katmanları ekler:

- Eylem yeteneği: kod çalıştırma, dosya okuma/yazma, web arama, tarayıcı kontrolü

- Oturumlar arası kalıcı hafıza ve kullanıcı modellemesi

- Çok adımlı görevleri planla → uygula → gözlemle döngüsüyle yürütme

- Çözülen görevlerden otomatik beceri üretimi ve birikme

**Sonuç**

Model "beyin", ajan ise bu beyne eller, hafıza ve görev yönetimi ekleyen sistemdir. Hermes Agent'in temel değeri, modele erişimi kolaylaştırmaktan çok, modeli kullanıcı adına eyleme geçen, hatırlayan ve karmaşık işleri bağımsız yürütebilen bir yapıya dönüştürmesidir. Aynı kategoride Claude Code ve Cursor gibi araçlar yer alır.