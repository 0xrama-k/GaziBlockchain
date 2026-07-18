### Fikir 2 — Otonom Abonelik & Fatura Ödeme Ajanı

Kullanıcı adına çalışan, gelen faturaları/abonelikleri izleyen, bakiyeyi yöneten ve en uygun FX zamanlamasında otomatik USDC/EURC ödemesi yapan bir kişisel finans ajanı. Kullanıcı sadece kuralları belirler ("aylık max $500, EURC kuru X'in altındaysa şimdi öde"), ajan gerisini halleder.

Neden kazanır: Çok net bir gerçek-dünya kullanım senaryosu ("path to production" kriteri buradan güçlü). Backend'de kural motoru + zamanlayıcı + ödeme tetikleyici senin alanın.

Circle araçları: Wallets, CCTP/Gateway (cross-border ve multi-currency), Nanopayments, Paymaster.

Kapsam kontrolü: Gerçek faturalarla uğraşma — mock bir "merchant" servisi kur, ajanın ona ödeme yaptığını göster. Bu, demo'yu basit ve temiz tutar.