-- Katchy Sales Analytics: product catalogue (Phase 5)
-- Run after schema.sql:  psql -U postgres -d katchy -f sql/seed.sql
-- Fills partners, promotions, product types and products. Sales and expenses are loaded separately.

BEGIN;

-- ---------------------------------------------------------------------------
-- Partners
-- ---------------------------------------------------------------------------

INSERT INTO partners (name, share_pct) VALUES
    ('Summer', 50);                        -- 50% of profit on her cat designs (SS codes)

-- ---------------------------------------------------------------------------
-- Promotions
-- ---------------------------------------------------------------------------

INSERT INTO promotions (name, min_quantity, discounted_price) VALUES
    ('Sheets and prints, 3 or more', 3, 2.00),   -- sheets and prints count together
    ('Stickers, 3 or more',          3, 1.00);

-- ---------------------------------------------------------------------------
-- Product types: price and promotion are set here
-- ---------------------------------------------------------------------------

INSERT INTO product_types (name, list_price, promotion_id) VALUES
    ('Sticker Sheet', 2.50, (SELECT promotion_id FROM promotions WHERE name = 'Sheets and prints, 3 or more')),
    ('Print',         2.50, (SELECT promotion_id FROM promotions WHERE name = 'Sheets and prints, 3 or more')),
    ('Sticker',       1.50, (SELECT promotion_id FROM promotions WHERE name = 'Stickers, 3 or more')),
    ('Shirt',        16.00, NULL),
    ('Pin',           1.50, NULL);

-- ---------------------------------------------------------------------------
-- Products
-- reorder_level 0 = no reprint alert yet; set real levels once stock is counted.
-- ---------------------------------------------------------------------------

-- Sticker sheets: tracked per design. SS codes feature Summer's cats.
INSERT INTO products (sku, product_type_id, design, partner_id)
SELECT v.sku,
       (SELECT product_type_id FROM product_types WHERE name = 'Sticker Sheet'),
       v.design,
       CASE WHEN v.sku LIKE 'SS%' THEN (SELECT partner_id FROM partners WHERE name = 'Summer') END
FROM (VALUES
    ('SS1_Willow',       'Willow'),
    ('SS2_Fungus',       'Fungus'),
    ('SS3_Jimmy',        'Jimmy'),
    ('S4_Bestfriends1',  'Bestfriends 1'),
    ('S5_Bestfriends2',  'Bestfriends 2'),
    ('S6_OceanWonders',  'Ocean Wonders'),
    ('S7_Cats',          'Cats'),
    ('S8_Spongebob',     'Spongebob'),
    ('S9_Minion',        'Minion'),
    ('S10_Pikmin',       'Pikmin'),
    ('S11_Borzoi',       'Borzoi'),
    ('S12_Catfish',      'Catfish'),
    ('S13_Sloth',        'Sloth')
) AS v (sku, design);

-- Shirts: tracked per design, colour and size (2 x 2 x 4 = 16 variants).
-- SKU pattern: T<design number>_<design>_<colour>_<size>, e.g. T1_Catfish_White_S
INSERT INTO products (sku, product_type_id, design, variant)
SELECT 'T' || d.num || '_' || d.design || '_' || c.colour || '_' || s.size,
       (SELECT product_type_id FROM product_types WHERE name = 'Shirt'),
       d.design,
       c.colour || ' ' || s.size
FROM (VALUES (1, 'Catfish'), (2, 'Flower'))         AS d (num, design)
CROSS JOIN (VALUES ('White'), ('Black'))            AS c (colour)
CROSS JOIN (VALUES (1,'S'), (2,'M'), (3,'L'), (4,'XL')) AS s (ord, size)
ORDER BY d.num, c.colour DESC, s.ord;

-- Stickers: all designs treated as one product.
INSERT INTO products (product_type_id, design) VALUES
    ((SELECT product_type_id FROM product_types WHERE name = 'Sticker'), 'All designs');

-- Prints: tracked per design.
INSERT INTO products (sku, product_type_id, design)
SELECT v.sku,
       (SELECT product_type_id FROM product_types WHERE name = 'Print'),
       v.design
FROM (VALUES
    ('P1_Shark',   'Shark'),
    ('P2_Drink',   'Drink'),
    ('P3_Cat',     'Cat I Wish'),
    ('P4_Borzoi',  'Borzoi'),
    ('P5_Giraffe', 'Giraffe'),
    ('P6_Cat',     'Cat Star')
) AS v (sku, design);

-- Pins: all designs treated as one product.
INSERT INTO products (product_type_id, design) VALUES
    ((SELECT product_type_id FROM product_types WHERE name = 'Pin'), 'All designs');

-- Placeholders for old sales that didn't record the design or size.
-- Inactive, so they never appear in the sales form.
INSERT INTO products (product_type_id, design, is_active) VALUES
    ((SELECT product_type_id FROM product_types WHERE name = 'Sticker Sheet'), 'Design not recorded', FALSE),
    ((SELECT product_type_id FROM product_types WHERE name = 'Print'),         'Design not recorded', FALSE),
    ((SELECT product_type_id FROM product_types WHERE name = 'Shirt'),         'Design not recorded', FALSE);

COMMIT;
