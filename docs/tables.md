# Sample Data

The first rows of every table and view in the `katchy` database, produced by [`sql/overview.sql`](../sql/overview.sql). See the [data model](data-model.md) for how the tables connect.

> **Privacy note:** costs, suppliers and partner payment amounts are shown as `xx`. Selling prices and quantities are real, since prices are public at the booth.

## Tables

### `events`

One row per market attended.

| event_id | name | start_date | num_days |
| --- | --- | --- | --- |
| 1 | New Beginnings | 2025-08-06 | 1 |
| 2 | Origin Market | 2025-09-10 | 2 |
| 3 | Back to School | 2026-09-09 | 2 |
| 4 | Nebula | 2026-10-08 | 1 |
| 5 | Creepy Craft Fair | 2026-10-28 | 3 |

### `orders`

One row per customer payment. `ordered_at` is empty for imported history; new sales from the app fill it in.

| order_id | event_id | event_day | payment_type | ordered_at |
| --- | --- | --- | --- | --- |
| 1 | 1 | 1 | cash | NULL |
| 2 | 1 | 1 | cash | NULL |
| 3 | 1 | 1 | paynow | NULL |
| 4 | 1 | 1 | paynow | NULL |
| 5 | 1 | 1 | paynow | NULL |

### `order_items`

One row per product within an order, with the unit price actually paid after any promotion.

| order_item_id | order_id | product_id | quantity | unit_price |
| --- | --- | --- | --- | --- |
| 1 | 1 | 30 | 1 | 1.50 |
| 2 | 2 | 30 | 1 | 1.50 |
| 3 | 3 | 40 | 1 | 16.00 |
| 4 | 4 | 39 | 2 | 2.50 |
| 5 | 4 | 30 | 3 | 1.00 |

### `products`

One row per design (and per size and colour for shirts), with Katchy's own SKU codes.

| product_id | sku | product_type_id | design | variant | partner_id | reorder_level | is_active |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | SS1_Willow | 1 | Willow |  | 1 | 0 | t |
| 2 | SS2_Fungus | 1 | Fungus |  | 1 | 0 | t |
| 3 | SS3_Jimmy | 1 | Jimmy |  | 1 | 0 | t |
| 4 | S4_Bestfriends1 | 1 | Bestfriends 1 |  | NULL | 0 | t |
| 5 | S5_Bestfriends2 | 1 | Bestfriends 2 |  | NULL | 0 | t |

### `product_types`

Price and promotion are set once per type.

| product_type_id | name | list_price | promotion_id |
| --- | --- | --- | --- |
| 1 | Sticker Sheet | 2.50 | 1 |
| 2 | Print | 2.50 | 1 |
| 3 | Sticker | 1.50 | 2 |
| 4 | Shirt | 16.00 | NULL |
| 5 | Pin | 1.50 | NULL |

### `promotions`

Quantity-based discounts.

| promotion_id | name | min_quantity | discounted_price |
| --- | --- | --- | --- |
| 1 | Sheets and prints, 3 or more | 3 | 2.00 |
| 2 | Stickers, 3 or more | 3 | 1.00 |

### `partners`

People who receive a share of profit on designs they contributed to.

| partner_id | name | share_pct |
| --- | --- | --- |
| 1 | Summer | 50.00 |

### `partner_payments`

Payments made to partners.

| payment_id | partner_id | event_id | payment_date | amount |
| --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 2025-08-06 | xx |
| 2 | 1 | 2 | 2025-09-11 | xx |
| 3 | 1 | 3 | 2026-09-10 | xx |
| 4 | 1 | 4 | 2026-10-08 | xx |
| 5 | 1 | 5 | 2026-10-30 | xx |

### `expenses`

Every purchase. Product purchases link to a product type and feed the weighted average cost.

| expense_id | purchase_year | purchase_date | item | category | product_type_id | quantity | total_cost | supplier | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 2025 | NULL | Plastic Container | display | NULL | NULL | xx | xx | NULL |
| 2 | 2025 | NULL | Plastic Packaging | packaging | NULL | NULL | xx | xx | xx |
| 3 | 2025 | NULL | Cardboard Packaging | packaging | NULL | NULL | xx | xx | xx |
| 4 | 2025 | NULL | Prints (Drink, Cat, Shark x20 each) | product | 2 | 60 | xx | xx | xx |
| 5 | 2025 | NULL | Sticker backings 8cm x 12cm | packaging | NULL | 100 | xx | xx | xx |

### `stock_movements`

Every stock change other than a sale.

*No rows yet. Stock movements start with the first physical stock count.*

| movement_id | product_id | movement_date | quantity_change | reason | notes |
| --- | --- | --- | --- | --- | --- |

---

## Views

### `v_type_avg_cost`

Weighted average cost per product type: total cost of all batches ÷ total units bought.

| product_type_id | product_type | total_cost | total_units | avg_unit_cost |
| --- | --- | --- | --- | --- |
| 5 | Pin | xx | 20 | xx |
| 4 | Shirt | xx | 44 | xx |
| 2 | Print | xx | 110 | xx |
| 1 | Sticker Sheet | xx | 380 | xx |
| 3 | Sticker | xx | 790 | xx |

### `v_stock_levels`

Current stock per design: stock movements − units sold.

| product_id | sku | product_type | design | variant | stock_on_hand | reorder_level | needs_reprint |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | SS1_Willow | Sticker Sheet | Willow |  | -5 | 0 | f |
| 2 | SS2_Fungus | Sticker Sheet | Fungus |  | -4 | 0 | f |
| 3 | SS3_Jimmy | Sticker Sheet | Jimmy |  | -6 | 0 | f |
| 4 | S4_Bestfriends1 | Sticker Sheet | Bestfriends 1 |  | 0 | 0 | f |
| 5 | S5_Bestfriends2 | Sticker Sheet | Bestfriends 2 |  | 0 | 0 | f |
| 6 | S6_OceanWonders | Sticker Sheet | Ocean Wonders |  | -1 | 0 | f |
| 7 | S7_Cats | Sticker Sheet | Cats |  | 0 | 0 | f |
| 8 | S8_Spongebob | Sticker Sheet | Spongebob |  | 0 | 0 | f |
| 9 | S9_Minion | Sticker Sheet | Minion |  | 0 | 0 | f |
| 10 | S10_Pikmin | Sticker Sheet | Pikmin |  | 0 | 0 | f |

Stock shows as negative or zero until the first physical stock count is recorded: the view subtracts imported sales from a starting stock of 0.