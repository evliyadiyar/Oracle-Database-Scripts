-- En çok yer kaplayan ilk 20 tabloyu ve sahiplerini listeler.
-- Boyutlar megabayt (MB) cinsindendir.
-- Sadece 'TABLE' segment tipindeki objeleri dikkate alır, indexleri hariç tutar.

SELECT
    owner,
    segment_name AS table_name,
    TRUNC(SUM(bytes) / 1024 / 1024) AS table_size_mb
FROM
    dba_segments
WHERE
    segment_type = 'TABLE'
GROUP BY
    owner,
    segment_name
ORDER BY
    table_size_mb DESC
FETCH FIRST 20 ROWS ONLY;
