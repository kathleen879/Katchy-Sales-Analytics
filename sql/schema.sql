-- Katchy Sales Analytics: database schema (Phase 5)
-- PostgreSQL. Run once on an empty database:  psql -U postgres -d katchy -f sql/schema.sql
-- Re-running drops and recreates every table, so do NOT run it on a database holding real data.

SET client_min_messages TO WARNING;   -- hide "does not exist, skipping" notices

DROP VIEW  IF EXISTS v_stock_levels, v_type_avg_cost CASCADE;
DROP TABLE IF EXISTS stock_movements, partner_payments, order_items, orders,
                     expenses, products, product_types, promotions, partners, events CASCADE;

-- ---------------------------------------------------------------------------
-- Reference tables
-- ---------------------------------------------------------------------------

-- Markets Katchy sells at.
CREATE TABLE events (
    event_id    SERIAL PRIMARY KEY,
    name        TEXT        NOT NULL,
    start_date  DATE,                                   -- NULL if not recorded
    num_days    SMALLINT    NOT NULL DEFAULT 1 CHECK (num_days >= 1),
    UNIQUE (name, start_date)
);

-- People who receive a share of profit on designs they contributed to.
CREATE TABLE partners (
    partner_id  SERIAL PRIMARY KEY,
    name        TEXT          NOT NULL UNIQUE,
    share_pct   NUMERIC(5,2)  NOT NULL CHECK (share_pct > 0 AND share_pct <= 100)  -- share of profit
);

-- Quantity-based promotions, e.g. sheets and prints are $2.00 each when 3+ are bought.
CREATE TABLE promotions (
    promotion_id      SERIAL PRIMARY KEY,
    name              TEXT          NOT NULL UNIQUE,
    min_quantity      SMALLINT      NOT NULL CHECK (min_quantity >= 2),
    discounted_price  NUMERIC(8,2)  NOT NULL CHECK (discounted_price >= 0)
);

-- Kinds of product. Price, promotion and average cost are set per type.
CREATE TABLE product_types (
    product_type_id  SERIAL PRIMARY KEY,
    name             TEXT          NOT NULL UNIQUE,     -- Sticker, Sticker Sheet, Print, Shirt, Pin
    list_price       NUMERIC(8,2)  NOT NULL CHECK (list_price >= 0),
    promotion_id     INT           REFERENCES promotions (promotion_id)  -- NULL = no promotion
);

-- Individual designs (the SKUs). Stock and design-level profit are tracked here.
CREATE TABLE products (
    product_id       SERIAL PRIMARY KEY,
    sku              TEXT      UNIQUE,                  -- Katchy's own code, e.g. SS1_Willow
    product_type_id  INT       NOT NULL REFERENCES product_types (product_type_id),
    design           TEXT      NOT NULL,                -- 'Design not recorded' for old sales
    variant          TEXT      NOT NULL DEFAULT '',     -- e.g. shirt size; '' if none
    partner_id       INT       REFERENCES partners (partner_id),         -- NULL = no partner share
    reorder_level    INT       NOT NULL DEFAULT 0 CHECK (reorder_level >= 0),
    is_active        BOOLEAN   NOT NULL DEFAULT TRUE,  -- FALSE = hidden from the sales form
                                                       -- (retired designs, 'Design not recorded')
    UNIQUE (product_type_id, design, variant)
);

-- ---------------------------------------------------------------------------
-- Sales
-- ---------------------------------------------------------------------------

-- One row per customer payment.
CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    event_id      INT          NOT NULL REFERENCES events (event_id),
    event_day     SMALLINT     NOT NULL DEFAULT 1 CHECK (event_day >= 1),
    payment_type  TEXT         CHECK (payment_type IN ('cash', 'paynow')),  -- NULL = not recorded
    ordered_at    TIMESTAMPTZ                                               -- NULL for old sales
);

-- One row per product within an order, with the unit price actually paid
-- (after any promotion), so revenue is always exact.
CREATE TABLE order_items (
    order_item_id  SERIAL PRIMARY KEY,
    order_id       INT           NOT NULL REFERENCES orders (order_id) ON DELETE CASCADE,
    product_id     INT           NOT NULL REFERENCES products (product_id),
    quantity       INT           NOT NULL CHECK (quantity > 0),
    unit_price     NUMERIC(8,2)  NOT NULL CHECK (unit_price >= 0),
    UNIQUE (order_id, product_id)
);

