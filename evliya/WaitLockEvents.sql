Aşağıdaki sorgu “bekleyen ↔ bloklayan” ikilisini tek shot gösterir (RAC dahil):
WITH links AS (
  SELECT w.inst_id   AS w_inst,
         w.sid       AS w_sid,
         w.serial#   AS w_serial,
         w.username  AS w_user,
         w.sql_id    AS w_sql_id,
         COALESCE(w.final_blocking_instance, w.blocking_instance) AS b_inst,
         COALESCE(w.final_blocking_session,  w.blocking_session)  AS b_sid,
         w.row_wait_obj# AS row_obj#,
         w.event     AS w_event,
         w.wait_class AS w_wait_class,
         w.seconds_in_wait AS w_secs
  FROM   gv$session w
  WHERE  w.wait_class <> 'Idle'
  AND    (w.blocking_session IS NOT NULL OR w.final_blocking_session IS NOT NULL)
)
SELECT l.w_inst, l.w_sid, l.w_serial, l.w_user, l.w_sql_id,
       l.w_event, l.w_wait_class, l.w_secs,
       b.inst_id   AS b_inst, b.sid AS b_sid, b.serial# AS b_serial,
       b.username  AS b_user, b.status AS b_status,
       COALESCE(b.sql_id, b.prev_sql_id) AS b_sql_id,
       b.event     AS b_event,
       o.owner||'.'||o.object_name AS row_object,
       t.start_time AS tx_start
FROM   links l
JOIN   gv$session b
       ON b.inst_id = l.b_inst AND b.sid = l.b_sid
LEFT JOIN gv$transaction t
       ON t.inst_id = b.inst_id AND t.ses_addr = b.saddr
LEFT JOIN dba_objects o
       ON o.object_id = l.row_obj#
ORDER  BY l.w_secs DESC;

•	b_sql_id: Bloklayanın SQL’i. Oturum “idle in transaction” ise SQL_ID boş olabilir; o yüzden COALESCE(b.sql_id, b.prev_sql_id) kullandım.
•	tx_start: Transaction ne zamandır açık? (Uzun süreli açık transaction = tipik bloklayıcı.)
•	row_object: Eğer satır bekleniyorsa (TX), hangi obje üzerinde beklediğini verir (V$SESSION’deki ROW_WAIT_* sütunları). docs.oracle.com
