"""
Build a SQL file that loads Katchy's old spreadsheet records into the database.

One-time migration: reads the workbook, cleans it, and writes data/real/history.sql.
Run that SQL file on the `katchy` database AFTER schema.sql and seed.sql.

Usage (from the project root, venv active):
    pip install openpyxl
    python scripts/build_history_sql.py
    python scripts/build_history_sql.py path/to/workbook.xlsx path/to/output.sql

The workbook and the output contain real data. Both live in data/real/, which is git-ignored.
"""

import re
import sys
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

import openpyxl

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

DEFAULT_XLSX = Path("data/real/Katchy_Tracking.xlsx")
DEFAULT_OUT = Path("data/real/history.sql")

# Sheet name -> event details. Order of row colours in each sheet = event day 1, 2, 3.
EVENTS = {
    "Sales for New Beginnings": dict(name="New Beginnings",    start="2025-08-06", end="2025-08-06", days=1, summary="New Beginnings"),
    "Sales for ORIGIN market":  dict(name="Origin Market",     start="2025-09-10", end="2025-09-11", days=2, summary="Origin Market"),
    "Sales for BACKtoSch":      dict(name="Back to School",    start="2026-09-09", end="2026-09-10", days=2, summary="Back to School"),
    "Sales for Nebula":         dict(name="Nebula",            start="2026-10-08", end="2026-10-08", days=1, summary="Nebula"),
    "Sales for Halloween":      dict(name="Creepy Craft Fair", start="2026-10-28", end="2026-10-30", days=3, summary="Halloween"),
}

EXPENSES_SHEET = "Expenses 2025"
SUMMARY_SHEET = "Total Sales 2025"

# Record each event's "to Summer" amount as a payment to her (assumes these were paid).
IMPORT_SUMMER_PAYMENTS = True

# Promotion rule (same as seed.sql): price per unit for 1-2 items, and for 3+ in the group.
PROMO_GROUPS = {
    "Sticker Sheet": "sheets_prints",
    "Print": "sheets_prints",
    "Sticker": "stickers",
}
PRICES = {  # product type: (normal price, promotion price)
    "Sticker Sheet": (Decimal("2.50"), Decimal("2.00")),
    "Print":         (Decimal("2.50"), Decimal("2.00")),
    "Sticker":       (Decimal("1.50"), Decimal("1.00")),
    "Shirt":         (Decimal("16.00"), None),
    "Pin":           (Decimal("1.50"), None),
}

# Other makers' items sold on commission: excluded. Value = price taken out of the payment.
COMMISSION_ITEMS = {"card holder": Decimal("5.00"), "macrame": Decimal("5.00")}

# Words in an item's notes or remarks that identify a design.
SHEET_DESIGNS = {"willow": "Willow", "fungus": "Fungus", "jimmy": "Jimmy", "ocean": "Ocean Wonders"}
SUMMER_CAT_SET = ["Willow", "Fungus", "Jimmy"]            # "Summer cats" = one of each
PRINT_DESIGNS = {"shark": "Shark", "drink": "Drink", "borzoi": "Borzoi", "giraffe": "Giraffe"}
SHIRT_DESIGNS = {"catfish": "Catfish", "flower": "Flower"}
SHIRT_SIZES = {"small": "S", "medium": "M", "large": "L", "xl": "XL", "s": "S", "m": "M", "l": "L"}
UNRECORDED = "Design not recorded"