-- ---------------------------------------------------------------------------
-- Costs
-- ---------------------------------------------------------------------------

-- Every purchase. Product purchases link to a product type and feed the
-- weighted average cost; other categories are overhead.
CREATE TABLE expenses (
    expense_id       SERIAL PRIMARY KEY,
    purchase_year    SMALLINT       NOT NULL,
    purchase_date    DATE,                               -- NULL for old purchases (year only)
    item             TEXT           NOT NULL,
    category         TEXT           NOT NULL
                     CHECK (category IN ('product', 'packaging', 'display', 'delivery', 'tools')),
    product_type_id  INT            REFERENCES product_types (product_type_id),
    quantity         INT            CHECK (quantity > 0),
    total_cost       NUMERIC(10,2)  NOT NULL CHECK (total_cost >= 0),
    supplier         TEXT,
    notes            TEXT,
    CONSTRAINT expense_date_matches_year
        CHECK (purchase_date IS NULL OR EXTRACT(YEAR FROM purchase_date) = purchase_year),
    -- a cost linked to a product type must say how many units it bought
    CONSTRAINT product_expense_needs_quantity
        CHECK (product_type_id IS NULL OR quantity IS NOT NULL)
);

-- Money paid to partners (e.g. Summer's share).
CREATE TABLE partner_payments (
    payment_id    SERIAL PRIMARY KEY,
    partner_id    INT            NOT NULL REFERENCES partners (partner_id),
    event_id      INT            REFERENCES events (event_id),   -- event the payment covers, if any
    payment_date  DATE           NOT NULL,
    amount        NUMERIC(10,2)  NOT NULL CHECK (amount > 0)
);

-- ---------------------------------------------------------------------------
-- Stock
-- ---------------------------------------------------------------------------

-- Every change in stock EXCEPT sales (sales already live in order_items).
-- Positive = stock in, negative = stock out.
CREATE TABLE stock_movements (
    movement_id      SERIAL PRIMARY KEY,
    product_id       INT    NOT NULL REFERENCES products (product_id),
    movement_date    DATE   NOT NULL,
    quantity_change  INT    NOT NULL CHECK (quantity_change <> 0),
    reason           TEXT   NOT NULL
                     CHECK (reason IN ('opening_stock', 'restock', 'giveaway', 'marketing', 'adjustment')),
    notes            TEXT
);

-- ---------------------------------------------------------------------------
-- Indexes on foreign keys used in joins
-- ---------------------------------------------------------------------------

CREATE INDEX ON orders (event_id);
CREATE INDEX ON order_items (product_id);
CREATE INDEX ON products (product_type_id);
CREATE INDEX ON expenses (product_type_id);
CREATE INDEX ON stock_movements (product_id);

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------

-- Weighted average cost per product type: total cost of all batches / total units bought.
CREATE VIEW v_type_avg_cost AS
SELECT pt.product_type_id,
       pt.name                                        AS product_type,
       SUM(e.total_cost)                              AS total_cost,
       SUM(e.quantity)                                AS total_units,
       ROUND(SUM(e.total_cost) / SUM(e.quantity), 4)  AS avg_unit_cost
FROM product_types pt
JOIN expenses e ON e.product_type_id = pt.product_type_id
GROUP BY pt.product_type_id, pt.name;

-- Current stock per design: all stock movements minus all units sold.
CREATE VIEW v_stock_levels AS
SELECT p.product_id,
       p.sku,
       pt.name   AS product_type,
       p.design,
       p.variant,
       COALESCE(m.moved, 0) - COALESCE(s.sold, 0)  AS stock_on_hand,
       p.reorder_level,
       p.reorder_level > 0
         AND COALESCE(m.moved, 0) - COALESCE(s.sold, 0) <= p.reorder_level  AS needs_reprint
FROM products p
JOIN product_types pt USING (product_type_id)
LEFT JOIN (SELECT product_id, SUM(quantity_change) AS moved
           FROM stock_movements GROUP BY product_id) m USING (product_id)
LEFT JOIN (SELECT product_id, SUM(quantity) AS sold
           FROM order_items GROUP BY product_id) s USING (product_id)
WHERE p.is_active;