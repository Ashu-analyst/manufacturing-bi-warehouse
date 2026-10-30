"""Create SYNTHETIC ERP extracts (as they would land from SAP/Navision via a copy pipeline).
Deliberately includes real-world data-quality problems so the dbt tests have work to do:
- customer names with trailing spaces and mixed case
- country codes in mixed formats ('DE', 'de', 'Germany')
- a few order lines with negative quantity (returns) and one duplicate line
"""
import csv
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(11)
OUT = Path(__file__).resolve().parents[1] / "seeds"
OUT.mkdir(exist_ok=True)

SITES = [("S01", "Bexbach", "DE"), ("S02", "Brattvåg", "NO"), ("S03", "Lima", "PE"), ("S04", "Ludwigshafen", "DE")]
PRODUCTS = [
    ("P100", "Omega-3 Concentrate 70%", "API", "kg", 42.0),
    ("P110", "Omega-3 Concentrate 50%", "API", "kg", 31.0),
    ("P200", "Refined Fish Oil", "Bulk Oil", "kg", 6.5),
    ("P210", "Algae Oil DHA", "Bulk Oil", "kg", 18.0),
    ("P300", "Softgel Ready Blend", "Finished Blend", "kg", 24.0),
    ("P310", "Pharma-grade EPA", "API", "kg", 65.0),
]
COUNTRIES = ["DE", "de", "Germany", "NL", "FR", "US", "us", "NO", "CH", "IT"]
CUSTOMERS = [(f"C{n:03d}", random.choice(["Nutra", "Pharma", "Vital", "Health", "Bio"]) + random.choice([" GmbH", " AG", " Inc", " S.A.", " BV "]),
              random.choice(COUNTRIES), random.choice(["Pharma", "Nutraceutical", "Infant Nutrition"])) for n in range(1, 61)]

with open(OUT / "raw_sites.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["site_code", "site_name", "country_code"]); w.writerows(SITES)
with open(OUT / "raw_products.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["material_no", "material_desc", "product_group", "base_uom", "std_price_eur"]); w.writerows(PRODUCTS)
with open(OUT / "raw_customers.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["customer_no", "customer_name", "country", "industry"])
    for c in CUSTOMERS:
        w.writerow([c[0], c[1] if random.random() > 0.3 else c[1].upper() + "  ", c[2], c[3]])

start = date(2024, 1, 1)
lines, batches = [], []
for d in range(0, 1004):
    day = start + timedelta(days=d)
    if day.weekday() >= 5:
        continue
    for _ in range(random.randint(2, 6)):
        cust = random.choice(CUSTOMERS)
        prod = random.choice(PRODUCTS)
        qty = round(random.lognormvariate(6.2, 0.6))
        if random.random() < 0.02:
            qty = -max(1, qty // 10)  # return
        price = round(prod[4] * random.uniform(0.9, 1.15), 2)
        lines.append([f"SO{len(lines) + 100000}", 10, day.isoformat(), cust[0], prod[0], random.choice(SITES)[0], qty, price, "EUR"])
    for site in SITES:
        if random.random() < 0.6:
            prod = random.choice(PRODUCTS)
            planned = random.choice([2000, 5000, 10000])
            actual = round(planned * random.uniform(0.86, 1.02))
            status = "RELEASED" if random.random() > 0.04 else "REJECTED"
            batches.append([f"B{len(batches) + 50000}", site[0], prod[0], day.isoformat(), planned, actual, status, round(random.uniform(18, 36), 1)])
lines.append(lines[42])  # duplicate extract row, a classic

with open(OUT / "raw_sales_order_lines.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["order_no", "line_no", "order_date", "customer_no", "material_no", "site_code", "quantity", "unit_price", "currency"]); w.writerows(lines)
with open(OUT / "raw_production_batches.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["batch_no", "site_code", "material_no", "production_date", "planned_qty_kg", "actual_qty_kg", "qc_status", "cycle_time_h"]); w.writerows(batches)
print(f"{len(lines)} order lines, {len(batches)} batches, {len(CUSTOMERS)} customers")
