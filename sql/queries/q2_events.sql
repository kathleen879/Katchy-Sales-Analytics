-- Q2: Which events make the most revenue and profit?
-- Profit = revenue - units sold x weighted average cost - partner share
SELECT e.name                                         AS event,
       e.start_date,
       COUNT(DISTINCT o.order_id)                     AS orders,
       SUM(oi.quantity * oi.unit_price)               AS revenue,
       ROUND(SUM(oi.quantity * c.avg_unit_cost), 2)   AS cost_of_goods,
       ROUND(SUM(oi.quantity * (oi.unit_price - c.avg_unit_cost)
                 * COALESCE(pa.share_pct, 0) / 100), 2) AS partner_share,
       ROUND(SUM(oi.quantity * (oi.unit_price - c.avg_unit_cost)
                 * (1 - COALESCE(pa.share_pct, 0) / 100)), 2) AS profit
FROM events e
JOIN orders o           USING (event_id)
JOIN order_items oi     USING (order_id)
JOIN products p         USING (product_id)
JOIN v_type_avg_cost c  USING (product_type_id)
LEFT JOIN partners pa   USING (partner_id)
GROUP BY e.event_id, e.name, e.start_date
ORDER BY profit DESC, revenue DESC;