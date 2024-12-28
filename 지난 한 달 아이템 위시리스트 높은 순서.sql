WITH latest_prices AS (
    SELECT properties.id as latest_id
           , properties.price as price
           , ROW_NUMBER() OVER (PARTITION BY properties.id ORDER BY timestamp DESC) AS row_num -- 가격 조정/변동이 있는 경우가 있어 최신 가격 정보 불러오기
      FROM events
     WHERE event = 'item_purchase'
       AND properties.isBrand = true
       AND properties.cashType = 'ZEM'
       AND timestamp >= '2024-09-01 00:00:00'
  ),
wishlist_events AS (
    SELECT properties.id as wish_id,
           , properties.$geoip_country_name,
           , timestamp
      FROM events
     WHERE event = 'item_wishlist_add'
       AND timestamp >= '2023-09-01 00:00:00'
       AND properties.id NOT LIKE 'IP_UGG%'
)

SELECT wishlist_events.wish_id,
       , latest_prices.price,
       , count() AS count_wish
  FROM wishlist_events
  JOIN latest_prices
    ON wishlist_events.wish_id = latest_prices.latest_id
   AND latest_prices.row_num = 1
 GROUP BY wishlist_events.wish_id, latest_prices.price
 ORDER BY count_wish DESC, wishlist_events.wish_id
