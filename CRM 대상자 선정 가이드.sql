-- 1차 CRM 대상자: 지난 한달간 헤드웨어 위시리스트 추가 유저 (헬로키티 리워드 소유 유저 제외

SELECT distinct_id,
    CASE -- 언어 설정을 위한 CASE 절
        WHEN argMax(properties.$geoip_country_name, timestamp) = 'South Korea' THEN 'KR' -- 마지막 접속 지역이 한국일때 KR 표시
        WHEN argMax(properties.$geoip_country_name, timestamp) = 'Japan' THEN 'JP' -- 마지막 접속 지역이 일본일 때 JP 표시
        ELSE 'EN' -- 마지막 접속 지역이 한국과 일본이 아닐 때 EN 표시
    END AS language
FROM events
WHERE event = 'item_wishlist_add' -- 위시리스트 추가 시 남는 이벤트 
  AND timestamp >= '2024-10-08' -- 시작 시간 입력
  AND timestamp <= '2024-11-15 12:00:00' -- 종료 시간 입력
  AND properties.id LIKE '%HEADWEAR%' -- id 에 HEADWEAR가 포함된 경우
  AND (length(distinct_id) = 24 AND length(person.properties.$app_version) > 0) -- 잘못된 형식의 서포트 코드 제외
  AND distinct_id NOT IN ( -- 헬로키티 리워드중 컬렉템 3가지, 혹은 일반 아이템 3가지를 구매한 유저 제외 
    SELECT distinct_id
    FROM events
    WHERE
      (
        event = 'collectem_purchase_detail' -- 컬렉템 구매 시 남는 이벤트 
        AND properties.eventCode = 'kitty_1001' -- 이벤트 코드 입력 
        AND (properties.itemID = 'HK_EFFECT_2' OR properties.itemID = 'HK_BTM_11' OR properties.itemID = 'HK_HEADWEAR_11')
      ) -- 아이템 아이디 입력 
      OR
      (
        event = 'item_purchase' -- 아이템 구매 시 남은 이벤트 
        AND timestamp >= '2024-05-07' -- 시작 기간 입력 
        AND (properties.id = 'HK_BAG_1' OR properties.id = 'HK_TOP_5' OR properties.id = 'HK_TOP_6')
      ) -- 아이템 아이디 입력 
  )
GROUP BY distinct_id

