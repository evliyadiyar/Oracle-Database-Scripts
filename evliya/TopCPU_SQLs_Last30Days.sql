--------------------------------------------------------------------------------
--  TopCPU_SQLs_Last30Days.sql
--  Oracle: Son 30 Günde En Çok CPU Harcayan SQL'lerin Detaylı Analizi
--  Yazar: Evliya Diyar | https://github.com/evliyadiyar/
--
--  Açıklama:
--      Bu sorgu, son 30 gün içinde Oracle veritabanında en fazla CPU kullanan
--      ilk 30 SQL'i detaylıca analiz eder. Sorgularda plan değişimi, bekleme süresi,
--      mantıksal I/O, çalıştırma sayısı, uygulama modülü, kısa SQL text gibi
--      performans tuning için kritik tüm metrikleri gösterir.
--
--  Kullanım:
--      SQL*Plus veya başka bir SQL aracı ile çalıştırabilirsiniz.
--      Çıktıdaki metrikler ile hangi sorguların optimizasyon gerektirdiğini
--      hızlıca tespit edebilirsiniz.
--------------------------------------------------------------------------------

WITH totcpu AS (
  SELECT SUM(cpu_time) sumcpu
  FROM   v$sqlstats
  WHERE  last_active_time > SYSDATE-30
)
SELECT *
FROM (
  SELECT
     s.sql_id                           AS sql_id,            -- SQL kimliği
     s.plan_hash_value                  AS plan_hash,         -- Plan hash (plan değişimi için)
     TO_CHAR(s.last_active_time,'MMDD HH24:MI') AS last_active_time, -- En son aktif olduğu zaman
     ROUND(s.cpu_time/1e6,2)            AS total_cpu_s,       -- Toplam CPU süresi (saniye)
     ROUND(100*(s.cpu_time/tc.sumcpu),2) AS cpu_pct,          -- Toplam CPU içindeki % pay
     ROUND(s.elapsed_time/1e6,2)        AS total_elapsed_s,   -- Toplam geçen süre (saniye)
     LEAST(s.executions/1000,99999999)  AS executions_k,      -- Çalıştırma sayısı (binlik)
     RANK() OVER (PARTITION BY 1 ORDER BY s.executions DESC) AS exec_rank, -- Çalıştırma sayısına göre sıralama
     ROUND(LEAST(s.cpu_time/s.executions,99999999)/1e6,2) AS cpu_per_exec_s, -- Çalıştırma başına CPU (saniye)
     ROUND(LEAST(s.buffer_gets/s.executions,999999)/1,2)  AS buffer_gets_per_exec, -- Çalıştırma başına mantıksal I/O
     q.module                          AS module,             -- Hangi uygulama modülü
     SUBSTR(REPLACE(s.sql_text,CHR(13)),1,50) AS sql_text     -- SQL text (ilk 50 karakter)
  FROM
     (SELECT *
      FROM v$sqlstats
      WHERE last_active_time > SYSDATE-30
      ORDER BY cpu_time DESC) s,
     (SELECT DISTINCT sql_id, plan_hash_value, module
      FROM v$sql
      WHERE parsing_schema_name NOT IN ('SYS','SYSTEM')) q,
     totcpu tc
  WHERE s.sql_id = q.sql_id
    AND s.plan_hash_value = q.plan_hash_value
    AND s.executions > 0
  ORDER BY s.cpu_time DESC
)
WHERE rownum < 31;

--------------------------------------------------------------------------------
-- Açıklamalar ve Yorumlama Notları
--
--  sql_id:
--      • Sorgunun benzersiz kimliği.
--      • Aynı sql_id için plan değişimi olabilir; plan_hash ile birlikte düşün.
--
--  plan_hash:
--      • Execution plan’ın hash’i; plan stabilitesi için izlenir.
--      • Sık değişiyorsa istatistikler, hints veya SQL Profile/Plan Baseline bakılmalı.
--
--  last_active_time:
--      • Sorgunun son aktif olduğu zaman (MMDD HH24:MI).
--      • Şu ana yakınsa canlı yük, çok eskiyse güncel sorunla ilgisiz olabilir.
--
--  total_cpu_s (saniye):
--      • Son 30 günde bu SQL’in topladığı toplam CPU süresi.
--      • > 60–120 s: Dikkat.  > 300 s: Kritik CPU tüketicisi.
--
--  cpu_pct (%):
--      • Son 30 gündeki toplam SQL CPU içinde bu SQL’in yüzdesi.
--      • ≥ %20: Çok baskın.  ≥ %35–40: Kritik (tek SQL sistemi taşıyor).
--
--  total_elapsed_s (saniye):
--      • Toplam geçen süre (CPU + bekleme).
--      • total_elapsed_s >> total_cpu_s ise bekleme ağırlıklı (I/O, commit, latch vs.).
--
--  executions_k (bin adet):
--      • Çalıştırma sayısı (bin’e bölünmüş).
--      • Az çağrılı ağır raporlar: düşük, API/chatty uygulamalar: yüksek.
--
--  exec_rank:
--      • En çok çalışan ilk 5–10 çağrı uygulama davranışını belirler; batching/caching adaylarıdır.
--
--  cpu_per_exec_s (saniye/exec):
--      • Bir çalıştırma başına ortalama CPU süresi.
--      • > 0.05 s (50 ms): Yüksek; plan/indeks bak. > 0.2 s: Ağır; acil tuning.
--
--  buffer_gets_per_exec (mantıksal I/O / exec):
--      • Her çalıştırmada buffer cache’den okunan blok sayısı.
--      • > 10.000: Yüksek.  > 100.000: Kritik; indeks/plan gözden geçirilmeli.
--
--  module:
--      • Çağrıyı yapan modül/program (örn. “JDBC Thin Client”, “oracle@host (J000)”).
--
--  sql_text (ilk 50 karakter):
--      • Sorguyu hızlı tanımak için kısa özet.
--      • Tam metin için v$sqlarea veya dbms_xplan.display_cursor ile detay bakılabilir.
--
--  Hızlı Karar Şeması:
--      • cpu_pct ≥ %20 → Öncelik #1 bu SQL.
--      • cpu_per_exec_s > 50 ms → Tek çağrı pahalı → plan/indeks/filtre/taslak sorgu düzelt.
--      • executions_k çok yüksek & cpu_per_exec_s düşük (örn. 1–5 ms) → “Chatty” → batching, caching, fetch size ↑, result cache kullanımı.
--      • buffer_gets_per_exec > 10k → Mantıksal I/O ağır → indeks/erişim yolu düzelt.
--      • elapsed ≫ cpu → Wait problemi → ASH ile wait_class/event kırılımına bak.
--      • plan_hash sık değişiyor → Plan stabil değil → istatistikler, bind peeking, SQL Plan Baseline/Profiles düşün.
--
--  Geliştirici: Evliya Diyar
--  GitHub:     https://github.com/evliyadiyar