# Expense rows needing manual handling, by row number in the Expenses sheet.
EXPENSE_OVERRIDES = {
    # One order of 100 sticker backings and 60 prints at the same unit cost: split into two rows.
    # total=None means quantity x the row's unit cost, so no real costs are written in this file.
    5: [
        dict(item="Prints (Drink, Cat, Shark x20 each)", category="product", type="Print",
             quantity=60, total=None),
        dict(item="Sticker backings 8cm x 12cm", category="packaging", type=None,
             quantity=100, total=None),
    ],
    6:  [dict(quantity=700)],           # "700 pieces" written in the description
    8:  [dict(quantity=80)],            # "80 pieces" written in the description
    9:  [dict(quantity=44)],            # quantity typed into the description column
    50: [dict(category="packaging")],   # packaging was labelled "Product"
}
# Item name -> product type, for product purchases (whole words, checked in order).
EXPENSE_TYPES = [
    (r"\bsticker\s*sheets?\b", "Sticker Sheet"),
    (r"\bstickers?\b", "Sticker"),
    (r"\bprints?\b", "Print"),
    (r"\bshirts?\b", "Shirt"),
    (r"\bpins?\b", "Pin"),
]

# Orders that don't follow the promotion rule: the unit prices actually charged.
# Key: (event name, row number in that event's sheet).
PRICE_OVERRIDES = {
    # First event: the sheet promotion didn't exist yet; prints and stickers were discounted.
    ("New Beginnings", 20): {"Sticker Sheet": Decimal("2.50"), "Print": Decimal("2.00"), "Sticker": Decimal("1.00")},
    # $0.50 off; assumed taken off the pin.
    ("Back to School", 7): {"Sticker Sheet": Decimal("2.50"), "Pin": Decimal("1.00")},
}

CENT = Decimal("0.01")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def money(x):
    return Decimal(str(x)).quantize(CENT, rounding=ROUND_HALF_UP)


def sql_str(value):
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def product_ref(ptype, design, variant=""):
    """SQL subquery that finds a product's id by type, design and variant."""
    return (f"(SELECT p.product_id FROM products p JOIN product_types t USING (product_type_id) "
            f"WHERE t.name = {sql_str(ptype)} AND p.design = {sql_str(design)} "
            f"AND p.variant = {sql_str(variant)})")


def find_designs(text, mapping):
    text = (text or "").lower()
    return [design for word, design in mapping.items() if word in text]


# ---------------------------------------------------------------------------
# Sales
# ---------------------------------------------------------------------------

def parse_part(part):
    """'3 sticker sheets (Summer cats)' -> (qty, product type or commission key, extra text)."""
    note = " ".join(re.findall(r"\(([^)]*)\)", part))
    text = re.sub(r"\([^)]*\)", "", part).strip().lower()
    m = re.match(r"^(\d+)?\s*(.*)$", text)
    qty = int(m.group(1)) if m.group(1) else 1
    rest = m.group(2)
    for key in COMMISSION_ITEMS:
        if key in rest:
            return qty, ("commission", key), rest
    for pattern, ptype in [(r"sticker\s*sheets?", "Sticker Sheet"), (r"stickers?", "Sticker"),
                           (r"prints?", "Print"), (r"shirts?", "Shirt"), (r"pins?", "Pin")]:
        if re.search(pattern, rest):
            return qty, ptype, (rest + " " + note).strip()
    return qty, None, rest


def assign_designs(ptype, qty, hint_text):
    """Split a line into (design, variant, qty) pieces using design words in the notes."""
    hint = (hint_text or "").lower()
    if ptype == "Sticker Sheet":
        if re.search(r"summers?\s*cats?", hint):
            designs = SUMMER_CAT_SET if qty == 3 else []
        else:
            designs = find_designs(hint, SHEET_DESIGNS)
    elif ptype == "Print":
        designs = find_designs(hint, PRINT_DESIGNS)
    elif ptype == "Shirt":
        tokens = re.findall(r"[a-z]+", hint)
        design = next((SHIRT_DESIGNS[t] for t in tokens if t in SHIRT_DESIGNS), None)
        colour = next((t.title() for t in tokens if t in ("white", "black")), None)
        size = next((SHIRT_SIZES[t] for t in tokens if t in SHIRT_SIZES), None)
        if design and colour and size:
            return [(design, f"{colour} {size}", qty)]
        return [(UNRECORDED, "", qty)]
    else:
        return [("All designs", "", qty)]

    pieces, used = [], 0
    for d in designs[:qty]:
        pieces.append((d, "", 1))
        used += 1
    if qty - used:
        pieces.append((UNRECORDED, "", qty - used))
    return pieces


