-- 1차 CRM 대상자: 지난 한달간 헤드웨어 위시리스트 추가 유저 (헬로키티 리워드 소유 유저 제외)

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


-- 특정 브랜드 아이템 구매 유저 
    
SELECT DISTINCT distinct_id,
    CASE --- 언어 설정을 위한 CASE 절  
      WHEN argMax(properties.$geoip_country_name, timestamp) = 'South Korea' THEN 'KR' -- 유저의 마지막 접속 지역이 'South Korea'일 경우 'KR'로 분류
      WHEN argMax(properties.$geoip_country_name, timestamp) = 'Japan' THEN 'JP' -- 유저의 마지막 접속 지역이 'Japan'일 경우 'JP'로 분류
      ELSE 'EN' -- 그 외 지역은 'EN'으로 분류
    END AS language
 FROM events
WHERE event = 'item_purchase' -- 아이템 구매시 남는 이벤트 
  AND timestamp >= '2023-01-01 00:00:00' -- timestamp로 기간 설정 -> 제타에서는 2023년 9월부터 데이터가 쌓이기 시작했기 때문에 2023년 9월 1일 이후로 필터
  AND (properties.brands IN ('["itzy"]')) -- itzy 브랜드 아이템
  AND properties.isBrand = true -- 브랜드 아이템인지 확인
  AND properties.cashType = 'ZEM' -- 'ZEM' 캐시 타입으로 구매한 유저
  AND (length(distinct_id) = 24 AND length(person.properties.$app_version) > 0) -- 잘못된 형식의 유저 서포트 값 제외 (distinct_id의 길이가 24이고, person.properties.$app_version의 길이가 0보다 큰 유저 필터링)
GROUP BY distinct_id

-- 특정 브랜드 아이템 입어본 유저, 중복 제거 

WITH crown_users AS ( -- '중복 유저 제거'를 위한 WITH절 생성하고 이름을 'crown_users' 로 부여 -> 왕관 아이템 구매 유저 제외 
  SELECT DISTINCT distinct_id
    FROM events
   WHERE event = 'item_purchase' -- 아이템 구매시 남는 이벤트
    AND timestamp >= '2024-04-30' -- timestamp로 기간 설정 -> 최근 6개월로 필터 
    AND properties.cashType = 'ZEM' -- 'ZEM' 캐시 타입으로 구매한 유저
    AND toFloat(properties.price) >= 0 -- 젬 가격 0이상 
    AND (properties.itemType = 'General' OR properties.itemType = 'Creator') -- 일반, 크리에이터 아이템만 필터링 (월드/라이브 제외)
    AND properties.tags LIKE ('["%crown%"]') -- 아이템 태그에 CROWN이 포함된 경우 
),

iap_revenue AS ( -- '중복 유저 제거'를 위한 두번째 코드 블록, 이름을 'iap_revenue' 로 부여 -> 인입결제
  SELECT distinct_id
         , sum(toFloat(properties.priceTier)) AS total_purchases -- 유저의 총 구매 금액을 다 더해주는 함수 
    FROM events
   WHERE (timestamp >= '2024-09-01' AND timestamp < '2024-10-01') -- timestamp로 9월 한 달 기준으로 설정 
     AND event = 'in_app_purchase' -- 인앱결제시 남는 이벤트 
   GROUP BY distinct_id
)

