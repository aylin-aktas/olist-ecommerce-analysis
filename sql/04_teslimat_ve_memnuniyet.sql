/* =====================================================================
   04_teslimat_ve_memnuniyet.sql
   İş sorusu : Teslimat gecikmesi müşteri memnuniyetini etkiliyor mu?

   Sadece teslim edilen ve teslim tarihi olan siparişler alındı.
   Geç teslim: söz verilen günden sonra teslim edilen sipariş
   (saat dikkate alınmadı, sadece gün karşılaştırıldı).
   Birden fazla yorumu olan siparişlerde her yorum ayrı sayıldı.
   ===================================================================== */

USE OlistDB;

-- 1) Teslim edilen siparişlerin yüzde kaçı geç teslim edilmiş?
--    Sonuç: 96.470 teslim edilen siparişin 6.534'ü geç teslim edilmiş (%6,8)

SELECT COUNT(*) AS teslim_edilen,
       SUM(CASE WHEN CAST(order_delivered_customer_date AS date) > order_estimated_delivery_date
                THEN 1 ELSE 0 END) AS gec_teslim,
       CAST(100.0 * SUM(CASE WHEN CAST(order_delivered_customer_date AS date) > order_estimated_delivery_date
                             THEN 1 ELSE 0 END) / COUNT(*) AS decimal(5,1)) AS gec_teslim_orani
FROM dbo.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- 2) Geç ve zamanında teslim edilen siparişlerin yorum puanları
--    Sonuç: Geç teslimlerde ortalama puan 2,27, 1 puan oranı %53,7.
--    Zamanında teslimlerde ortalama puan 4,29, 1 puan oranı %6,6.
SELECT CASE WHEN CAST(o.order_delivered_customer_date AS date) > o.order_estimated_delivery_date
            THEN 'Geç' ELSE 'Zamanında' END AS teslimat,
       COUNT(*) AS yorum_sayisi,
       CAST(AVG(r.review_score * 1.0) AS decimal(3,2)) AS ort_puan,
       CAST(100.0 * SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) / COUNT(*)
            AS decimal(5,1)) AS bir_puan_orani
FROM dbo.orders AS o
JOIN dbo.order_reviews AS r
  ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY CASE WHEN CAST(o.order_delivered_customer_date AS date) > o.order_estimated_delivery_date
              THEN 'Geç' ELSE 'Zamanında' END;

-- 3) Gecikme uzadıkça puan nasıl değişiyor?
--    Geç teslimleri gecikme süresine göre gruplara ayırıp her grubun
--    ortalama puanına bakıyoruz.
--    Sonuç: Zamanında 4,29 / 1-5 gün geç 2,99 / 6-15 gün geç 1,75 /
--    15 günden fazla geç 1,73. Gecikme uzadıkça puan düşüyor.
WITH teslimat_puan AS (
    SELECT DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS gecikme_gun,
           r.review_score
    FROM dbo.orders AS o
    JOIN dbo.order_reviews AS r
      ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT CASE WHEN gecikme_gun <= 0  THEN '1. Zamanında'
            WHEN gecikme_gun <= 5  THEN '2. 1-5 gün geç'
            WHEN gecikme_gun <= 15 THEN '3. 6-15 gün geç'
            ELSE                        '4. 15 günden fazla geç'
       END AS gecikme_grubu,
       COUNT(*) AS yorum_sayisi,
       CAST(AVG(review_score * 1.0) AS decimal(3,2)) AS ort_puan
FROM teslimat_puan
GROUP BY CASE WHEN gecikme_gun <= 0  THEN '1. Zamanında'
              WHEN gecikme_gun <= 5  THEN '2. 1-5 gün geç'
              WHEN gecikme_gun <= 15 THEN '3. 6-15 gün geç'
              ELSE                        '4. 15 günden fazla geç'
         END
ORDER BY gecikme_grubu;