def price_lines(lines):
    """Apply the promotion rule. lines: list of dicts with type and qty."""
    group_qty = {}
    for ln in lines:
        g = PROMO_GROUPS.get(ln["type"])
        if g:
            group_qty[g] = group_qty.get(g, 0) + ln["qty"]
    for ln in lines:
        normal, promo = PRICES[ln["type"]]
        g = PROMO_GROUPS.get(ln["type"])
        ln["unit"] = promo if g and promo and group_qty[g] >= 3 else normal


def fit_to_paid(items, paid):
    """Scale unit prices so the order adds up to what was actually paid."""
    rule_total = sum(i["unit"] * i["qty"] for i in items)
    if rule_total == paid or rule_total == 0:
        return
    for i in items:
        i["unit"] = (i["unit"] * paid / rule_total).quantize(CENT, rounding=ROUND_HALF_UP)
    diff = paid - sum(i["unit"] * i["qty"] for i in items)
    single = next((i for i in items if i["qty"] == 1), None)
    if diff and single:
        single["unit"] += diff


def read_event_sheet(ws, event, report):
    orders, colours = [], []
    for r in range(2, ws.max_row + 1):
        item = ws.cell(r, 2).value
        if isinstance(item, str) and item.strip().lower().startswith("total revenue"):
            break
        paid = ws.cell(r, 3).value
        if not item or paid is None:
            continue
        paid = money(paid)
        pay = (ws.cell(r, 4).value or "").strip().lower() or None
        remarks = ws.cell(r, 5).value or ""

        fill = ws.cell(r, 1).fill
        colour = fill.fgColor.rgb if fill.fill_type else None
        if colour not in colours:
            colours.append(colour)
        day = colours.index(colour) + 1

        parts = [p for p in re.split(r",|\band\b", str(item)) if p.strip()]
        lines, katchy_paid, skipped = [], paid, []
        for part in parts:
            qty, ptype, rest = parse_part(part)
            if isinstance(ptype, tuple):
                katchy_paid -= COMMISSION_ITEMS[ptype[1]] * qty
                skipped.append(part.strip())
            elif ptype is None:
                report["unparsed"].append(f"{event['name']} row {r}: {item!r}")
            else:
                lines.append(dict(type=ptype, qty=qty, hint=rest))

        if skipped and not lines:
            report["commission"].append(f"{event['name']} row {r}: {item!r} ${paid} (whole order skipped)")
            continue
        if skipped:
            report["commission"].append(f"{event['name']} row {r}: removed {skipped} from {item!r}")
        if not lines:
            continue
        if katchy_paid <= 0:
            report["unparsed"].append(f"{event['name']} row {r}: nothing left after commission")
            continue

        # Remarks name designs only when the order has one line of that type.
        for ptype in ("Sticker Sheet", "Print"):
            same = [ln for ln in lines if ln["type"] == ptype]
            if len(same) == 1:
                same[0]["hint"] += " " + str(remarks)

        price_lines(lines)
        rule_total = sum(ln["unit"] * ln["qty"] for ln in lines)
        override = PRICE_OVERRIDES.get((event["name"], r))
        if override:
            for ln in lines:
                ln["unit"] = override.get(ln["type"], ln["unit"])
            new_total = sum(ln["unit"] * ln["qty"] for ln in lines)
            report["overridden"].append(
                f"{event['name']} row {r}: {item!r} paid ${katchy_paid}; rule gives ${rule_total}, "
                f"override gives ${new_total}")
            rule_total = new_total

        items = {}
        for ln in lines:
            for design, variant, q in assign_designs(ln["type"], ln["qty"], ln["hint"]):
                key = (ln["type"], design, variant)
                if key in items:
                    items[key]["qty"] += q
                else:
                    items[key] = dict(type=ln["type"], design=design, variant=variant, qty=q, unit=ln["unit"])
        items = list(items.values())

        if rule_total != katchy_paid:
            report["price_mismatch"].append(
                f"{event['name']} row {r}: {item!r} paid ${katchy_paid}, promotion rule gives ${rule_total}")
            fit_to_paid(items, katchy_paid)

        orders.append(dict(day=day, pay=pay if pay in ("cash", "paynow") else None,
                           items=items, paid=katchy_paid, row=r))

    if len(colours) > event["days"]:
        report["warnings"].append(f"{event['name']}: {len(colours)} row colours but {event['days']} event days")
    return orders


