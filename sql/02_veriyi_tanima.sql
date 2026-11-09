/* =====================================================================
   02_veriyi_tanima.sql
   Amaç : Analize başlamadan önce veriyi tanımak (keşifsel veri analizi)
   Sorular:
     1. Siparişler hangi durumlarda ve kaçar tane?
     2. Veri hangi tarih aralığını kapsıyor?
     3- 12 Diğer tablolarda veri kalitesi ve yapı kontrolleri
   ===================================================================== */
 
USE OlistDB;
 
-- 1) Sipariş durumlarına göre sipariş sayısı
--    Sonuç: Siparişlerin %97'si teslim edilmiş (delivered).
--    Teslimat analizinde yalnızca 'delivered' siparişler kullanılacak,
--    çünkü teslim tarihi sadece bu siparişlerde bulunuyor.
SELECT order_status,
       COUNT(*) AS siparis_sayisi,
       CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dbo.orders) AS decimal(5,1)) AS yuzde
FROM dbo.orders
GROUP BY order_status
ORDER BY siparis_sayisi DESC;
 
-- 2) Verinin kapsadığı tarih aralığı
--    Sonuç: 4 Eylül 2016 - 17 Ekim 2018 (yaklaşık 2 yıl)
SELECT MIN(order_purchase_timestamp) AS eski_siparis,
       MAX(order_purchase_timestamp) AS yeni_siparis
FROM dbo.orders;
 
/* ---------------------------------------------------------------------
   MÜŞTERİLER
   --------------------------------------------------------------------- */
 
-- 3) Kaç gerçek müşteri var?
--    Olist her siparişe yeni bir customer_id veriyor. Aynı kişiyi
--    customer_unique_id gösteriyor.
--    Sonuç:  99.441 customer_id var, benzersiz müşteri sayısı 96.096.
--    Yani bazı müşteriler birden fazla sipariş vermiş. 
SELECT COUNT(*)                           AS customer_id_sayisi,
       COUNT(DISTINCT customer_unique_id) AS gercek_musteri_sayisi
FROM dbo.customers;
 

-- 4) Birden fazla sipariş veren müşteri sayısı
--    Sonuç: 2.997 müşteri birden fazla sipariş vermiş.
SELECT COUNT(*) AS tekrar_alan_musteri
FROM (
    SELECT customer_unique_id
    FROM dbo.customers
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) AS tekrar_alanlar;
 
-- 4a) Tekrar alım oranı
--     Oran = tekrar alan müşteri / tüm benzersiz müşteriler
--     Değerler 3. ve 4. sorgunun sonuçlarından alındı:
--       tüm benzersiz müşteri = 96.096 (3. sorgu)
--       tekrar alan müşteri   =  2.997 (4. sorgu)
--     Sonuç: Müşterilerin %3,1'i tekrar alışveriş yapmış.
SELECT CAST(100.0 * 2997 / 96096 AS decimal(5,1)) AS tekrar_alim_orani;
 
-- 4b) Müşterilerin sipariş sayısı dağılımı
--     3. ve 4. sorgudaki farkın kontrolü: 99.441 - 96.096 = 3.345 fazladan ID var,
--     ama tekrar alan müşteri 2.997. Aradaki fark 3 ve daha fazla sipariş
--     veren müşterilerden geliyor.
--     Sonuç: Müşterilerin büyük çoğunluğu (93.099) yalnızca 1 sipariş vermiş.
--     Tekrar alan 2.997 müşterinin 2.745'i 2 sipariş vermiş; 3 ve üzeri
--     sipariş veren 252 müşteri var. Fazladan ID'lerin toplamı 3.345'i
--     tutuyor, yani 3. ve 4. sorgu arasında tutarsızlık yok.
--     17 sipariş veren 1 müşteri dikkat çekiyor.
SELECT siparis_sayisi,
       COUNT(*) AS musteri_sayisi
FROM (
    SELECT customer_unique_id,
           COUNT(*) AS siparis_sayisi
    FROM dbo.customers
    GROUP BY customer_unique_id
) AS musteri_siparisleri
GROUP BY siparis_sayisi
ORDER BY siparis_sayisi;

/* ---------------------------------------------------------------------
   SİPARİŞ KALEMLERİ
   --------------------------------------------------------------------- */
-- 5) Ürün tablosundaki satır sayısı ve sipariş sayısı
--    Sonuç: 112.650 satır var ama yalnızca 98.666 farklı sipariş var.
--    Not : Tabloda her satır bir ürün. Birden fazla ürünlü siparişler
--    birden fazla satırda geçiyor. Sipariş sayarken COUNT(DISTINCT order_id)
--    kullanılmalı; tablolar birleştirilirken de sipariş bazlı değerler
--    (ödeme, puan) tekrar ederek toplamları şişirebilir.
SELECT COUNT(*)                 AS satir_sayisi,
       COUNT(DISTINCT order_id) AS siparis_sayisi
FROM dbo.order_items;
 
-- 5a) Siparişlerde kaçar ürün var?
--     Sonuç: 88.863 sipariş tek ürünlü, en kalabalık grup bu.
--     En fazla ürün içeren sipariş 21 ürünlü.
SELECT urun_sayisi,
       COUNT(*) AS siparis_sayisi
FROM (
    SELECT order_id, COUNT(*) AS urun_sayisi
    FROM dbo.order_items
    GROUP BY order_id
) AS siparis_urunleri
GROUP BY urun_sayisi
ORDER BY urun_sayisi;
 
