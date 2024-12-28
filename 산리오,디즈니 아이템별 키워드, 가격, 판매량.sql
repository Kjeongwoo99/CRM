SELECT properties.id AS id
       , argMax(properties.keywords, timestamp) AS keyword_raw
       , CASE
          WHEN argMax(properties.keywords, timestamp) LIKE '%outwear%' THEN 'outwear'
          WHEN argMax(properties.keywords, timestamp) LIKE '%pants%' THEN 'pants'
          WHEN argMax(properties.keywords, timestamp) LIKE '%skirt%' THEN 'skirt'
          WHEN argMax(properties.keywords, timestamp) LIKE '%onepiece%' THEN 'onepiece'
          WHEN argMax(properties.keywords, timestamp) LIKE '%footwear%' THEN 'footwear'
          WHEN argMax(properties.keywords, timestamp) LIKE '%accessory_nailart%' THEN 'accessory_nailart'
          WHEN argMax(properties.keywords, timestamp) LIKE '%accessory_bag%' THEN 'accessory_bag'
          WHEN ((argMax(properties.keywords, timestamp) LIKE '%accessory%') AND (argMax(properties.keywords, timestamp) NOT LIKE '%accessory_nailart%')) AND 
          ((argMax(properties.keywords, timestamp) LIKE '%accessory%') AND (argMax(properties.keywords, timestamp) NOT LIKE '%accessory_bag%')) AND 
          ((argMax(properties.keywords, timestamp) LIKE '%accessory%') AND (argMax(properties.keywords, timestamp) NOT LIKE '%headwear_accessory%')) THEN 'accessory_etc'
          WHEN argMax(properties.keywords, timestamp) LIKE '%jewelry_necklace%' THEN 'jewelry_necklace'
          WHEN (argMax(properties.keywords, timestamp) LIKE '%jewelry_earring%') OR (argMax(properties.keywords, timestamp) LIKE 'jewelry_piercing') THEN 'jewelry_earring_&_piercing'
          WHEN ((argMax(properties.keywords, timestamp) LIKE '%jewelry%') AND (argMax(properties.keywords, timestamp) NOT LIKE '%jewelry_necklace%')) AND 
          ((argMax(properties.keywords, timestamp) LIKE '%jewelry%') AND (argMax(properties.keywords, timestamp) NOT LIKE '%jewelry_earring%')) THEN 'jewelry_bracelet_&_anklet'
          WHEN argMax(properties.keywords, timestamp) LIKE '%headwear_top%' THEN 'headwear_top'
          WHEN (argMax(properties.keywords, timestamp) LIKE '%headwear%') AND (argMax(properties.keywords, timestamp) NOT LIKE '%headwear_top%') THEN 'headwear_accessory'
          WHEN argMax(properties.keywords, timestamp) LIKE '%eyewear%' THEN 'eyewear'
          WHEN argMax(properties.keywords, timestamp) LIKE '%socks%' THEN 'socks'
          WHEN argMax(properties.keywords, timestamp) LIKE '%animal%' THEN 'animal'
          WHEN argMax(properties.keywords, timestamp) LIKE '%hair%' THEN 'hair'
          WHEN (argMax(properties.keywords, timestamp) LIKE '%skinmakeup%') OR (argMax(properties.keywords, timestamp) LIKE '%eyemakeup%') OR (argMax(properties.keywords, timestamp) LIKE '%lipmakeup%') THEN 'makeup'
          WHEN (argMax(properties.keywords, timestamp) LIKE '%top%' AND (argMax(properties.keywords, timestamp) NOT LIKE '%headwear_top%'))
          AND (argMax(properties.keywords, timestamp) LIKE '%top%' AND (argMax(properties.keywords, timestamp) NOT LIKE '%topleft%'))
          AND (argMax(properties.keywords, timestamp) LIKE '%top%' AND (argMax(properties.keywords, timestamp) NOT LIKE '%topright%')) THEN 'top'
          ELSE 'etc'
         END AS keyword
        , argMax(toFloat(properties.price), timestamp) AS price, count(*) AS quantity
  FROM events
 WHERE event = 'item_purchase'
   AND timestamp >= '2024-09-01'
   AND timestamp < '2024-12-01'
   AND properties.startdate < '2024-09-02'
   AND properties.cashType = 'ZEM'
   AND (properties.itemType = 'General' OR properties.itemType = 'Creator')
   AND (properties.discountRate IS NULL OR properties.discountRate = '0')
   AND (properties.brands LIKE '%disney%' OR properties.brands LIKE '%sanrio%')
   AND properties.isBrand = True
 GROUP BY properties.id
 ORDER BY keyword DESC, price
