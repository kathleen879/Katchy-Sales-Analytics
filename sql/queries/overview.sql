SELECT * FROM events           ORDER BY event_id      LIMIT 5;
SELECT * FROM orders           ORDER BY order_id      LIMIT 5;
SELECT * FROM order_items      ORDER BY order_item_id LIMIT 5;
SELECT * FROM products         ORDER BY product_id    LIMIT 5;
SELECT * FROM product_types    ORDER BY product_type_id LIMIT 5;
SELECT * FROM promotions       ORDER BY promotion_id  LIMIT 5;
SELECT * FROM partners         ORDER BY partner_id    LIMIT 5;
SELECT * FROM partner_payments ORDER BY payment_id    LIMIT 5;
SELECT * FROM expenses         ORDER BY expense_id    LIMIT 5;
SELECT * FROM stock_movements  ORDER BY movement_id   LIMIT 5;

-- The two views
SELECT * FROM v_type_avg_cost;
SELECT * FROM v_stock_levels   ORDER BY product_id    LIMIT 10;