-- 5b) Tek ürünlü siparişlerin oranı
--     Değerler 5. ve 5a sorgusundan alındı:
--       tek ürünlü sipariş        = 88.863 (5a)
--       ürün tablosundaki sipariş = 98.666 (5)
--     Sonuç: Siparişlerin %90,1'i tek ürünlü.
SELECT CAST(100.0 * 88863 / 98666 AS decimal(5,1)) AS tek_urunlu_oran;
 
-- 5c) Hiç ürün satırı olmayan siparişler
--     Toplam 99.441 sipariş var ama ürün tablosunda 98.666 sipariş geçiyor.
--     Aradaki siparişler hangi durumda?
--     Sonuç: Ürün satırı olmayan 775 siparişin 767'si stokta olmadığı
--     (unavailable, 603) ya da iptal edildiği (canceled, 164) için ürün
--     içermiyor.
--     Kalan 8 sipariş (created 5, invoiced 2, shipped 1) süreçte görünmesine
--     rağmen ürün satırı yok. Özellikle kargoya verilmiş görünen 1 sipariş
--     bir veri tutarsızlığı; analizlerde dikkate alınmalı.
SELECT order_status,
       COUNT(*) AS siparis_sayisi
FROM dbo.orders
WHERE order_id NOT IN (SELECT order_id FROM dbo.order_items)
GROUP BY order_status
ORDER BY siparis_sayisi DESC;
 
/* ---------------------------------------------------------------------
   ÖDEMELER
   --------------------------------------------------------------------- */
 
-- 6) Ödeme türleri, sayıları ve ortalama taksit
--    Sonuç: Ödemelerin %73,9'u kredi kartı (76.795), %19,0'u boleto (19.784),
--    %5,6'sı kupon/hediye çeki (5.775), %1,5'i banka kartı (1.529).
--    Taksitli ödeme yalnızca kredi kartında var (ortalama 3.5 taksit);
--    diğer yöntemler tek çekim.
--    3 ödemenin türü tanımsız (not_defined); sonuçları etkilemeyecek kadar az.
SELECT payment_type,
       COUNT(*)                  AS odeme_sayisi,
	   CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dbo.order_payments) AS decimal(5,1)) AS yuzde,
        CAST(AVG(payment_installments * 1.0) AS decimal(5,1)) AS ort_taksit
FROM dbo.order_payments
GROUP BY payment_type
ORDER BY odeme_sayisi DESC;
 
-- 7) Birden fazla ödeme satırı olan siparişler var mı?
--    Sonuç:  103.886 ödeme satırı, 99.440 sipariş. Bazı siparişler birden
--    fazla ödeme satırına sahip.
SELECT COUNT(*)                 AS odeme_satiri,
       COUNT(DISTINCT order_id) AS odeme_yapilan_siparis
FROM dbo.order_payments;
 
 -- 7a) Ödeme kaydı olmayan siparişler
--     Sonuç: 1 sipariş (bfbd0f9bdef84302105ad712db648a6c), durumu delivered.
--     Teslim edilmiş ama ödeme kaydı yok; küçük bir veri tutarsızlığı.
SELECT order_id,
       order_status
FROM dbo.orders
WHERE order_id NOT IN (SELECT order_id FROM dbo.order_payments);
/* ---------------------------------------------------------------------
   YORUMLAR
   --------------------------------------------------------------------- */
 
-- 8) Yorum puanlarının dağılımı (1-5)
--    Sonuç: 5 puan %57,8 (57.328), 4 puan %19,3 (19.142), 3 puan %8,2 (8.179),
--    2 puan %3,2 (3.151), 1 puan %11,5 (11.424).
SELECT review_score,
       COUNT(*) AS yorum_sayisi,
	   CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dbo.order_reviews) AS decimal(5,1)) AS yuzde
FROM dbo.order_reviews
GROUP BY review_score
ORDER BY review_score;
 
-- 9) Yorumu olan sipariş sayısı (toplam sipariş: 99.441)
--    Sonuç: 98.673 siparişin yorumu var.
SELECT COUNT(DISTINCT order_id) AS yorumlu_siparis
FROM dbo.order_reviews;
 
/* ---------------------------------------------------------------------
   ÜRÜNLER VE SİPARİŞLER: BOŞ DEĞER KONTROLLERİ
   --------------------------------------------------------------------- */
 
-- 10) Kategorisi boş olan ürün sayısı
--     Sonuç: 610 ürünün kategorisi boş.
SELECT COUNT(*) AS kategorisiz_urun
FROM dbo.products
WHERE product_category_name IS NULL;
 
-- 11) Teslim edilmiş görünüp teslim tarihi boş olan siparişler
--     Sonuç: 8 sipariş teslim edilmiş (delivered) ama teslim tarihi boş.
SELECT COUNT(*) AS tarihi_eksik_teslimat
FROM dbo.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;
 
/* ---------------------------------------------------------------------
   TABLOLAR ARASI BAĞLANTI KONTROLÜ
   --------------------------------------------------------------------- */
 
-- 12) Sipariş kalemlerinde, ürünler tablosunda olmayan ürün var mı?
--     Sonuç: Sipariş kalemlerindeki tüm ürünler ürünler tablosunda var.
SELECT COUNT(*) AS eslesmeyen_urun
FROM dbo.order_items
WHERE product_id NOT IN (SELECT product_id FROM dbo.products);
