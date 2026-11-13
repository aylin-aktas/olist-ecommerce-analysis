# Olist E-Ticaret Analizi: Satış, Teslimat ve Müşteri Memnuniyeti

> **Durum:** Devam ediyor

**English summary:** SQL Server analysis of ~100k orders from Olist, a Brazilian e-commerce marketplace (2016–2018). The project explores sales performance, delivery delays and their effect on customer satisfaction.

## Proje Hakkında

Bu projede Brezilya'daki Olist e-ticaret pazaryerine ait, herkese açık ve anonimleştirilmiş yaklaşık 100 bin siparişlik veri setini SQL Server üzerinde analiz ediyorum.

**Ana soru:** Teslimat gecikmeleri müşteri memnuniyetini ne kadar etkiliyor ve şirket bu konuda ne yapabilir?

## Veri Seti

- **Kaynak:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Lisans:** CC BY-NC-SA 4.0
- **Kapsam:** 99.441 sipariş, 4 Eylül 2016 – 17 Ekim 2018
- **Kullanılan tablolar:** siparişler, sipariş kalemleri, ödemeler, yorumlar, müşteriler, ürünler, satıcılar, kategori çevirisi

## Araçlar

- SQL Server / SSMS (T-SQL)
- Power BI (planlanıyor)

## Proje Yapısı

| Dosya | İçerik |
|---|---|
| `sql/01_veri_yukleme.sql` | Tabloların oluşturulması ve CSV dosyalarının yüklenmesi |
| `sql/02_veriyi_tanima.sql` | Veriyi tanıma ve veri kalitesi kontrolleri |
| `sql/03_bekleyen_siparisler.sql` | Teslim edilmemiş siparişler için gecikmeye göre öncelik raporu |
| *(hazırlanıyor)* | Satış performansı, teslimat analizi, müşteri memnuniyeti |

## Veriyi Tanıma: İlk Bulgular

- Siparişlerin %97'si teslim edilmiş. Teslimat analizinde yalnızca teslim edilen siparişler kullanılacak.
- 96.096 benzersiz müşteri var; bunların 2.997'si birden fazla sipariş vermiş (%3,1). Tekrar alım oranı düşük.
- Siparişlerin %90,1'i tek ürünlü.
- Ödemelerin %73,9'u kredi kartıyla, %19,0'u boleto ile yapılmış. Kredi kartında ortalama taksit 3,5.
- Yorumların %57,8'i 5 puan, %11,5'i 1 puan.

## Bekleyen Siparişler Raporu

- Veride 1.729 açık sipariş görünüyor (kargoda 1.107, faturalanmış 314, hazırlanıyor 301, oluşturulmuş 5, onaylanmış 2).
- Hepsinin söz verilen teslim tarihi geçmiş ve ortalama 310–579 gündür bekliyor. Kargodaki siparişlerin 1.106'sı ortalama 290 gün gecikmeli.
- Bu siparişler büyük olasılıkla güncellenmemiş eski kayıtlar. Rapor, referans tarihi `GETDATE()` ile değiştirilerek canlı veride günlük olarak kullanılabilir.

## Veri Kalitesi Notları

- Sipariş kalemleri ve ödemeler tablolarında bir sipariş birden fazla satırda geçebiliyor. Sipariş sayarken `COUNT(DISTINCT order_id)` kullanıldı.
- Ürün satırı olmayan 775 siparişin 767'si iptal edilmiş ya da stokta olmayan siparişler.
- 610 ürünün kategorisi boş.
- 8 sipariş teslim edilmiş görünüyor ama teslim tarihi boş; teslimat analizinde dışarıda bırakılacak.
- 1 teslim edilmiş siparişin ödeme kaydı yok.

## Projeyi Çalıştırma

1. Veri setini Kaggle'dan indirip CSV dosyalarını bir klasöre çıkarın.
2. SQL Server'da `OlistDB` adında yeni ve boş bir veritabanı oluşturun. (Yükleme dosyası aynı adlı tabloları silip yeniden kurar.)
3. `sql/01_veri_yukleme.sql` dosyasındaki `C:\data\olist` yolunu kendi klasörünüzle değiştirip çalıştırın.
4. Diğer dosyaları numara sırasıyla çalıştırın.