def read_to_summer(ws):
    for r in range(1, ws.max_row + 1):
        if str(ws.cell(r, 5).value or "").strip().lower() == "to summer":
            return money(ws.cell(r, 6).value)
    return None


def read_summary(wb):
    """Revenue per event from the Total Sales tab, excluding commission rows."""
    ws = wb[SUMMARY_SHEET]
    totals = {}
    for r in range(2, ws.max_row + 1):
        event, item, revenue = ws.cell(r, 2).value, ws.cell(r, 3).value, ws.cell(r, 5).value
        if event and item and "comm" not in str(item).lower() and isinstance(revenue, (int, float)):
            totals[event] = totals.get(event, Decimal(0)) + money(revenue)
    return totals


# ---------------------------------------------------------------------------
# Expenses
# ---------------------------------------------------------------------------

def read_expenses(wb, report):
    ws = wb[EXPENSES_SHEET]
    rows = []
    for r in range(2, ws.max_row + 1):
        year, item = ws.cell(r, 1).value, ws.cell(r, 2).value
        if not isinstance(year, (int, float)) or not item:
            continue
        base = dict(
            year=int(year),
            item=str(item).strip(),
            quantity=int(ws.cell(r, 5).value) if isinstance(ws.cell(r, 5).value, (int, float)) else None,
            total=money(ws.cell(r, 6).value),
            supplier=ws.cell(r, 8).value,
            category=str(ws.cell(r, 9).value or "").strip().lower(),
            notes="; ".join(str(v).replace("\n", " ").strip()
                            for v in (ws.cell(r, 3).value, ws.cell(r, 10).value)
                            if v is not None and not isinstance(v, (int, float))) or None,
        )
        base["type"] = None
        if base["category"] == "product":
            name = base["item"].lower()
            base["type"] = next((t for pattern, t in EXPENSE_TYPES if re.search(pattern, name)), None)

        unit_cost = ws.cell(r, 4).value
        for override in EXPENSE_OVERRIDES.get(r, [{}]):
            row = {**base, **override}
            if row["total"] is None:
                row["total"] = money(Decimal(str(unit_cost)) * row["quantity"])
            if row["type"] and row["quantity"] is None:
                report["warnings"].append(f"Expense row {r} {row['item']!r}: product with no quantity, left unlinked")
                row["type"] = None
            rows.append(row)
    return rows


# ---------------------------------------------------------------------------
# SQL output
# ---------------------------------------------------------------------------

