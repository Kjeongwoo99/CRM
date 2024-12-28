WITH collectem_sales AS ( -- 컬렉템 매출 
  SELECT substring(concat(timestamp,''),1,7) AS date_month AS date_month -- 매 달로 나누기
         , sum(properties.zemAmount) AS total_purchase -- 컬렉템 젬 매출
    FROM events
   WHERE timestamp >= '2024-02-01' AND timestamp < '2024-09-01' -- 2월 이후
     AND event = 'collectem_purchase'
     AND properties.zemAmount > 0
   GROUP BY date_month
  ),

monthly_new_item_sales AS ( 
  SELECT CASE
          WHEN toDateRaw(properties.startDate) >= '2024-02-01' AND toDateRaw(properties.startDate) < '2024-03-01' THEN '2024-02' -- 매 달 신규 출시 제휴 아이템
          WHEN toDateRaw(properties.startDate) >= '2024-03-01' AND toDateRaw(properties.startDate) < '2024-04-01' THEN '2024-03'
          WHEN toDateRaw(properties.startDate) >= '2024-04-01' AND toDateRaw(properties.startDate) < '2024-05-01' THEN '2024-04'
          WHEN toDateRaw(properties.startDate) >= '2024-05-01' AND toDateRaw(properties.startDate) < '2024-06-01' THEN '2024-05'
          WHEN toDateRaw(properties.startDate) >= '2024-06-01' AND toDateRaw(properties.startDate) < '2024-07-01' THEN '2024-06'
          WHEN toDateRaw(properties.startDate) >= '2024-07-01' AND toDateRaw(properties.startDate) < '2024-08-01' THEN '2024-07'
          WHEN toDateRaw(properties.startDate) >= '2024-08-01' AND toDateRaw(properties.startDate) < '2024-09-01' THEN '2024-08'
          ELSE NULL
         END AS date_month
         , sum(toFloat(properties.charged)) AS new_item_sales  
   FROM events
  WHERE event = 'item_purchase'
    AND toDateRaw(timestamp) >= '2024-02-01' AND toDateRaw(timestamp) < '2024-09-01'
    AND properties.cashType = 'ZEM' -- 젬 매출
    AND properties.itemType IN ('Creator', 'General') -- 일반, 크리에이터
    AND properties.isBrand = TRUE -- 제휴
    AND toFloat(properties.price) > 0 -- 유상
  GROUP BY date_month
)

SELECT collectem_sales.date_month AS date_month,
       , (collectem_sales.total_purchase * 1300 / 14) AS '신규 컬렉템 매출',
       , (monthly_new_item_sales.new_item_sales * 1300 / 14) AS '신규 제휴 아이템 매출',
       , (collectem_sales.total_purchase * 1300 / 14) / 
       , ((collectem_sales.total_purchase * 1300 / 14) + (monthly_new_item_sales.new_item_sales * 1300 / 14)) AS '신규 컬렉템 매출 비중'
  FROM collectem_sales
  JOIN monthly_new_item_sales ON collectem_sales.date_month = monthly_new_item_sales.date_month
 ORDER BY collectem_sales.date_month
