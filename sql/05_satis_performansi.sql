/* =====================================================================
   05_satis_performansi.sql
   İş sorusu : Satışlar zaman içinde nasıl değişmiş, hangi kategoriler
               öne çıkıyor?

   Sadece teslim edilen siparişler alındı.
   Ciro: ürün fiyatlarının toplamı (kargo ücreti hariç), Brezilya reali (BRL).
   ===================================================================== */

USE OlistDB;

-- 1) Aylara göre sipariş sayısı ve ciro
--    Sonuç:  2016'da çok az sipariş var (Eylül 1, Ekim 265, Aralık 1; Kasım yok).
--    Düzenli veri Ocak 2017'de başlıyor, son ay Ağustos 2018.
--    En yüksek ay Kasım 2017: 7.289 sipariş, 987.765 BRL ciro.
--    2018'de aylık sipariş sayısı 6.099 ile 7.069 arasında.

SELECT YEAR(o.order_purchase_timestamp)  AS yil,
       MONTH(o.order_purchase_timestamp) AS ay,
       COUNT(DISTINCT o.order_id)        AS siparis_sayisi,
       CAST(SUM(i.price) AS decimal(12,2)) AS ciro
FROM dbo.orders AS o
JOIN dbo.order_items AS i
  ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY YEAR(o.order_purchase_timestamp),
         MONTH(o.order_purchase_timestamp)
ORDER BY yil, ay;

-- 2) En çok ciro getiren 10 kategori
--    Kategori adları İngilizce çeviriden alındı. Çevirisi olmayan ya da
--    kategorisi boş olan ürünler 'bilinmiyor' olarak gösterildi.
--    Sonuç: En çok ciro health_beauty (1.233.132 BRL), ardından watches_gifts
--    (1.166.177 BRL) ve bed_bath_table (1.023.435 BRL).
--    En çok sipariş bed_bath_table'da (9.272) ama ciroda 3. sırada.

SELECT TOP 10
       ISNULL(t.product_category_name_english, 'bilinmiyor') AS kategori,
       COUNT(DISTINCT o.order_id)          AS siparis_sayisi,
       CAST(SUM(i.price) AS decimal(12,2)) AS ciro
FROM dbo.orders AS o
JOIN dbo.order_items AS i
  ON o.order_id = i.order_id
JOIN dbo.products AS p
  ON i.product_id = p.product_id
LEFT JOIN dbo.category_translation AS t
  ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY ISNULL(t.product_category_name_english, 'bilinmiyor')
ORDER BY ciro DESC;

-- 3) Ortalama sipariş tutarı (sepet tutarı)
--    Önce her siparişin toplam tutarı, sonra bunların ortalaması alındı.
--    Sonuç: 96.478 siparişte ortalama sipariş tutarı 137,04 BRL.
--    En düşük 0,85 BRL, en yüksek 13.440 BRL.

WITH siparis_tutarlari AS (
    SELECT i.order_id,
           SUM(i.price) AS siparis_tutari
    FROM dbo.order_items AS i
    JOIN dbo.orders AS o
      ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY i.order_id
)
SELECT COUNT(*)                                   AS siparis_sayisi,
       CAST(AVG(siparis_tutari) AS decimal(10,2)) AS ort_siparis_tutari,
       CAST(MIN(siparis_tutari) AS decimal(10,2)) AS en_dusuk,
       CAST(MAX(siparis_tutari) AS decimal(10,2)) AS en_yuksek
FROM siparis_tutarlari;
