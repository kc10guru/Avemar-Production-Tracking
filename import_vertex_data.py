import xlrd
from datetime import datetime, timedelta

SPREADSHEET = (
    r"c:\Users\kc10g\OneDrive\Documents\JCD Enterprises"
    r"\INTERNAL REPORT -VERTEX WINDOWS 2-13-26.xls"
)
OUTPUT_SQL = (
    r"c:\Users\kc10g\OneDrive\Documents\JCD Enterprises"
    r"\Avemar-Production-Tracking\sql\import-vertex-orders.sql"
)

FIXED = {
    "customer_name": "V2X",
    "contract_type": "Commercial Sales",
    "aircraft_type": "King Air",
    "contact_name": "Edgar Jones",
    "contact_email": "edgar.jones@gov2x.com",
    "shipping_address": "555 Industrial Blvd S Madison MS 39110",
}


def excel_date_to_iso(val):
    if val and isinstance(val, float) and val > 0:
        dt = datetime(1899, 12, 30) + timedelta(days=int(val))
        return dt.strftime("%Y-%m-%d")
    return None


def map_status(cat_process):
    s = str(cat_process).strip().upper() if cat_process else ""
    if "SHIPPED" in s:
        return "Completed"
    if "BER" in s or "SCRAP" in s:
        return "Scrapped"
    return "In Progress"


def sql_str(val):
    if val is None:
        return "NULL"
    escaped = str(val).replace("'", "''").strip()
    if not escaped:
        return "NULL"
    return f"'{escaped}'"


def sql_date(val):
    iso = excel_date_to_iso(val)
    return f"'{iso}'" if iso else "NULL"


def generate_ro_number(index, date_val):
    dt = excel_date_to_iso(date_val)
    if dt:
        date_part = dt.replace("-", "")
    else:
        date_part = datetime.now().strftime("%Y%m%d")
    return f"RO-{date_part}-{1000 + index}"


def build():
    wb = xlrd.open_workbook(SPREADSHEET)
    ws = wb.sheet_by_name("QUOTES APPROVED")

    lines = []
    lines.append("-- Import Vertex Windows repair orders from spreadsheet")
    lines.append("-- Generated: " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    lines.append("")
    lines.append("-- Step 1: Add invoice_number column if not present")
    lines.append("ALTER TABLE repair_orders ADD COLUMN IF NOT EXISTS invoice_number TEXT;")
    lines.append("")
    lines.append("-- Step 2: Insert repair orders")

    count = 0
    for r in range(19, 50):
        part_number = str(ws.cell_value(r, 5)).strip() if ws.cell_value(r, 5) else ""
        serial_number = str(ws.cell_value(r, 6)).strip() if ws.cell_value(r, 6) else ""

        if not part_number or not serial_number:
            continue

        vertex_po = str(ws.cell_value(r, 4)).strip() if ws.cell_value(r, 4) else None
        date_approved = ws.cell_value(r, 7)
        cat_process = str(ws.cell_value(r, 8)).strip() if ws.cell_value(r, 8) else ""
        invoice_no = str(ws.cell_value(r, 9)).strip() if ws.cell_value(r, 9) else None
        shipped_date = ws.cell_value(r, 10)
        promise_date = ws.cell_value(r, 12)

        status = map_status(cat_process)
        current_stage = 15 if status == "Completed" else 1
        ro_number = generate_ro_number(count + 1, date_approved)

        # Handle the Dec 2026 typo
        shipped_iso = excel_date_to_iso(shipped_date)
        if shipped_iso and shipped_iso > "2026-02-24":
            shipped_iso = shipped_iso[:4].replace("2026", "2025") + shipped_iso[4:]

        lines.append(f"""
INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  {sql_str(ro_number)}, {sql_str(FIXED['customer_name'])}, {sql_str(part_number)}, {sql_str(serial_number)},
  {sql_str(FIXED['aircraft_type'])}, {sql_str(FIXED['contract_type'])}, {sql_str(FIXED['shipping_address'])},
  {sql_str(vertex_po)}, {sql_str(invoice_no)},
  {sql_str(FIXED['contact_name'])}, {sql_str(FIXED['contact_email'])},
  {current_stage}, {sql_date(date_approved)}, {sql_date(promise_date)}, {f"'{shipped_iso}'" if shipped_iso else 'NULL'},
  {sql_str(status)}, {sql_str(cat_process) if cat_process else 'NULL'}
);""")
        count += 1

    lines.append("")
    lines.append(f"-- Total records imported: {count}")

    with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"Generated {count} INSERT statements")
    print(f"Output: {OUTPUT_SQL}")


if __name__ == "__main__":
    build()
