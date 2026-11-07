# Business Questions

This document covers Phase 4: the questions the new system has to answer. Each question becomes one SQL query and one chart on the dashboard, and the data each one needs decides what the database stores (Phase 5).

| # | Question | Helps decide | Chart |
| --- | --- | --- | --- |
| 1 | Which products and designs make the most profit? | What to print more of | Bar chart |
| 2 | Which events make the most revenue and profit? | Which markets to apply for again | Grouped bar chart |
| 3 | Does the second event day sell as well as the first? | Whether two-day markets are worth it | Grouped bar chart |
| 4 | How often do customers reach the 3-item promotion? | Whether the promotion is worth its discount | Percentage + bar chart |
| 5 | What is the average order value, and what is bought together? | Bundles and booth layout | Number + table |
| 6 | How much is owed to Summer per event and in total? | Paying her accurately | Table |
| 7 | When should each design be reprinted? | Reprint timing | Bar chart with reorder line |

---

### Question 1: Which products and designs make the most profit?

**Why it matters:** the best seller isn't always the most profitable. This shows which designs earn the most for each reprint.

**Calculation:** profit = quantity × (price paid − weighted average cost). For Summer's cat designs, her 50% share is subtracted.

**Data needed:** line items (product, quantity, price paid), products (type, design), purchase batches (for average cost), partner share.

**Chart:** horizontal bar chart of profit by product, with a filter to switch between product types and individual designs.

### Question 2: Which events make the most revenue and profit?

**Why it matters:** booth slots are limited. Comparing events shows which markets to apply for again.

**Data needed:** orders (event), line items, average costs.

**Chart:** grouped bar chart of revenue and profit per event, in date order.

### Question 3: Does the second event day sell as well as the first?

**Why it matters:** a weak second day may mean a one-day market, or a one-day slot, is the better choice.

**Data needed:** orders (event, event day), line items.

**Chart:** grouped bar chart of revenue per day for each multi-day event.

### Question 4: How often do customers reach the 3-item promotion?

**Why it matters:** the promotion lowers the price per item. It is only worth it if it makes customers buy more.

**Calculation:** share of orders with 3 or more items from the same promotion group, and the discount given = list price − price paid, summed over those items.

**Data needed:** line items (price paid), products (list price, promotion group), promotions (minimum quantity, discounted price).

**Chart:** percentage of orders reaching the promotion, and a bar chart of the number of items per order.

### Question 5: What is the average order value, and what is bought together?

**Why it matters:** a higher average order value means more revenue from the same number of customers. Products often bought together can be placed side by side or bundled.

**Calculation:** average order value = total revenue ÷ number of orders. Pairs are counted from orders that contain both products.

**Data needed:** orders, line items (product).

**Chart:** average order value per event, and a table of the most common product pairs.

### Question 6: How much is owed to Summer per event and in total?

**Why it matters:** her share is currently worked out by hand from free-text notes, so it's easy to get wrong.

**Calculation:** 50% × profit on her three cat designs sold, minus payments already made.

**Data needed:** products (partner), partners (share percentage), line items, payments to partners.

**Chart:** table per event showing cat sheets sold, profit, her share, amount paid and balance owed.

### Question 7: When should each design be reprinted?

**Why it matters:** running out at a market means lost sales; over-printing ties up money in stock.

**Calculation:** current stock = units bought − units sold − units given away. A design needs reprinting when its stock falls below its reorder level.

**Data needed:** stock movements (purchases, sales, adjustments), products (reorder level).

**Chart:** bar chart of current stock per design, with each design's reorder level marked and low-stock designs highlighted.

---

## Data needed, by table

This summary feeds directly into the database design in Phase 5.

| Table | Columns the questions need | Used by |
| --- | --- | --- |
| `events` | name, date | 2, 3, 5 |
| `orders` | event, event day, payment type | 2, 3, 4, 5 |
| `order_items` | order, product, quantity, price paid | 1–6 |
| `products` | type, design, list price, promotion group, partner, reorder level | 1, 4, 6, 7 |
| `promotions` | promotion group, minimum quantity, discounted price | 4 |
| `product_costs` | product, quantity, total cost | 1, 2, 6 |
| `partners` | name, share percentage | 1, 6 |
| `partner_payments` | partner, date, amount | 6 |
| `stock_movements` | product, date, quantity change, reason | 7 |

## Limitation of the historical data

Past transactions mostly record the product type ("3 sticker sheets"), not the design. So questions 1 and 7 can be answered by design only for sales recorded in the new system. For older events, they are answered by product type.