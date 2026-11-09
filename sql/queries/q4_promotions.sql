-- Q4: How often do customers reach the 3-item promotion?
-- Step 1 (CTE): one row per order per promotion group, with items bought and discount given.
WITH order_groups AS (
    SELECT o.order_id,
           pt.promotion_id,
           SUM(oi.quantity)                                AS items,
           SUM(oi.quantity * (pt.list_price - oi.unit_price)) AS discount
    FROM orders o
    JOIN order_items oi    USING (order_id)
    JOIN products p        USING (product_id)
    JOIN product_types pt  USING (product_type_id)
    WHERE pt.promotion_id IS NOT NULL
    GROUP BY o.order_id, pt.promotion_id
)
-- Step 2: summarise per promotion.
SELECT pr.name                                                        AS promotion,
       COUNT(*)                                                       AS orders_with_these_items,
       COUNT(*) FILTER (WHERE og.items >= pr.min_quantity)            AS orders_reaching_promotion,
       ROUND(100.0 * COUNT(*) FILTER (WHERE og.items >= pr.min_quantity) / COUNT(*), 1) AS pct_reaching,
       ROUND(AVG(og.items), 2)                                        AS avg_items_per_order,
       SUM(og.discount)                                               AS discount_given
FROM order_groups og
JOIN promotions pr USING (promotion_id)
GROUP BY pr.promotion_id, pr.name
ORDER BY pr.promotion_id;

-- Q4b: how many orders bought 1, 2, 3... items from each promotion group (for the bar chart).
WITH order_groups AS (
    SELECT o.order_id, pt.promotion_id, SUM(oi.quantity) AS items
    FROM orders o
    JOIN order_items oi    USING (order_id)
    JOIN products p        USING (product_id)
    JOIN product_types pt  USING (product_type_id)
    WHERE pt.promotion_id IS NOT NULL
    GROUP BY o.order_id, pt.promotion_id
)
SELECT pr.name AS promotion, og.items, COUNT(*) AS orders
FROM order_groups og
JOIN promotions pr USING (promotion_id)
GROUP BY pr.promotion_id, pr.name, og.items
ORDER BY pr.promotion_id, og.items;