SELECT distinct_id
       , CASE
            WHEN argMax(properties.$geoip_country_name, timestamp) = 'South Korea' THEN 'KR' -- 유저의 마지막 접속 지역이 'South Korea'이면 'KR'로 분류
            WHEN argMax(properties.$geoip_country_name, timestamp) = 'Japan' THEN 'JP' -- 유저의 마지막 접속 지역이 'Japan'이면 'JP'로 분류
            ELSE 'EN' -- 그 외의 국가는 'EN'으로 분류
          END AS language
  FROM events
 WHERE event = 'item_wear' -- 아이템 착용 시 남는 이벤트 
  AND timestamp >= '2024-09-30' -- 최근 한 달 기준 - 2024년 9월 30일 이후의 유저를 필터링
  AND properties.brands IN ('["itzy"]') -- 'itzy' 브랜드 아이템을 착용한 유저를 필터링
  AND distinct_id NOT IN (
        SELECT distinct_id 
          FROM crown_users -- 'crown_users'에서 이미 선택된 유저를 제외 -> 왕관 아이템 착용 유저 제외 
    )
  AND distinct_id NOT IN (
        SELECT distinct_id 
          FROM iap_revenue WHERE total_purchases >= 3.99 -- 'iap_revenue'에서 총 구매 금액이 3.99달러 이상인 유저를 제외
    )
  AND distinct_id NOT IN ( -- 있지 컬렉템 페이지 접속한 유저 제외 
        SELECT distinct_id
          FROM events
         WHERE event = 'collectem_enter' -- 컬렉템 이벤트 페이지 접속시 남는 이벤트 코드 
           AND properties.eventCode = 'itzy' -- 있지 컬렉템 
           AND timestamp >= '2024-10-18' -- 있지 컬렉템 오픈일인 10/18일 이후 
    )
  AND (length(distinct_id) = 24 AND length(person.properties.$app_version) > 0) -- 잘못된 형식의 유저 서포트 값 제외 (distinct_id의 길이가 24이고, person.properties.$app_version의 길이가 0보다 큰 유저 필터링)
GROUP BY distinct_id

-- 월 인앱결제 기준 일정 금액 이상 결제 유저 

WITH iap_revenue AS ( -- '중복 유저 제거'를 위한 WITH절 생성하고 이름을 'iap_revenue' 로 부여 -> 인입결제
  SELECT distinct_id
         , sum(toFloat(properties.priceTier)) AS total_purchases -- 유저의 총 구매 금액을 다 더해주는 함수
         , argMax(properties.$geoip_country_name, timestamp) AS country -- 나라 별로 유저 구분을 위한 함수 
    FROM events
   WHERE (timestamp >= '2024-09-01' -- 시작 기간 입력 AND timestamp < '2024-10-01') -- 종료 기간 입력 -> 최근 한달 기준으로 필터
     AND event = 'in_app_purchase' -- 인앱결제시 남는 이벤트
     AND (length(distinct_id) = 24 AND length(person.properties.$app_version) > 0) -- 잘못된 형식의 유저 서포트 값 제외 (distinct_id의 길이가 24이고, person.properties.$app_version의 길이가 0보다 큰 유저 필터링)
   GROUP BY distinct_id
    ),
crown_users AS ( -- '중복 유저 제거'를 위한 두번째 코드 블록, 이름을 'crown_users' 로 부여 -> 왕관 아이템 구매 유저 제외 
  SELECT DISTINCT distinct_id
    FROM events
   WHERE event = 'item_purchase' -- 아이템 구매시 남는 이벤트
    AND timestamp >= '2024-04-30' -- timestamp로 기간 설정 -> 최근 6개월로 필터 
    AND properties.cashType = 'ZEM' -- 'ZEM' 캐시 타입으로 구매한 유저
    AND toFloat(properties.price) >= 0 -- 젬 가격 0 이상 
    AND (properties.itemType = 'General' OR properties.itemType = 'Creator') -- 일반, 크리에이터 아이템만 필터링 (월드/라이브 제외)
    AND properties.tags LIKE ('["%crown%"]') -- 아이템 태그에 CROWN이 포함된 경우
    )
