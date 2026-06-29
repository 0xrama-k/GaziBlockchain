# Smart Contract Security Scanner — Kısa Proje Özeti

Smart Contract Security Scanner, Solidity/EVM tabanlı akıllı kontratları güvenlik açısından analiz eden bir web tabanlı güvenlik tarayıcısıdır. Proje başlangıçta Monad ekosistemi için geliştirilecek, ilerleyen süreçte Arc ve diğer EVM uyumlu ekosistemlere genişletilebilecektir.

Kullanıcı ilk sürümde tek bir `.sol` dosyası yükleyerek veya Solidity kodunu doğrudan yapıştırarak scan başlatabilecektir. Sistem, kontratı statik analizden geçirerek potansiyel güvenlik açıklarını tespit edecek ve kullanıcıya anlaşılır, aksiyon alınabilir bir rapor sunacaktır.

Analiz motoru üç ana parçadan oluşacaktır:

- Custom Rule Engine

- Slither entegrasyonu

- LLM destekli analiz ve açıklama katmanı

Rule Engine, bilinen riskli patternleri deterministic şekilde tespit eder. Slither, profesyonel statik analiz çıktısı sağlar. LLM ise bulguları açıklamak, exploit senaryosu üretmek ve fix önerileri vermek için kullanılır. LLM tek başına nihai güvenlik kararı vermez; ana güvenlik kanıtı Rule Engine ve Slither’dan gelir.

İlk sürümde analiz kapsamı statik analiz ile sınırlı olacaktır. GitHub repo scan, contract address scan, multi-file project analysis, dynamic testing ve fuzzing gibi özellikler roadmap’e bırakılmıştır.

Backend Rust ile geliştirilecek ve Axum + SQLx + PostgreSQL kullanılacaktır. Mimari katmanlı ama gereksiz karmaşık olmayacak şekilde tasarlanacaktır. Analiz süreci scan job lifecycle üzerinden yürütülecek, Slither Docker sandbox içinde güvenli şekilde çalıştırılacaktır.

Kullanıcıya sunulacak raporda:

- Overall risk seviyesi

- Finding listesi

- Severity ve confidence bilgisi

- Contract/function/line lokasyonu

- Teknik açıklama

- Exploit senaryosu

- Fix önerisi

- JSON ve Markdown export

bulunacaktır.

Projenin amacı, geliştiricilerin ve teknik bilgiye sahip founder’ların smart contract güvenlik problemlerini erken aşamada tespit edebilmesini sağlayan, gerçek ürüne dönüşebilir bir güvenlik analiz platformu oluşturmaktır.