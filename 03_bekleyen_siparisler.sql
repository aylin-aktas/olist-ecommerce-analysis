/* =====================================================================
   03_bekleyen_siparisler.sql
   İş sorusu : Henüz teslim edilmemiş siparişlerden hangilerine öncelik
               verilmeli? (Operasyon ekibi için "bekleyen işler" raporu)

   Referans tarihi:
     Veri 2018'de sona erdiği için "bugün" olarak gerçek tarih yerine
     verideki son sipariş tarihi kullanıldı. Aksi halde her sipariş
     yıllardır bekliyor görünürdü.

   Veri sınırlılığı:
     Veri seti belirli bir andaki anlık görüntüdür. Açık görünen bazı
     siparişler, sistemde güncellenmemiş eski kayıtlar olabilir.
   ===================================================================== */

USE OlistDB;

DECLARE @referans_tarihi datetime2 = (SELECT MAX(order_purchase_timestamp) FROM dbo.orders);

-- 1) Özet: Açık siparişler duruma göre kaç tane, ne kadar süredir bekliyor,
--    kaçının müşteriye söz verilen teslim tarihi geçmiş?
--    Sonuç: 1.729 açık sipariş var (shipped 1.107, invoiced 314, processing 301,
--    created 5, approved 2). Hepsinin söz verilen teslim tarihi geçmiş; ortalama
--    bekleme 310-579 gün. Büyük olasılıkla güncellenmemiş eski kayıtlar.

SELECT order_status                                                   AS siparis_durumu,
       COUNT(order_id)                                                AS siparis_sayisi,
       MIN(order_purchase_timestamp)                                  AS en_eski_siparis,
       AVG(DATEDIFF(day, order_purchase_timestamp, @referans_tarihi)) AS ort_bekleme_gun,
       SUM(CASE WHEN order_estimated_delivery_date < @referans_tarihi
                THEN 1 ELSE 0 END)                                    AS gecikmis_siparis
FROM dbo.orders
WHERE order_status IN ('created', 'approved', 'invoiced', 'processing', 'shipped')
GROUP BY order_status
ORDER BY ort_bekleme_gun DESC;

-- 2)  Kargodaki gecikmiş siparişler, öncelik sırasına göre
--    (Kargo firmasıyla görüşmede kullanılacak liste)
--    Sonuç: Kargodaki 1.107 siparişin tamamının söz verilen teslim tarihi geçmiş.

GO 
DECLARE @referans_tarihi datetime2 = (SELECT MAX(order_purchase_timestamp) FROM dbo.orders);

SELECT order_id,
       order_purchase_timestamp,
       order_estimated_delivery_date,
       DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) AS gecikme_gun,
       CASE WHEN DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) > 30 THEN 'Acil'
            WHEN DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) > 10 THEN 'Yüksek'
            ELSE 'Normal'
       END AS oncelik
FROM dbo.orders
WHERE order_status = 'shipped'
  AND order_estimated_delivery_date < @referans_tarihi
ORDER BY gecikme_gun DESC;

-- 2a) Öncelik gruplarına göre özet
--    Her grupta kaç sipariş var ve ortalama kaç gün gecikmiş?
--    Sonuç: 1.106 sipariş Acil (ortalama 290 gün gecikme), 1 sipariş Yüksek (29 gün).
--    Normal grubunda sipariş yok.

GO 
DECLARE @referans_tarihi datetime2 = (SELECT MAX(order_purchase_timestamp) FROM dbo.orders);

SELECT CASE WHEN DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) > 30 THEN 'Acil'
            WHEN DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) > 10 THEN 'Yüksek'
            ELSE 'Normal'
       END AS gecikme_durumu,
       COUNT(*)                                                            AS siparis_sayisi,
       AVG(DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi)) AS ort_gecikme_gun
FROM dbo.orders
WHERE order_status = 'shipped'
  AND order_estimated_delivery_date < @referans_tarihi
GROUP BY CASE WHEN DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) > 30 THEN 'Acil'
              WHEN DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) > 10 THEN 'Yüksek'
              ELSE 'Normal'
         END
ORDER BY ort_gecikme_gun DESC;

-- 3) Aynı özetin CTE (WITH) ile yazılmış hali
--    2a. sorguda CASE ifadesi hem SELECT'te hem GROUP BY'da tekrar yazılıyor.
--    CTE ile gecikme günü ve öncelik bir kez hesaplanıyor, sonra bu
--    hazır sütunlar üzerinden gruplama yapılıyor. Eşik değiştirmek
--    gerekirse tek yerden düzeltmek yeterli.
GO 

DECLARE @referans_tarihi datetime2 = (SELECT MAX(order_purchase_timestamp) FROM dbo.orders);

WITH gecikmis_kargolar AS (
    -- 1. aşama: Her sipariş için gecikme günü ve öncelik etiketi

    SELECT order_id,
           DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) AS gecikme_gun,
           CASE WHEN DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) > 30 THEN 'Acil'
                WHEN DATEDIFF(day, order_estimated_delivery_date, @referans_tarihi) > 10 THEN 'Yüksek'
                ELSE 'Normal'
           END AS oncelik
    FROM dbo.orders
    WHERE order_status = 'shipped'
      AND order_estimated_delivery_date < @referans_tarihi
)
-- 2. aşama: Öncelik gruplarına göre sipariş sayısı ve ortalama gecikme
SELECT oncelik,
       COUNT(*)         AS siparis_sayisi,
       AVG(gecikme_gun) AS ort_gecikme_gun
FROM gecikmis_kargolar
GROUP BY oncelik
ORDER BY ort_gecikme_gun DESC;