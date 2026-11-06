# Current Sales Tracking Procedure
This document covers Phase 1 (how Katchy tracks sales and costs today) and Phase 2 (the problems with that approach). 
> **Privacy note:** customer names, supplier details and exact unit costs are left out of this public version on purpose. Selling prices are included because they are already public at the booth.

---

## Part 1: How sales are tracked today
All tracking currently happens in a single spreadsheet workbook on Microsoft Excel.

### Sales channels

Katchy currently sells only at in-person markets. Events tracked so far:

| Year | Event |
| --- | --- |
| 2025 | New Beginnings |
| 2025 | Origin Market |
| 2026 | Back to School |
| 2026 | Nebula |
| 2026 | Creepy Craft Fair |

Products sold: stickers, sticker sheets, prints, shirts and pins.

### Structure of the workbook

The workbook has seven tabs, in this order:

```
Workbook
├── Expenses             (all purchases, 2025–2026)
├── Total Sales          (per event × product summary)
├── Halloween            ┐
├── Nebula               │
├── Back to School       ├ one transaction tab per event
├── Origin Market        │
└── New Beginnings       ┘
```

### 1. Costs: the Expenses tab

Every purchase is entered as one row:

| Column | What goes in it |
| --- | --- |
| Year | Year of purchase |
| Item | What was bought |
| Description | Free-text details, e.g. which designs were printed |
| Cost (per item) | Unit cost in SGD |
| Quantity | Number of units |
| Total Cost | Unit cost × quantity, or typed in directly |
| Category | Dropdown: Product, Packaging, Display, Delivery, Tools |
| Comments | Notes, e.g. units kept for personal or marketing use |

A total at the bottom sums all expenditure.

### 2. Sales: the event tabs

During each event, every sale is entered as one row in that event's tab:

| Column | What goes in it |
| --- | --- |
| No. | Running transaction number |
| Item | Free text listing everything bought, e.g. "3 stickers, 1 print" |
| Paid | Amount paid in SGD |
| Payment Type | Cash or PayNow |
| Remarks | Customer name, design names or notes |
| Profit | Paid minus unit costs |

Rows are colour-coded by event day, so a two-day market has two colour bands.

Next to the transaction list, each tab has a **price list** with each product's unit cost, selling price and promotion. Current selling prices:

| Product | Price | Promotion |
| --- | --- | --- |
| Sticker | $1.50 | 3 for $3 |
| Sticker sheet | $2.50 | 3 for $6 |
| Print | $2.50 | 3 for $6 |
| Shirt | $16 | none |
| Pin | $1.50 | none |

### 3. Profit share with Summer

Three sticker sheet designs feature cats owned by Summer. Katchy pays her **50% of the profit** on those three designs. At the bottom of each event tab, a "to Summer" amount is worked out by hand from the number of cat sticker sheets sold that event.

### 4. Summarising each event: the Total Sales tab

After each event, the event tab is reviewed and totals are copied into Total Sales, one row per product:

| Column | What goes in it |
| --- | --- |
| Year | Year of the event |
| Event | Event name |
| Item | Product type: Sticker, Sticker Sheets, Prints, Shirt, Pins |
| Qty | Units sold, counted from the event tab |
| Revenue | Money received for that product |
| Cost Price | Quantity × unit cost |
| Profit | Revenue minus cost price |

The bottom of the tab shows total revenue across all events.

---

## Part 2: Problems and limitations

### Problem 1: Sales are recorded as free text, so they cannot be counted automatically

**Each transaction stores everything bought in one cell, e.g. "4 stickers, 1 print, 2 sticker sheets".** 
**Example:** to fill in Total Sales, every row of an event tab has to be read and the quantities added up by hand for each product.
**Impact:** summaries are slow to produce and easy to miscount. Product-level questions (which designs sell best, what is bought together) can't be answered without re-reading every row.

### Problem 2: The same thing is written in different ways

**There are no fixed product names or IDs.** 
**Example:** "sticker sheet", "Sticker Sheets" and "3 sticker sheet" all appear; the print promotion is written as both "3 for 6" and "6 for 3".
**Impact:** any formula or query that groups by product splits one product into several.

### Problem 3: Event tabs and Total Sales don't agree

**Each sale is recorded in an event tab and then retyped, as product totals, in Total Sales. The price list is also copied into every event tab.** 
**Example:** only one of the five events has matching totals:

| Event | Event tab total | Total Sales revenue | Difference |
| --- | --- | --- | --- |
| Halloween | $256.50 | $223.00 | $33.50 |
| Nebula | $65.50 | $65.50 | $0.00 |
| Back to School | $182.50 | $167.00 | $15.50 |
| Origin Market | $110.50 | $107.50 | $3.00 |
| New Beginnings | $183.50 | $167.50 | $16.00 |

**Impact:** there is no single source of truth, so it's unclear which revenue figure is correct.

### Problem 4: Partner's profit share is calculated by hand

**Cat sticker sheets aren't recorded as separate products, so they have to be picked out of the free-text Item and Remarks columns.** 
**Example:** some rows name the cats, but others just say "3 sticker sheets". The amount is then worked out per tab.
**Impact:** it is easy to underpay or overpay my partner, and there is no running total of what she has been paid.

### Problem 5: Unit costs are fixed numbers that don't follow real purchases

**Profit uses a single unit cost per product from the price list.** 
**Example:** the price list keeps one cost for sticker sheets and prints, but the Expenses tab shows later batches cost noticeably less, and the print cost in the price list differs from the Expenses tab.
**Impact:** profit per event and per product is inaccurate, and the effect of cheaper suppliers or bulk orders can't be measured.

### Problem 6: Event profit ignores overhead costs

**Event profit only subtracts the unit cost of items sold.** 
**Example:** display items, packaging, tools and delivery fees are in the Expenses tab but never reach Total Sales.
**Impact:** every event looks profitable, while the business's true overall profit after all expenses is never calculated.

### Problem 7: Costs can't be linked to the products they were for

**Expenses rows describe purchases, but nothing connects them to what was sold.** 
**Example:** many small bead and charm purchases are logged as "Product", with no link to which finished product they went into.
**Impact:** the true cost and profit of a specific product line is unknown.


### Problem 8: No stock tracking

**Quantities bought and quantities sold live on different tabs and are never compared.** 
**Example:** units given away or kept for marketing are noted only in comments.
**Impact:** there is no record of how much stock is left, so reprint decisions are made by gut feel.
