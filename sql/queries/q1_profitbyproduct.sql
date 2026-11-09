-- Q1: Which products and designs make the most profit?
-- Profit = revenue - units sold x weighted average cost - partner share
SELECT pt.name                                        AS product_type,
       p.design,
       p.variant,
       SUM(oi.quantity)                               AS units_sold,
       SUM(oi.quantity * oi.unit_price)               AS revenue,
       ROUND(SUM(oi.quantity * c.avg_unit_cost), 2)   AS cost_of_goods,
       ROUND(SUM(oi.quantity * (oi.unit_price - c.avg_unit_cost)
                 * COALESCE(pa.share_pct, 0) / 100), 2) AS partner_share,
       ROUND(SUM(oi.quantity * (oi.unit_price - c.avg_unit_cost)
                 * (1 - COALESCE(pa.share_pct, 0) / 100)), 2) AS profit
FROM products p
JOIN product_types pt   USING (product_type_id)
JOIN order_items oi     USING (product_id)
JOIN v_type_avg_cost c  USING (product_type_id)
LEFT JOIN partners pa   USING (partner_id)
GROUP BY p.product_id, pt.name, p.design, p.variant
ORDER BY profit DESC;