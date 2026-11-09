/* =====================================================================
   01_veri_yukleme.sql
   Amaç   : Olist CSV dosyalarından tabloları oluşturmak ve veriyi yüklemek
   Araç   : SQL Server (T-SQL), SSMS
   Not    : 'C:\data\olist' yerine CSV dosyalarının bulunduğu klasörü yazın.
            Yükleme BULK INSERT ile yapılır (Import Flat File sihirbazına
            göre çok daha hızlıdır).
   Sıra   : Her tablo için  Sil -> Tanımla -> Yükle , en sonda Kontrol

   Not	  : Sorgu OlistDB içinde aynı adlı tablolar varsa onları
   silip (DROP TABLE) yeniden oluşturur. Bu sayede dosya tekrar tekrar
   çalıştırılabilir. 
   ===================================================================== */

USE OlistDB;

-- 1) SİPARİŞLER
DROP TABLE IF EXISTS dbo.orders;
CREATE TABLE dbo.orders (
    order_id                      varchar(50) NOT NULL PRIMARY KEY,
    customer_id                   varchar(50),
    order_status                  varchar(20),
    order_purchase_timestamp      datetime2,
    order_approved_at             datetime2 NULL,
    order_delivered_carrier_date  datetime2 NULL,
    order_delivered_customer_date datetime2 NULL,
    order_estimated_delivery_date datetime2
);
BULK INSERT dbo.orders
FROM 'C:\data\olist\olist_orders_dataset.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

-- 2) SİPARİŞ KALEMLERİ
DROP TABLE IF EXISTS dbo.order_items;
CREATE TABLE dbo.order_items (
    order_id            varchar(50) NOT NULL,
    order_item_id       int         NOT NULL,
    product_id          varchar(50),
    seller_id           varchar(50),
    shipping_limit_date datetime2,
    price               decimal(10,2),
    freight_value       decimal(10,2),
    PRIMARY KEY (order_id, order_item_id)
);
BULK INSERT dbo.order_items
FROM 'C:\data\olist\olist_order_items_dataset.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

-- 3) ÖDEMELER
DROP TABLE IF EXISTS dbo.order_payments;
CREATE TABLE dbo.order_payments (
    order_id             varchar(50),
    payment_sequential   int,
    payment_type         varchar(20),
    payment_installments int,
    payment_value        decimal(10,2)
);
BULK INSERT dbo.order_payments
FROM 'C:\data\olist\olist_order_payments_dataset.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

-- 4) YORUMLAR
--    Yorum metinlerinde satır sonları olduğu için bu dosyada
--    Windows satır sonu (0x0d0a) kullanıldı.
DROP TABLE IF EXISTS dbo.order_reviews;
CREATE TABLE dbo.order_reviews (
    review_id               varchar(50),
    order_id                varchar(50),
    review_score            int,
    review_comment_title    nvarchar(max) NULL,
    review_comment_message  nvarchar(max) NULL,
    review_creation_date    datetime2,
    review_answer_timestamp datetime2
);
BULK INSERT dbo.order_reviews
FROM 'C:\data\olist\olist_order_reviews_dataset.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0d0a', CODEPAGE = '65001');

-- 5) MÜŞTERİLER
--    Posta kodu metin olarak saklandı (baştaki sıfırlar kaybolmasın diye).
DROP TABLE IF EXISTS dbo.customers;
CREATE TABLE dbo.customers (
    customer_id              varchar(50) NOT NULL PRIMARY KEY,
    customer_unique_id       varchar(50),
    customer_zip_code_prefix varchar(10),
    customer_city            nvarchar(100),
    customer_state           char(2)
);
BULK INSERT dbo.customers
FROM 'C:\data\olist\olist_customers_dataset.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

-- 6) ÜRÜNLER
--    'lenght' yazımı veri setinin orijinal sütun adıdır.
DROP TABLE IF EXISTS dbo.products;
CREATE TABLE dbo.products (
    product_id                 varchar(50) NOT NULL PRIMARY KEY,
    product_category_name      nvarchar(100) NULL,
    product_name_lenght        decimal(10,2) NULL,
    product_description_lenght decimal(10,2) NULL,
    product_photos_qty         decimal(10,2) NULL,
    product_weight_g           decimal(10,2) NULL,
    product_length_cm          decimal(10,2) NULL,
    product_height_cm          decimal(10,2) NULL,
    product_width_cm           decimal(10,2) NULL
);
BULK INSERT dbo.products
FROM 'C:\data\olist\olist_products_dataset.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

-- 7) SATICILAR
DROP TABLE IF EXISTS dbo.sellers;
CREATE TABLE dbo.sellers (
    seller_id              varchar(50) NOT NULL PRIMARY KEY,
    seller_zip_code_prefix varchar(10),
    seller_city            nvarchar(100),
    seller_state           char(2)
);
BULK INSERT dbo.sellers
FROM 'C:\data\olist\olist_sellers_dataset.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

-- 8) KATEGORİ ÇEVİRİSİ (Portekizce -> İngilizce)
DROP TABLE IF EXISTS dbo.category_translation;
CREATE TABLE dbo.category_translation (
    product_category_name         nvarchar(100),
    product_category_name_english nvarchar(100)
);
BULK INSERT dbo.category_translation
FROM 'C:\data\olist\product_category_name_translation.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

-- KONTROL: Her tablonun satır sayısı
SELECT 'orders' AS tablo, COUNT(*) AS satir FROM dbo.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM dbo.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM dbo.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM dbo.order_reviews
UNION ALL SELECT 'customers', COUNT(*) FROM dbo.customers
UNION ALL SELECT 'products', COUNT(*) FROM dbo.products
UNION ALL SELECT 'sellers', COUNT(*) FROM dbo.sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM dbo.category_translation;