SELECT distinct_id
       , CASE
             WHEN country = 'South Korea' THEN 'KR' -- 유저의 마지막 접속 지역이 'South Korea'이면 'KR'로 분류
             WHEN country = 'Japan' THEN 'JP' -- 유저의 마지막 접속 지역이 'Japan'이면 'JP'로 분류
             ELSE 'EN' -- 그 외의 국가는 'EN'으로 분류
          END AS Language
  FROM iap_revenue
 WHERE total_purchases >= 3.99 -- 'iap_revenue'에서 총 구매 금액이 3.99달러 이상인 유저를 제외
   AND distinct_id NOT IN (
            SELECT distinct_id 
              FROM crown_users
        ) -- 'crown_users'에서 이미 선택된 유저를 제외 -> 왕관 아이템 착용 유저 제외 
   AND distinct_id IN ( -- 있지 컬렉템 페이지 접속한 유저 제외 
            SELECT distinct_id
              FROM events
             WHERE event = 'collectem_enter' -- 컬렉템 이벤트 페이지 접속시 남는 이벤트 코드 
               AND properties.eventCode = 'itzy' -- 있지 컬렉템
               AND timestamp >= '2024-10-18' -- 있지 컬렉템 오픈일인 10/18일 이후 
        )

-- 기존 컬렉템 BU 

WITH crm_bu AS ( -- WITH절을 사용하여 기존에 컬렉템 구매를 한 유저를 필터 
       SELECT distinct_id
              , argMax(properties.$geoip_country_name, timestamp) AS country -- 유저의 마지막 접속 지역을 가져오는 함수
         FROM events
        WHERE (length(distinct_id) = 24 AND length(person.properties.$app_version) > 0) -- 잘못된 형식의 유저 서포트 값 제외 (distinct_id의 길이가 24이고, person.properties.$app_version의 길이가 0보다 큰 유저 필터링)
         AND (
             (event = 'collectem_purchase' -- 컬렉템 구매시 남는 이벤트 
              AND timestamp >= '2024-07-01 16:00:00' -- 시작 시간 입력 
              AND timestamp < '2024-08-05 00:00:00' -- 종료 기간 입력 
              AND properties.eventCode = 'KUROMI' -- 쿠로미 컬렉템 
              AND properties.zemAmount > 0) -- 'collectem_purchase' 이벤트에서 zemAmount가 0보다 큰 유저를 필터링
              OR
              (event = 'collectem_purchase'
              AND timestamp >= '2024-02-27 16:00:00' -- 시작 시간 입력 
              AND timestamp < '2024-04-01 00:00:00' -- 종료 기간 입력 
              AND properties.eventCode = 'rilakkuma_0215' -- 리락쿠마 컬렉템
              AND properties.zemAmount > 0) -- 'collectem_purchase' 이벤트에서 zemAmount가 0보다 큰 유저를 필터링
              OR
              (event = 'collectem_purchase'
              AND timestamp >= '2024-08-16' -- 시작 시간 입력 
              AND timestamp < '2024-09-19 00:00:00' -- 종료 기간 입력 
              AND properties.eventCode = 'aespa' -- 에스파 컬렉템
              AND properties.zemAmount > 0) -- 'collectem_purchase' 이벤트에서 zemAmount가 0보다 큰 유저를 필터링
              OR
              (event = 'collectem_purchase'
              AND timestamp >= '2024-08-30 16:00:00' -- 시작 시간 입력 
              AND properties.eventCode = 'mickyandfriends_0830' -- 베이비미키 컬렉템
              AND properties.zemAmount > 0) -- 'collectem_purchase' 이벤트에서 zemAmount가 0보다 큰 유저를 필터링
              OR
              (event = 'collectem_purchase'
              AND timestamp >= '2024-10-01' -- 시작 시간 입력 
              AND properties.eventCode = 'kitty_1001' -- 헬로키티 컬렉템
              AND properties.zemAmount > 0) -- 'collectem_purchase' 이벤트에서 zemAmount가 0보다 큰 유저를 필터링
              )
       GROUP BY distinct_id
       )
SELECT DISTINCT distinct_id
       , CASE WHEN country = 'South Korea' THEN 'KR' -- 유저의 마지막 접속 지역이 'South Korea'이면 'KR'로 분류
              WHEN country = 'Japan' THEN 'JP' -- 유저의 마지막 접속 지역이 'Japan'이면 'JP'로 분류
              ELSE 'EN' -- 그 외의 국가는 'EN'으로 분류
          END AS Language
FROM crm_bu
