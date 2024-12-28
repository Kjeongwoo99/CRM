SELECT event
       , country,
       , event_count,
       , rank() over (ORDER BY event_count DESC) AS country_rank, -- rank 지정
       , event_count * 100.0 / total_event_count AS percentage -- 퍼센트지로 계산
  FROM (
     SELCT event,
           , properties.$geoip_country_name AS country,
           , COUNT(*) AS event_count,
           , sum(COUNT(*)) over () AS total_event_count -- 지난 7일간의 total count 계산
      FROM events
     WHERE timestamp > now() - interval 7 day
       AND event = 'Application Opened'
     GROUP BY 
        event,
        properties.$geoip_country_name
  ) AS event_counts
ORDER BY event_count DESC
LIMIT 100
