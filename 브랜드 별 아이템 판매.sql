-- 아이템 위시리스타 추가 > 아이템 구매 전환 브랜드 별 아이템 리스트

WITH BrandSales AS (
  SELECT properties.brands AS Brand
         , COUNT(*) AS total_sales
    FROM events
   WHERE event = 'item_purchase'
     AND timestamp >= '2024-09-01 00:00:00'  -- Start date
     AND properties.cashType = 'ZEM'
     AND properties.isBrand = true
   GROUP BY properties.brands
  ),
RankedItems AS (
  SELECT properties.brands AS Brand
         , properties.id AS item_id
         , COUNT(*) AS number_sold
         , RANK() OVER (PARTITION BY properties.brands ORDER BY COUNT(*) DESC) AS rank
   FROM events
  WHERE event = 'item_purchase'
    AND timestamp >= '2024-09-01 00:00:00'  -- Start date
    AND properties.cashType = 'ZEM'
    AND properties.isBrand = true
  GROUP BY properties.brands, properties.id
  ),
TopItemPerBrand AS (
  SELECT Brand
         , max(number_sold) AS max_sold
    FROM RankedItems
   GROUP BY Brand
)
SELECT RankedItems.Brand
       , RankedItems.item_id
       , RankedItems.number_sold
  FROM RankedItems
  JOIN TopItemPerBrand ON RankedItems.Brand = TopItemPerBrand.Brand
 ORDER BY RankedItems.number_sold DESC
