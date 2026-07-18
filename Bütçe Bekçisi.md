### 5 — AI Ajanları için "Bütçe Bekçisi" (guardrail katmanı)

Gerçek problem: Otonom ajanlara cüzdan verildiğinde en büyük korku kontrolsüz harcama — bir bug veya kötü prompt ajanı tüm bakiyeyi boşaltabilir. Bu, agentic ödemelerin benimsenmesindeki bir numaralı engel.

Çözüm: Ajan ile cüzdan arasına giren bir politika/guardrail motoru. Harcama limitleri, hız sınırları, izin verilen alıcı beyaz listeleri, "şüpheli işlemde insan onayı" kuralları koyarsın. Her ajan ödemesi önce bu katmandan geçer, Paymaster ile gas soyutlanır.

Neden çok akıllıca bir seçim: Bu bir _altyapı_ fikri — diğer tüm agentic projelerin ihtiyaç duyduğu şey. Jüri bunun ekosistem değeri olduğunu hemen görür. Tamamen backend/policy-engine işi, senin uzmanlığına mükemmel oturur ve kapsamı küçük tutulabilir (birkaç kural türü + bir demo ajanı yeterli).