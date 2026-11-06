# Solutions

This document covers Phase 3: how the new system fixes each problem from the [current procedure](current-procedure.md). Solution numbers match the problem numbers.

The core idea behind every solution is the same: **record each fact once, in a structured database, and calculate everything else from it.** Totals, profit and stock are never typed in by hand again.

| # | Problem | Solution | Built with |
| --- | --- | --- | --- |
| 1 | Sales recorded as free text | One row per product per sale, with the promotion price applied | `orders`, `order_items` tables |
| 2 | Same thing written different ways | Fixed product list with IDs | `products`, `promotions` tables, dropdowns |
| 3 | Event tabs and Total Sales don't agree | Summaries calculated by queries, not retyped | SQL views |
| 4 | Summer's share calculated by hand | Cat designs tagged, share calculated automatically | `partners` table, payout query |
| 5 | Fixed unit costs | Weighted average cost from real purchases | `product_costs` table, average-cost query |
| 6 | Costs not linked to products | Purchases linked to the product they were for | `product_id` on expenses |
| 7 | No stock tracking | Stock calculated from purchases and sales | `stock_movements` table |

---

### Solution 1: Record each product in a sale as its own row

**Each sale is split into an order and its line items.** An order holds the date, event, event day and payment type. Each line item holds one product, its quantity and the unit price actually paid.

Recording every transaction matters because **the price of an item depends on how many are bought in the same order**:

| Product | 1–2 in an order | 3 or more in an order |
| --- | --- | --- |
| Sticker sheet or print (combined) | $2.50 each | $2.00 each |
| Sticker | $1.50 each | $1.00 each |

**Example:** "2 sticker sheets, 1 print" is three items from the same group, so each is $2.00 and the order totals $6.00. "2 sticker sheets" alone is $2.50 each, $5.00 in total. The entry form applies this rule automatically from the quantities entered.

**Result:** revenue is exact because it uses the price paid, not the list price. Quantities per product, per event or per day come straight from a query, and questions like "what is bought together" or "how often do customers reach the promotion" become possible.

### Solution 2: Use one fixed list of products

**Every product, design and promotion is stored once, with its own ID.** A promotion records which products it covers, the minimum quantity and the discounted price, so the rule in Solution 1 can change without changing any code. The sales entry form uses dropdowns from this list, so names can't be typed differently.

**Example:** "sticker sheet", "Sticker Sheets" and "3 sticker sheet" all become the product *Sticker Sheet*, with quantity stored separately.

**Result:** grouping by product always works, and a price or promotion is changed in one place only.

### Solution 3: Calculate summaries instead of retyping them

**The Total Sales view is a SQL query over the sales data**, not a separate sheet. The price list lives in the database, not in every event tab.

**Example:** event revenue is always `SUM(quantity × price)` over that event's line items, so the summary and the transactions can't disagree.

**Result:** one source of truth. Adding a sale updates every summary instantly.

### Solution 4: Calculate Summer's share automatically

**Each sticker sheet design is a separate product, and the three cat designs are linked to Summer with a 50% profit share.** Payments made to her are recorded too.

**Example:** after an event, a query lists the cat sheets sold, the profit on them, and Summer's 50%.

**Result:** her share is always accurate, and there is a running total of what she has been owed and paid.

### Solution 5: Use weighted average cost per product

**Each purchase batch is still recorded with its quantity and total cost, but profit uses one average cost per product:** total cost of all batches ÷ total units bought. Sold units from different suppliers can't be told apart, so this avoids guessing which batch each sale came from.

**Example:** 100 sheets at $0.40 and 50 sheets at $0.60 give an average of $70 ÷ 150 = $0.467 per sheet.

**Result:** profit uses a cost based on real purchases instead of a fixed number typed into a price list, and the average updates automatically when a new batch is added.

### Solution 6: Link purchases to products

**Each expense can optionally point to the product it was for.** General costs, like tools, are left unlinked and counted as overhead.

**Example:** a print run is linked to *Prints*, so its cost counts toward that product line.

**Result:** the true cost and profit of each product line can be calculated.

### Solution 7: Track stock from purchases and sales

**Every change in stock is recorded as a movement:** a purchase adds stock, a sale removes it, and giveaways or units kept for marketing are recorded as adjustments.

**Example:** stock of a sticker sheet design = sheets printed − sheets sold − sheets given away.

**Result:** current stock is always known, and a low-stock alert shows when a design needs reprinting.