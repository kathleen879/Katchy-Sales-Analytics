-- Q7: When should each design be reprinted?
-- avg_sold_per_event: units sold / number of events so far
-- events_of_stock_left: how many more markets the current stock lasts at that rate
WITH rate AS (
    SELECT product_id,
           SUM(quantity)::numeric / (SELECT COUNT(*) FROM events) AS avg_per_event
    FROM order_items
    GROUP BY product_id
)
SELECT s.sku,
       s.product_type,
       s.design,
       s.variant,
       s.stock_on_hand,
       s.reorder_level,
       s.needs_reprint,
       ROUND(COALESCE(r.avg_per_event, 0), 1)                         AS avg_sold_per_event,
       CASE WHEN r.avg_per_event > 0
            THEN ROUND(s.stock_on_hand / r.avg_per_event, 1) END      AS events_of_stock_left
FROM v_stock_levels s
LEFT JOIN rate r USING (product_id)
WHERE s.product_type IN ('Sticker Sheet', 'Print', 'Shirt')        -- the types tracked per design
ORDER BY s.needs_reprint DESC, events_of_stock_left NULLS LAST, s.stock_on_hand,
         s.product_type, s.sku;                                     -- tie-breakers keep the order stable