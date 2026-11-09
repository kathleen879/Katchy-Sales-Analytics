-- Q3: Does the second event day sell as well as the first?
-- One row per day of each multi-day event, with that day's share of the event's revenue.
SELECT e.name                                         AS event,
       o.event_day,
       COUNT(DISTINCT o.order_id)                     AS orders,
       SUM(oi.quantity * oi.unit_price)               AS revenue,
       ROUND(SUM(oi.quantity * (oi.unit_price - c.avg_unit_cost)
                 * (1 - COALESCE(pa.share_pct, 0) / 100)), 2) AS profit,
       -- window function: this day's revenue / the whole event's revenue
       ROUND(100.0 * SUM(oi.quantity * oi.unit_price)
             / SUM(SUM(oi.quantity * oi.unit_price)) OVER (PARTITION BY e.event_id), 1) AS pct_of_event_revenue
FROM events e
JOIN orders o           USING (event_id)
JOIN order_items oi     USING (order_id)
JOIN products p         USING (product_id)
JOIN v_type_avg_cost c  USING (product_type_id)
LEFT JOIN partners pa   USING (partner_id)
WHERE e.num_days > 1
GROUP BY e.event_id, e.name, e.start_date, o.event_day
ORDER BY e.start_date, o.event_day;