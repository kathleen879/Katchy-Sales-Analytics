# Business Concepts Learnt

This project required learning how a small retail business actually records, prices and measures its sales, beyond the data science and analytics side. This page lists those concepts and where each one shows up in the project.

> Cost figures on this page are illustrative, not Katchy's real costs.

---

## Point of sale (POS)

### Transactions and line items

A **transaction** (order) is one customer paying once. A **line item** is one product within it, with its own quantity and price. POS systems store these separately so every product sold can be counted.

**In this project:** the old tracker wrote whole orders as free text ("3 stickers, 1 print"). The new database splits them into `orders` and `order_items` (Solution 1).

### SKU (stock keeping unit)

A **SKU** is a unique ID for each sellable product, so the same item is always recorded the same way, whatever someone types.

**In this project:** each product and sticker sheet design gets a fixed `product_id`, replacing names written five different ways (Solution 2).

### Reconciliation and a single source of truth

**Reconciliation** means checking that two records of the same money agree, such as transactions against summaries, or recorded sales against cash and PayNow received. A **single source of truth** means each fact is stored once and everything else is calculated from it.

**In this project:** four of five events had event-tab totals that didn't match the summary sheet. Summaries are now SQL queries over the transactions, so they can't disagree (Solution 3).

### Payment types

Recording **how** each sale was paid (cash or PayNow) lets cash on hand and bank transfers be checked separately at the end of an event.

---

## Pricing

### Markup vs margin

Both compare price and cost, but against different bases:

- **Markup** = profit ÷ cost
- **Margin** = profit ÷ selling price

**Example:** an item that costs $1.00 and sells for $2.50 has a markup of 150% but a margin of 60%. Mixing the two up leads to under- or over-pricing.

### Bundle pricing

A **bundle promotion** sells several units for less than their single price, raising the number of items per order at the cost of margin per item.

**Example:** sticker sheets at $2.50 each, or 3 for $6, means each sheet in a bundle sells for $2.00, a 20% discount. Profit per sheet has to be calculated at the price actually paid, not the list price.

---

## Costs and profit

### Cost of goods sold (COGS) vs overhead

- **COGS** is the cost of the items actually sold (printing a sticker sheet, for example).
- **Overhead** (operating expenses) is everything else needed to run the business: display stands, packaging, tools, delivery fees.

### Gross profit vs net profit

- **Gross profit** = revenue − COGS
- **Net profit** = gross profit − overhead
### Fixed vs variable costs

**Variable costs** rise with each item sold (printing). **Fixed costs** don't change with sales volume (a clothes rack, a booth fee). Knowing which is which shows how many sales an event needs to cover its fixed costs.

### Break-even point

The **break-even point** is the number of sales needed for profit to cover fixed costs.

**Example:** a $30 booth fee and $1.50 gross profit per sticker sheet means 20 sheets must be sold before the event makes any money.

### Weighted average cost

When identical units are bought in batches at different prices and can't be told apart once mixed, **weighted average cost** values every unit at the same average: total cost of all batches ÷ total units.

**Example:** 100 units at $0.40 and 50 at $0.60 average to $70 ÷ 150 = $0.467, not $0.50. Other inventory costing methods include **FIFO** (first in, first out), which assumes the oldest stock sells first.

**In this project:** sheets from different suppliers can't be told apart once sold, so profit uses weighted average cost (Solution 5).

### Economies of scale

Ordering in larger batches usually lowers the unit cost. Tracking cost per batch shows whether bulk orders actually improved margins.

---

## Inventory

### Stock movements

Stock isn't one number typed into a sheet. It's the result of every **movement**: purchases add stock, sales remove it, and adjustments record anything else.

**In this project:** stock = units bought − units sold − adjustments (Solution 7).

### Write-offs and marketing samples

Units that leave stock without being sold, such as giveaways or items kept for marketing, are **written off**. Their cost is still a business expense, even though there was no revenue.

### Reorder level

A **reorder level** is the stock count at which a product should be reprinted, set from how fast it sells and how long a reprint takes. It replaces deciding by gut feel.

---

## Partnerships

### Profit sharing and licensing

When a design uses someone else's likeness or idea, the owner can be paid a share of what it earns. This works like **licensing**. The agreement has to say whether the share is of **revenue** or of **profit**, since the two give very different payouts.

**In this project:** three sticker sheet designs feature a partner's cats, and the partner receives 50% of the profit on them. The new system calculates this per sale and keeps a running total of what is owed (Solution 4).

### Consignment and commission

**Consignment** means selling someone else's goods and keeping a **commission**. Only the commission is the seller's revenue; the rest belongs to the maker.

**In this project:** other makers' items were mixed into Katchy's sales records, overstating revenue. They are excluded from the new tracker.

---

## Events as a sales channel

### Revenue attribution by channel

**Attribution** means tracking which channel or event each sale came from, so their performance can be compared. Recording the event day as well shows whether a second market day is worth attending.

**In this project:** each order stores its event and event day, replacing row colours that formulas couldn't read.