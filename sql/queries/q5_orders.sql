-- Q5a: What is the average order value per event?
SELECT e.name                                                          AS event,
       COUNT(DISTINCT o.order_id)                                      AS orders,
       SUM(oi.quantity * oi.unit_price)                                AS revenue,
       ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
       ROUND(SUM(oi.quantity)::numeric / COUNT(DISTINCT o.order_id), 2)        AS avg_items_per_order
FROM events e
JOIN orders o       USING (event_id)
JOIN order_items oi USING (order_id)
GROUP BY e.event_id, e.name, e.start_date
ORDER BY e.start_date;

-- Q5b: Which product types are bought together?
-- Self-join: pair each line item with every other line item in the same order.
-- ta.product_type_id < tb.product_type_id keeps each pair once (A+B, never also B+A)
-- and skips pairs of the same type.
SELECT ta.name                       AS product_a,
       tb.name                       AS product_b,
       COUNT(DISTINCT a.order_id)    AS orders_together
FROM order_items a
JOIN order_items b      ON b.order_id = a.order_id
JOIN products pa        ON pa.product_id = a.product_id
JOIN products pb        ON pb.product_id = b.product_id
JOIN product_types ta   ON ta.product_type_id = pa.product_type_id
JOIN product_types tb   ON tb.product_type_id = pb.product_type_id
WHERE ta.product_type_id < tb.product_type_id
GROUP BY ta.name, tb.name
ORDER BY orders_together DESC;