def write_sql(path, events, expenses, summer_payments):
    out = [
        "-- Katchy historical data, generated by scripts/build_history_sql.py. CONTAINS REAL DATA.",
        "-- Run once on `katchy`, after schema.sql and seed.sql.",
        "SET client_min_messages TO WARNING;",
        "BEGIN;",
        "DO $$ BEGIN IF EXISTS (SELECT 1 FROM orders) OR EXISTS (SELECT 1 FROM expenses) THEN",
        "  RAISE EXCEPTION 'orders or expenses already contain data: history was probably loaded already';",
        "END IF; END $$;",
        "",
        "-- Events",
    ]
    for ev in events:
        out.append(f"INSERT INTO events (name, start_date, num_days) VALUES "
                   f"({sql_str(ev['name'])}, {sql_str(ev['start'])}, {ev['days']});")

    out += ["", "-- Expenses"]
    for e in expenses:
        type_sql = (f"(SELECT product_type_id FROM product_types WHERE name = {sql_str(e['type'])})"
                    if e["type"] else "NULL")
        out.append(
            "INSERT INTO expenses (purchase_year, item, category, product_type_id, quantity, total_cost, supplier, notes) "
            f"VALUES ({e['year']}, {sql_str(e['item'])}, {sql_str(e['category'])}, {type_sql}, "
            f"{e['quantity'] if e['quantity'] is not None else 'NULL'}, {e['total']}, "
            f"{sql_str(e['supplier'])}, {sql_str(e['notes'])});")

    out += ["", "-- Orders and line items"]
    for ev in events:
        event_sql = f"(SELECT event_id FROM events WHERE name = {sql_str(ev['name'])})"
        out.append(f"-- {ev['name']}")
        for o in ev["orders"]:
            values = ", ".join(
                f"({product_ref(i['type'], i['design'], i['variant'])}, {i['qty']}, {i['unit']})"
                for i in o["items"])
            out.append(
                f"WITH o AS (INSERT INTO orders (event_id, event_day, payment_type) "
                f"VALUES ({event_sql}, {o['day']}, {sql_str(o['pay'])}) RETURNING order_id) "
                f"INSERT INTO order_items (order_id, product_id, quantity, unit_price) "
                f"SELECT o.order_id, v.product_id, v.quantity, v.unit_price FROM o, "
                f"(VALUES {values}) AS v (product_id, quantity, unit_price);")

    if summer_payments:
        out += ["", "-- Payments to Summer (each event's 'to Summer' amount)"]
        for name, date, amount in summer_payments:
            out.append(
                "INSERT INTO partner_payments (partner_id, event_id, payment_date, amount) VALUES "
                "((SELECT partner_id FROM partners WHERE name = 'Summer'), "
                f"(SELECT event_id FROM events WHERE name = {sql_str(name)}), {sql_str(date)}, {amount});")

    out += ["", "COMMIT;", ""]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(out), encoding="utf-8")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    xlsx = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_XLSX
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUT
    wb = openpyxl.load_workbook(xlsx, data_only=True)   # data_only: read formula results
    report = {k: [] for k in ("overridden", "price_mismatch", "commission", "unparsed", "warnings")}

    summary = read_summary(wb)
    events, summer_payments = [], []
    for sheet, ev in EVENTS.items():
        ws = wb[sheet]
        ev = {**ev, "orders": read_event_sheet(ws, ev, report)}
        events.append(ev)
        amount = read_to_summer(ws)
        if IMPORT_SUMMER_PAYMENTS and amount:
            summer_payments.append((ev["name"], ev["end"], amount))
    events.sort(key=lambda e: e["start"])
    expenses = read_expenses(wb, report)
    write_sql(out, events, expenses, summer_payments)

    # Report
    print(f"Wrote {out}\n")
    print(f"{'Event':<20}{'Orders':>7}{'Revenue loaded':>16}{'Total Sales tab':>17}")
    for ev in events:
        revenue = sum(i["unit"] * i["qty"] for o in ev["orders"] for i in o["items"])
        tab = summary.get(ev["summary"], Decimal(0))
        print(f"{ev['name']:<20}{len(ev['orders']):>7}{'$' + str(revenue):>16}{'$' + str(tab):>17}")
    print(f"\nExpenses: {len(expenses)} rows, ${sum(e['total'] for e in expenses)}")
    if summer_payments:
        print(f"Payments to Summer: {len(summer_payments)}, ${sum(a for _, _, a in summer_payments)}")

    titles = {
        "overridden": "Orders priced from PRICE_OVERRIDES",
        "price_mismatch": "Orders where the amount paid differs from the promotion rule "
                          "(unit prices adjusted to match what was paid)",
        "commission": "Commission items excluded",
        "unparsed": "Rows the script could not read (NOT imported, check these)",
        "warnings": "Warnings",
    }
    for key, title in titles.items():
        if report[key]:
            print(f"\n{title}:")
            for line in report[key]:
                print(f"  - {line}")


if __name__ == "__main__":
    main()