--------------------------------------------------------------------------------
--  HighPGASessions.sql
--  Oracle: Yüksek PGA Kullanan Oturumların Haftalık Analizi
--  Yazar: Evliya Diyar | https://github.com/evliyadiyar/
--
--  Açıklama:
--      Bu sorgu, son 7 gün içinde belirli bir kullanıcının (örnek: 'CRANE_CREW_PLN')
--      oturumlarında 500 MB üzerinde PGA RAM tahsis edilmiş örnekleri listeler.
--      En fazla bellek kullanan oturumlar, ilgili SQL_ID, program ve makina bilgileriyle
--      birlikte özetlenir.
--
--  Kullanım:
--      SQL*Plus veya başka bir SQL aracı ile çalıştırabilirsiniz.
--      USERNAME satırını ihtiyacınıza göre güncelleyebilirsiniz.
--      Bellek yönetimi ve tuning için kullanışlıdır.
--------------------------------------------------------------------------------

SELECT
    TO_CHAR(sample_time, 'DD-MM HH24:MI') AS sample_time,  -- Örnekleme zamanı (dakika hassasiyetinde)
    session_id,
    session_serial#,
    sql_id,
    MAX(pga_allocated) / 1024 / 1024 / 1024 AS max_pga_gb, -- GB cinsinden maksimum PGA
    program,
    machine,
    COUNT(*) AS samples                                    -- Kaç örnek var (yoğunluk göstergesi)
FROM
    v$active_session_history
WHERE
    sample_time >= SYSDATE - 7                             -- Son 7 gün
    AND user_id = (SELECT user_id FROM dba_users WHERE username = 'CRANE_CREW_PLN')
    AND pga_allocated > 500*1024*1024                      -- 500 MB üstü PGA
GROUP BY
    TO_CHAR(sample_time, 'DD-MM HH24:MI'),
    session_id,
    session_serial#,
    sql_id,
    program,
    machine
ORDER BY
    max_pga_gb DESC;

--------------------------------------------------------------------------------
-- Açıklamalar:
--  sample_time:      Analiz edilen örnek zaman dilimi (dakika hassasiyetinde)
--  session_id:       Oturumun SID değeri
--  session_serial#:  Oturumun serial numarası
--  sql_id:           Çalışan SQL sorgusunun kimliği
--  max_pga_gb:       O zaman aralığında gözlenen en yüksek PGA kullanımı (GB)
--  program:          Oturumu açan/bağlanan program adı
--  machine:          Oturumun geldiği sunucu/istemci adı
--  samples:          Bu kombinasyona ait örnek sayısı (yoğunluk göstergesi)
--
--  Not:
--      - USERNAME satırını ihtiyacınıza göre değiştirin.
--      - Büyük PGA kullanan oturumlar genelde sorgu optimizasyonu/tuning için incelenir.
--
--  Geliştirici: Evliya Diyar
--  GitHub:     https://github.com/evliyadiyar
--------------------------------------------------------------------------------
