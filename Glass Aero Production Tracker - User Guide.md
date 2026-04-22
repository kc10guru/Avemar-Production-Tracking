# Glass Aero Production Tracker
## User Guide

**Version:** 1.0  
**Last Updated:** March 2026

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Dashboard](#2-dashboard)
3. [Repair Orders](#3-repair-orders)
4. [Scan & Advance](#4-scan--advance)
5. [Inventory Management](#5-inventory-management)
6. [Bill of Materials (BOM)](#6-bill-of-materials-bom)
7. [Reports](#7-reports)
8. [Settings (Admin Only)](#8-settings-admin-only)
9. [Label Printing](#9-label-printing)
10. [Tips & Troubleshooting](#10-tips--troubleshooting)

---

## 1. Getting Started

### Logging In

1. Open the Production Tracker in your web browser
2. Enter your **email address** and **password**
3. Click **Sign In**

If you don't have login credentials, contact your administrator.

### Navigation

The top navigation bar provides access to all system areas:

| Menu Item | Description |
|-----------|-------------|
| **Dashboard** | Production overview and status summary |
| **Scan** | Quick barcode scanning to advance repair orders |
| **Repair Orders** | View and manage all repair orders |
| **Inventory** | Manage subcomponent stock levels |
| **BOM** | Bill of Materials configuration (Admin only) |
| **Reports** | Production and inventory reports |
| **Settings** | System configuration (Admin only) |

### User Roles

- **Standard User**: Can view orders, advance stages, manage inventory
- **Admin**: Full access including BOM, Settings, Import, and Delete functions

---

## 2. Dashboard

The Dashboard provides a real-time overview of production status.

### Summary Statistics

At the top of the dashboard, you'll see five key metrics:

| Stat | Description |
|------|-------------|
| **Active Orders** | Total repair orders currently in progress |
| **Late Units** | Orders that have exceeded their stage time limit |
| **On Hold** | Orders currently paused/held |
| **Completed This Month** | Orders finished in the current calendar month |
| **Low Stock Alerts** | Inventory items below reorder point |

Click on any stat card to see the related orders.

### Production Pipeline

The pipeline shows all production stages with:
- **Stage number and name**
- **Count of units** currently in each stage
- **Late indicators** (red pulse) for stages with overdue units
- **Hold indicators** for stages with held orders

Click any stage to view the orders at that stage.

### Recent Repair Orders

Shows the 8 most recent active orders with:
- RO number
- Customer name
- Part number and serial
- Current stage
- Status

Click any order to view its details.

### Low Stock Alerts

Displays inventory items that need attention:
- Items below reorder point
- Projected shortages based on in-work orders

---

## 3. Repair Orders

### Viewing All Orders

The Repair Orders page displays all orders in a searchable, filterable table.

**Filters Available:**
- **Search**: Find orders by RO number, customer name, serial number, etc.
- **Status**: Filter by In Progress, Completed, On Hold, or Cancelled
- **Stage**: Filter by specific production stage
- **Part Number**: Filter by windshield part number

Click **Clear** to reset all filters.

### Creating a New Repair Order

1. Click the **+ New Repair Order** button
2. Fill in the required fields (marked with red asterisk):
   - **Customer Name** (required)
   - **Part Number** (required) - select from dropdown
   - **Serial Number** (required)
   - **Contract Type** (required) - Commercial Sales or C12
3. Optionally fill in additional fields:
   - Purchase Order
   - Invoice Number
   - Shipping Address
   - Contact Information
   - Aircraft Details
   - Date Received
   - Expected Completion
   - Notes
4. Click **Create Repair Order**

The system automatically generates a unique RO number (format: RO-YYYYMMDD-XXXX).

### Viewing Repair Order Details

Click any order in the list to view its detail page, which shows:

**Header Section:**
- RO number and status
- Action buttons (Print Barcode, Print, Hold, Advance Stage)

**Production Progress Bar:**
- Visual timeline of all 15 stages
- Completed stages shown in green
- Current stage highlighted in blue
- Skipped stages shown as dashed
- On-hold stage shown in red with pulse animation

**Order Details:**
- All customer and product information
- Edit button (for modifications)

**Documents:**
- Upload files (PDF, images) by clicking **Upload** or dragging and dropping
- View uploaded documents
- Download documents with signed URLs
- Delete documents

**Parts Issued:**
- Shows all inventory parts issued to this order
- Organized by production stage

**Stage History:**
- Complete audit trail of stage transitions
- Shows who completed each stage and when
- Includes any notes added during advancement

### Advancing a Repair Order to the Next Stage

1. Open the repair order detail page
2. Click the **Advance Stage** button
3. If parts are required for this stage (from BOM), they will be displayed
4. Optionally add notes
5. Click **Confirm**

The system will:
- Move the order to the next stage
- Automatically deduct BOM parts from inventory
- Record the stage transition in history

### Placing an Order On Hold

1. Open the repair order detail page
2. Click the **Hold** button (red)
3. Enter the reason for the hold (required)
4. Click **Confirm Hold**

A held order:
- Cannot advance to the next stage
- Shows a red "ON HOLD" banner
- Appears with a hold indicator on the dashboard

### Resuming a Held Order

1. Open the held repair order
2. Click the **Resume** button (green)
3. The order returns to normal status and can be advanced

### Going Back a Stage

If you need to revert an order to a previous stage:
1. Open the repair order detail page
2. Click **Go Back** button
3. Confirm the action

Note: This will restore any parts that were issued when entering the current stage.

### Editing a Repair Order

1. Open the repair order detail page
2. Click the **Edit** button
3. Modify any fields as needed
4. Click **Save Changes**

**Warning:** Changing the part number will:
- Reverse all previously issued BOM parts
- Re-issue the correct parts from the new BOM

### Deleting a Repair Order (Admin Only)

1. Open the repair order detail page
2. Click the **Delete** button
3. Confirm the deletion

This action cannot be undone.

---

## 4. Scan & Advance

The Scan page is optimized for shop floor use with barcode scanners and tablets.

### Using a Barcode Scanner

1. Navigate to the **Scan** page
2. Place cursor in the scan input field
3. Scan the barcode on the repair order label
4. The order information appears automatically
5. Click **Advance** to move to the next stage

### Manual Entry

1. Type the RO number (e.g., RO-20260315-0001)
2. Click **Lookup** or press Enter
3. Review the order information
4. Click **Advance** to proceed

### Quick Workflow

The Scan page is designed for rapid processing:
- Large input field for easy scanning
- Big Advance button for touch screens
- Shows current stage and next stage
- Immediate feedback on success/error

---

## 5. Inventory Management

### Viewing Inventory

The Inventory page shows all subcomponents with:
- Part number and description
- Category
- Quantity on hand
- Available quantity (on hand minus projected needs)
- Reorder point
- Lead time
- Status (OK, Low, Critical)

**Filters:**
- **Category**: Filter by Glass, Electrical, Seals, Hardware, Consumable, General
- **Low Stock Only**: Show only items below reorder point

### Adding a New Part

1. Click **+ Add Part**
2. Fill in the part details:
   - Part Number (required)
   - Description (required)
   - Category
   - Unit of Measure
   - Quantity on Hand
   - Unit Cost
   - Reorder Point
   - Reorder Quantity
   - Lead Time (days)
   - Supplier
3. Click **Save**

### Editing a Part

1. Find the part in the inventory list
2. Click the **Edit** (pencil) icon
3. Modify the fields
4. Click **Save**

### Receiving Stock

When new inventory arrives:

1. Click **Receive Stock** button
2. Select the part from the dropdown
3. Enter the quantity received
4. Click **Receive**

The quantity on hand will be updated automatically.

### Understanding Stock Status

| Status | Meaning |
|--------|---------|
| **OK** (green) | Stock level is above reorder point |
| **Low** (yellow) | Stock is at or below reorder point |
| **Critical** (red) | Stock is zero or will be depleted by in-work orders |

### Projected Availability

The "Available" column shows:
- On Hand quantity
- Minus projected needs for all in-work orders
- Based on BOM requirements for remaining stages

This helps you anticipate shortages before they occur.

---

## 6. Bill of Materials (BOM)

*Admin access required*

The BOM defines which subcomponents are needed for each windshield part number at each production stage.

### Viewing a BOM

1. Navigate to the **BOM** page
2. Select a windshield part number from the dropdown
3. The BOM displays organized by stage

### Adding a BOM Item

1. Select the windshield part number
2. Click **+ Add Item**
3. Select the subcomponent
4. Choose the production stage
5. Enter the quantity required
6. Add optional notes
7. Click **Save**

### Editing a BOM Item

1. Find the item in the BOM list
2. Click the **Edit** icon
3. Modify stage, quantity, or notes
4. Click **Save Changes**

### Deleting a BOM Item

1. Find the item in the BOM list
2. Click the **Delete** (trash) icon
3. Confirm the deletion

### How BOM Works

When a repair order advances to a new stage:
1. System checks if BOM items exist for that stage and part number
2. Required parts are displayed in the Advance modal
3. Upon confirmation, parts are automatically deducted from inventory
4. Issuance is recorded in the repair order's Parts Issued section

---

## 7. Reports

### Weekly Production Report

Shows production activity for a selected week:

**Metrics:**
- Units Received
- Units Delivered
- Total In Work
- Behind Schedule count

**Details:**
- Units by Stage breakdown
- Behind Schedule list with specific orders

**To generate:**
1. Select the week using the date picker
2. Click **Generate**

### Projected Inventory Report

Shows projected inventory levels based on in-work orders:

**Metrics:**
- Total Subcomponents
- Projected Shortages
- Units In Work

**Details:**
- Complete inventory breakdown
- On hand vs. projected need
- Available quantity after all orders complete

### Quarterly Report

Shows production trends for a selected quarter:

**Metrics:**
- Units Received
- Units Delivered
- Units Scrapped
- Average Days to Complete

**Details:**
- Monthly trend chart
- Monthly breakdown table

### Annual Report

Shows year-over-year production data:

**Metrics:**
- Total Received (with YoY comparison)
- Total Delivered (with YoY comparison)
- Total Scrapped
- Average Days to Complete

**Details:**
- 12-month trend chart
- Monthly breakdown table

### Printing Reports

Click **Print Report** to print the current report view. Non-essential elements (navigation, filters) are automatically hidden for print.

---

## 8. Settings (Admin Only)

### Windshield Part Numbers

Manage the list of valid part numbers that can be assigned to repair orders.

**To add a part number:**
1. Click **+ Add**
2. Enter the part number
3. Enter a description
4. Click **Add**

**To edit:**
1. Click the edit icon next to the part
2. Modify fields
3. Click **Save**

### Production Stage Time Limits

Configure how long a unit can stay in each stage before being flagged as late.

1. Enter the number of hours for each stage
2. Click **Save Changes**

Time limits use business hours only (see below).

### Business Hours

Configure your shop's operating hours for accurate time limit calculations.

**Settings:**
- **Shop Opens**: Start time
- **Shop Closes**: End time
- **Timezone**: Select your timezone
- **Work Days**: Check the days your shop operates

Time spent outside business hours (nights, weekends) is not counted toward stage time limits.

---

## 9. Label Printing

### Printing a Barcode Label

1. Open the repair order detail page
2. Click **Print Barcode** button
3. A print preview window opens
4. Select your label printer (Brother QL-1100C recommended)
5. Ensure paper size is set to your label type (DK-1208 recommended)
6. Click Print

### Label Contents

Each label includes:
- Company name (Glass Aero)
- RO number
- Part number
- Serial number
- Scannable barcode (Code 128)

### Recommended Label Printer Setup

**Brother QL-1100C with DK-1208 labels:**
- Label size: 3.5" x 1.4"
- Set as default printer for label jobs
- In printer preferences, select "DK-1208" paper size

---

## 10. Tips & Troubleshooting

### Best Practices

1. **Scan don't type**: Use barcode scanning whenever possible to reduce errors
2. **Keep inventory updated**: Receive stock promptly to maintain accurate availability
3. **Use holds appropriately**: Document the reason clearly for team communication
4. **Check Low Stock daily**: Review the dashboard alerts to prevent delays
5. **Add notes when advancing**: Document any issues or observations

### Common Issues

**"Database connection error"**
- Check your internet connection
- Refresh the page
- If persists, contact your administrator

**"Part number not found"**
- The part number may need to be added in Settings
- Contact an admin to add new part numbers

**"Insufficient inventory"**
- Check the Inventory page for current stock levels
- Receive new stock before advancing the order
- Or adjust the BOM if quantities are incorrect

**Label printing issues**
- Ensure the correct printer is selected
- Verify paper size matches your label roll
- Check that the printer is online

**Order stuck on hold**
- Only the person who placed the hold (or an admin) can resume
- Check the hold reason in the order details

### Real-Time Updates

The system uses real-time synchronization:
- Multiple users can work simultaneously
- Changes appear immediately across all browsers
- Dashboard updates automatically when orders change

### Browser Compatibility

Recommended browsers:
- Google Chrome (latest)
- Microsoft Edge (latest)
- Mozilla Firefox (latest)

Mobile/Tablet:
- Safari on iPad
- Chrome on Android tablets

---

## Support

For technical support or feature requests, contact your system administrator.

---

*Glass Aero Production Tracker - Built for windshield repair excellence.*
