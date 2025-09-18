--------------------------------------------------------------------------------
--  SchedulerJobHighPGA.sql
--  Oracle: Son 7 Gün İçinde DBMS_SCHEDULER ile Çalışan ve Yüksek PGA Kullanan
--  Arka Plan (Job) Oturumlarının Analizi
--  Yazar: Evliya Diyar | https://github.com/evliyadiyar/
--
--  Açıklama:
--      Bu sorgu, son 7 gün içinde DBMS_SCHEDULER tarafından başlatılan ve
--      program adı '%J0%' olan (tipik olarak arka plan job'ları) oturumlarda
--      100 MB'tan fazla PGA tahsis edilen örnekleri listeler.
--      Ayrıca geçici alan (TEMP) kullanımı ve ilgili SQL kimliği gibi metrikleri de içerir.
--
--  Kullanım:
--      SQL*Plus veya başka bir SQL aracı ile çalıştırabilirsiniz.
--      Arka plan job'larında (ör. otomasyon, toplu işler) bellek yönetimi ve tuning
--      için kullanışlıdır.
--------------------------------------------------------------------------------

SELECT 
    s.snap_id,
    s.begin_interval_time,                          -- Snapshot başlangıcı (zaman aralığı)
    ash.sample_time,                                -- ASH örnekleme zamanı
    ash.session_id,                                 -- Oturum ID
    ash.program,                                    -- Program adı (örn. arka plan job)
    ash.module,                                     -- Modül (örn. DBMS_SCHEDULER)
    ash.action,                                     -- Action (örn. ORA$AT_OS_OPT% gibi detaylar)
    ash.pga_allocated/1024/1024 AS pga_mb,          -- PGA kullanımı (MB)
    ash.temp_space_allocated/1024/1024 AS temp_mb,  -- Geçici alan kullanımı (MB)
    ash.sql_id                                      -- İşletilen SQL kimliği
FROM dba_hist_snapshot s,
     dba_hist_active_sess_history ash
WHERE s.snap_id = ash.snap_id
  AND s.dbid = ash.dbid
  AND s.instance_number = ash.instance_number
  AND ash.sample_time >= SYSDATE - 7                 -- Son 7 gün
  AND ash.program LIKE '%J0%'                        -- Arka plan job (örn. J000, J001)
  AND ash.module = 'DBMS_SCHEDULER'                  -- Scheduler job'ları
  AND ash.action LIKE '%ORA$AT_OS_OPT%'              -- Otomatik optimizer işleri vb.
  AND ash.pga_allocated > 100*1024*1024              -- 100 MB üstü PGA kullanımı
ORDER BY ash.sample_time DESC, ash.pga_allocated DESC;

--------------------------------------------------------------------------------
-- Açıklamalar:
--  snap_id:             İlgili AWR snapshot kimliği
--  begin_interval_time: Snapshot'ın başladığı zaman (analiz aralığı için)
--  sample_time:         ASH örneklemesinin zamanı (yükün ne zaman oluştuğu)
--  session_id:          Oturum kimliği
--  program:             Oturumu başlatan program (örn. arka plan job)
--  module:              Uygulama modülü (DBMS_SCHEDULER)
--  action:              Detaylı iş tipi (örn. otomatik task)
--  pga_mb:              PGA RAM kullanımı (MB)
--  temp_mb:             Geçici alan kullanımı (MB)
--  sql_id:              Çalışan SQL’in kimliği
--
--  Notlar:
--      - Arka planda çalışan job'larda (J0) yüksek bellek tüketimi tuning fırsatı sunar.
--      - action, program ve module filtrelerini ihtiyacınıza göre düzenleyebilirsiniz.
--      - Daha fazla detay için SQL_ID üzerinden v$sqlarea veya dbms_xplan ile plan bakılabilir.
--
--  Geliştirici: Evliya Diyar
--  GitHub:     https://github.com/evliyadiyar
--------------------------------------------------------------------------------
