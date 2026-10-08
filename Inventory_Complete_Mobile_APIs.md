# Immortal ERP — Complete Inventory APIs (Mobile / App)

**Audience:** Mobile developers  
**Module:** Inventory (parity with web)  
**Source of truth:** `backend-erp-system/routes/inventoryRoutes.js` + nested inventory modules + web `frontend-erp-system/src/pages/Inventory/`  
**Date:** 21 September 2026  
**Related:**  
- `Inventory_Dashboard_Mobile_APIs.md` (dashboard deep-dive)  
- `Inventory_Stock_Lookup_Mobile_APIs.md` (stock search MVP)  
- `Mobile_Permissions_API_Guide.md`

This document lists **every Inventory API the web app uses**, with request/response shapes that match the live backend so the mobile app can implement full Inventory parity.

---

## 1. Global contract

### Base URL
```text
https://<host>/api
```
UAT example: `https://erp-uat.immortalgroup.in/api`

Prefer paths under `/api/...` (same as web `httpClient`).  
Router is mounted at both `/api` and `/api/inventory`. Use the **web paths below** to avoid double prefixes like `/api/inventory/inventory/stock-in`.

### Headers (every call)
```http
Authorization: Bearer <access_token>
Content-Type: application/json
Accept: application/json
x-company-id: <company UUID>
```

For multipart uploads, omit `Content-Type` (let the client set the boundary). Still send `Authorization` and `x-company-id`.

### Response envelope
```json
{
  "success": true,
  "message": "...",
  "data": {}
}
```

**Approval pending** (many writes):
```json
{
  "success": true,
  "message": "...sent for approval",
  "data": [],
  "approvalId": 123
}
```

**Error:**
```json
{ "success": false, "message": "..." }
```
Zod validation may also include `"errors": [...]`. Older errors may use `{ "status": "fail", "message": "..." }` — handle both.

### Auth / module
- JWT required. On `401` → refresh → retry.
- Inventory module entitlement required (`checkModule('inventory')`), except some paths also allow `sales` / `production`.
- Missing permission → `403`.
- SuperAdmin bypasses permission checks and may get `bypass.approval`.

### Uploads
- Allowed: PDF, JPEG, PNG  
- Max **5MB** (backend). Web documents UI may enforce a tighter client limit.  
- Stored URL shape: `/api/uploads/<filename>`  
- Absolute URL: `{API_ORIGIN}/api/uploads/<filename>`

### Pagination (default unless noted)
| Query | Default | Max |
|-------|---------|-----|
| `page` | 1 | — |
| `limit` | 10 (items default 25) | usually 200; transactions/items up to 500 |

List responses commonly:
```json
{
  "success": true,
  "data": {
    "data": [ /* rows */ ],
    "pagination": { "total": 100, "page": 1, "limit": 20 }
  }
}
```
Some endpoints use `{ items, pagination }`, `{ customers, pagination }`, `{ vendors, pagination }` — unwrap carefully (web does).

---

## 2. Web screen → permission map

Match web tab gates (`inventoryTabPermissions.js`). Access is **any-of** the listed permissions.

| Web route / tab | Permissions (any) |
|-----------------|-------------------|
| `/inventory/dashboard` | `inventory_dashboard.view`, `inventory.view` |
| Products | `product.view`, `product.manage` |
| Product Categories | `product_category.view`, `product_category.manage`, `product.view` |
| Price Lists | UI stub — **no API** |
| BOM | `bom.view`, `bom.manage` (+ related view/write set on server) |
| Vendors | `vendor.view` (manage needs `vendor.manage`) |
| Purchase Demand | `purchase_order.view`, `approval.view` |
| Purchase Orders | `purchase_order.view` |
| Purchase Received | `purchase_receive.view` |
| Purchase Bills | `bill.view` |
| Inventory (lots) | `inventory.view` |
| Stock IN / OUT | `inventory.view`, `inventory.manage`, `product.manage` |
| Stock OUT Bills | `inventory.view`, `inventory.manage`, `bill.view` |
| Warehouses | `inventory.view`, `warehouse.manage` |
| Movement Ledger | `inventory.view` |
| Stock Report | `inventory_report.view`, `inventory.view` |
| Sellable Inventory | `inventory.view` |
| Processed lots & FG | `inventory.view`, `lot_processing.process` |
| Documents | `inventory.view`, `inventory_dashboard.view` |
| Reports | `inventory_report.view`, `inventory.view` |
| Sales tabs under Inventory | **legacy** — web redirects to Sales CRM; APIs still exist |

---

## 3. Lookups (shared pickers)

Used across Products, Purchase, Stock, BOM.

| Method | Path | Permission | Query | `data` |
|--------|------|------------|-------|--------|
| GET | `/api/lookups/product-categories` | lookup catalog | `search`/`q`, `limit` | `[{ id, name, type, hsnSac }]` |
| GET | `/api/lookups/vendors` | lookup catalog | same | `[{ id, name }]` ACTIVE |
| GET | `/api/lookups/warehouses` | lookup catalog | same | `[{ id, name }]` |
| GET | `/api/lookups/items` | lookup catalog | `search`/`q`, `limit` | item lite (+ category and `productType`) |

Web also lists warehouses via `GET /api/warehouse?page=1&limit=500` and items via `GET /api/items?page=1&limit=500`.

---

## 4. Dashboard

**Web:** `/inventory/dashboard`

### 4.1 Stats
```http
GET /api/dashboard/stats
```
**Permission:** `inventory_dashboard.view` | `inventory.view`  
**Query:** web may send `startDate`, `lotId`, `grade` — **server currently ignores filters**.

**`data` fields (use these for KPI cards):**

| Field | Meaning |
|-------|---------|
| `lotsCount` | Total lots |
| `stockCount` | Sum of item `current_stock` |
| `productsWithStock` | Items with stock > 0 |
| `lowStockCount` | Below reorder |
| `movementIn30d` / `movementOut30d` | Last 30 days GRN in / stock-out qty |
| `gradeBreakdown` | `{ [grade]: { processed, available, sold } }` |
| `topProductsByStock[]` | `{ id, name, sku, productCode, currentStock, reorderLevel, unit, lowStock }` |
| `recentMovements[]` | `{ id, type, quantity, direction, absQty, itemName, itemSku, createdAt }` |
| `revenue` | Invoice amount total |
| `ordersCount` | Sales orders count |
| `itemsCount`, `customersCount`, `vendorsCount`, `purchasesCount` | Counts |
| `purchasesAmount`, `vendorReceivedQty` | Purchase totals |
| `invoiceSummary` / `billSummary` | `{ count, amount }` |
| `approvalsPendingCount` | Pending approvals |

### 4.2 Supporting calls (same as web widgets)
| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/lot?page=&limit=&filters=` | Lots table / filters |
| GET | `/api/inventory/reports/financial?months=1` | Financial snapshot |
| GET | `/api/inventory/low-stock` | Low-stock panel |

---

## 5. Products (Items)

**Web:** `/inventory/products?tab=products`

| Method | Path | Permission | Body / query |
|--------|------|------------|--------------|
| GET | `/api/items` | `product.view` \| `product.manage` \| `inventory.view` \| `bom.view` | `page`, `limit` (default 25, max 500), `search`/`q` |
| GET | `/api/items/next-product-code` | view/manage | — → `{ productCode }` |
| POST | `/api/items` | `product.manage` | JSON **or** multipart `image` + fields |
| PUT | `/api/items/:id` | `product.manage` | same |
| PATCH | `/api/items/:id/stock` | `product.manage` \| `inventory.manage` | `{ quantity ≥ 0, warehouseHint? }` |
| GET | `/api/items/:id/cost-history` | view/manage | `limit` 1–100 (default 25) |
| POST | `/api/items/import` | `product.manage` | `{ rows: object[] }` max 500 |

### Create / update body
**Required create:** `name`, `sku`, `unit`, `categoryId`  
**Optional:** `productCode`, `description`, `brandName`, `mrp`, `b2bPrice`, `productType`, `sourcing`, `visibility`, `status`, `sellingPrice`, `costPrice`, `reorderLevel`, `vendorId`, `rollLengthM`, `rollWidthMm`, `rollThicknessMic`, `productDimensions[]`, `openingStock`, `warehouseHint`

`productType` values: `FINISHED` (Physical), `CONVERTING` (Tape / roll product (converting)), `SERVICE` (Service), or `DIGITAL` (Digital).

`productDimensions[]` item: `{ key?, label, value?, unit? }`

### Item object (`data` / list row)
```json
{
  "id": 1,
  "productCode": "P-1001",
  "imageUrl": "/api/uploads/...",
  "name": "BOPP Tape",
  "sku": "tap-48",
  "description": null,
  "unit": "Nos",
  "categoryId": 3,
  "category": { "id": 3, "name": "Tape", "type": "...", "status": "ACTIVE", "hsnSac": "3919" },
  "hsnSac": "3919",
  "brandName": null,
  "mrp": 100,
  "b2bPrice": 80,
  "productType": "FINISHED",
  "sourcing": "BUY",
  "visibility": "PUBLIC",
  "sellingPrice": 90,
  "costPrice": 50,
  "reorderLevel": 20,
  "openingStock": 0,
  "currentStock": 120,
  "stocks": [{ "warehouseId": 1, "warehouseName": "Main", "quantity": 120 }],
  "status": "ACTIVE",
  "vendorId": null,
  "vendor": null,
  "productDimensions": [],
  "rollLengthM": null,
  "rollWidthMm": null,
  "rollThicknessMic": null
}
```

List response: `{ items: [...], pagination: { page, limit, total, totalPages } }`

Import summary: `{ created, approvals, failed, errors: [{ row, message }] }`

---

## 6. Product Categories

**Web:** `/inventory/products?tab=item-groups`

| Method | Path | Permission | Body |
|--------|------|------------|------|
| GET | `/api/categories` | `product_category.view` \| manage \| `product.view` \| manage | — |
| POST | `/api/categories` | `product_category.manage` \| `product.manage` | `{ name, type?, status?, hsnSac }` |
| PUT | `/api/categories/:id` | manage | partial |
| DELETE | `/api/categories/:id` | manage | may go to approval |

`hsnSac` is validated by HSN rules (`required` on create).  
Row: `{ id, name, type, status, hsnSac, createdAt, updatedAt }`

---

## 7. BOM

**Web:** `/inventory/bom`  
**Path used by web:** `/api/inventory/bom` (also available as `/api/bom`)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/bom` | All BOMs + `item` + `materials.item` |
| GET | `/api/bom/:id` | Single or 404 |
| POST | `/api/bom` | create |
| PUT | `/api/bom/:id` | update (materials replaced if sent) |
| DELETE | `/api/bom/:id` | delete |

**Create body:**
```json
{
  "itemId": 10,
  "description": "optional",
  "materials": [
    {
      "itemId": 2,
      "quantity": 1.5,
      "uom": "Kg",
      "scrapPct": 0,
      "consumptionFactor": 1,
      "componentType": "RM"
    }
  ]
}
```

**Lookup:** `GET /api/lookups/items?limit=1000`

---

## 8. Vendors

**Web:** `/inventory/purchase?tab=vendors`

| Method | Path | Permission | Notes |
|--------|------|------------|-------|
| GET | `/api/vendors` | `vendor.view` | `page`, `limit` → `{ vendors, pagination }` |
| GET | `/api/vendors/:id` | `vendor.view` | detail + docs |
| POST | `/api/vendors` | `vendor.manage` | multipart optional `panCard`, `aadharCard` |
| PUT | `/api/vendors/:id` | `vendor.manage` | fields only (no re-upload on web update) |
| POST | `/api/vendors/import` | `vendor.manage` | `{ rows }` max 500 |

**Required:** `name` (2–200), `email`, `phone` (10-digit IN, starts 6–9), `address` (min 3)  
**Optional:** `gstNumber`, `panNumber`, `tdsSectionCode`  
Creates/updates may return `approvalId`.

---

## 9. Purchase Demand

**Web:** `/inventory/purchase?tab=purchase-demand`

| Method | Path | Body / query |
|--------|------|--------------|
| GET | `/api/purchase-demands` | `page`, `limit`, `status?` → `{ data, pagination }` |
| POST | `/api/purchase-demands/:workOrderId/raise-purchases` | `{ vendorByItemId, persistVendorOnItems }` |
| GET | `/api/vendors` | vendor pickers |
| POST | `/api/approvals/approve` | `{ requestId, note? }` |
| POST | `/api/approvals/reject` | `{ requestId, note? }` |

Raise failure may return:
```json
{ "success": false, "message": "...", "missingVendors": [] }
```

Demand rows include `workOrderId`, `approvalRequestId`, shortage/item lines, status.

---

## 10. Purchase Orders

**Web:** `/inventory/purchase?tab=purchase-orders`

| Method | Path | Body |
|--------|------|------|
| GET | `/api/purchase` | `page`, `limit`, `q` (PO number) |
| POST | `/api/purchase` | see below |
| POST | `/api/purchase/import` | `{ rows }` max 500 |

**Create body:**
```json
{
  "vendorId": 5,
  "warehouseId": 1,
  "items": [
    {
      "itemId": 10,
      "orderedQty": 100,
      "price": 25.5,
      "unitCategory": null,
      "unitValue": null,
      "measureUnit": "Nos",
      "specifications": {},
      "length": null,
      "width": null,
      "thickness": null,
      "weight": null
    }
  ]
}
```
Aliases accepted: `quantity` / `qty` for ordered qty.

**Purchase row:**
```json
{
  "id": 1,
  "poNumber": "PO-...",
  "vendorId": 5,
  "vendor": { "id": 5, "name": "...", "email": "...", "phone": "..." },
  "warehouseId": 1,
  "warehouse": { "id": 1, "name": "Main", "address": null, "status": "ACTIVE" },
  "status": "CREATED",
  "totalAmount": 2550,
  "latestReceiveReceipt": null,
  "items": [ /* enriched lines */ ],
  "createdAt": "...",
  "updatedAt": "..."
}
```

Statuses include: `CREATED`, `RECEIVE_PENDING_APPROVAL`, `PARTIALLY_RECEIVED`, `RECEIVED`, `REJECTED`, `DRAFT`, etc.

---

## 11. Purchase Received

**Web:** `/inventory/purchase?tab=purchase-received`

| Method | Path | Body |
|--------|------|------|
| GET | `/api/purchase` | list |
| GET | `/api/warehouse` | warehouse picker |
| POST | `/api/purchase/:id/receive` | JSON or FormData |
| POST | `/api/purchase/:id/reject` | `{}` |
| GET | `/api/bills` | billed state |
| POST | `/api/accounts/bills/from-purchase` | `{ purchaseId }` |

**Receive body:**
```json
{
  "warehouseId": 1,
  "invoiceNumber": "INV-001",
  "items": [
    {
      "itemId": 10,
      "receivedQty": 90,
      "rejectedQty": 10,
      "rejectionReason": "DAMAGED"
    }
  ]
}
```
`rejectionReason` enum: `DAMAGED` | `SHORT` | `WRONG_SPEC` | `OTHER`  
Multipart field name: `invoicePhoto` → stored as `invoicePhotoUrl`.

Cannot reject if already received / receive pending approval / any `receivedQty > 0`.

---

## 12. Purchase Bills & payables

**Web:** `/inventory/purchase?tab=bills`

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/bills` | `page`, `limit`, `q` (bill_no) |
| GET | `/api/purchase`, `/api/vendors` | helpers |
| POST | `/api/accounts/bills` | manual bill (Accounts) |
| GET | `/api/vendor-payments` | `page`, `limit`, `q?`, `vendorId?`, `billId?` |
| POST | `/api/vendor-payments` | create payment → **201** |
| GET | `/api/vendor-credits` | list |
| POST | `/api/vendor-credits` | create credit → **201** |

**Bill row fields:** `id`, `billNo`, `purchaseId`, `vendorId`, `vendor`, `amount`, `paidAmount`, `creditedAmount`, `balanceAmount`, `status`, `vendorInvoiceNo`, `invoiceDate`, GST amounts, `reverseCharge`, `itcEligibility`, `lines[]`.

**Vendor payment body:**
```json
{
  "vendorId": 5,
  "amount": 1000,
  "billId": 12,
  "method": "Bank Transfer",
  "reference": "UTR...",
  "notes": "",
  "paidAt": "2026-09-21"
}
```
`method`: `Bank Transfer` | `UPI` | `Cheque` | `Cash`  
Need one of `billId` / `purchaseId` / `billNo`.

**Vendor credit body:** `{ vendorId, amount, billId|purchaseId|billNo, reason?, creditedAt? }`

**Manual Accounts bill body (web):**
```json
{
  "vendorId": 5,
  "vendor": "Name",
  "poNo": "",
  "vendorInvoiceNo": "",
  "invoiceDate": "2026-09-21",
  "dueDate": "2026-10-21",
  "notes": "",
  "reverseCharge": false,
  "itcEligibility": "ELIGIBLE",
  "lines": []
}
```

---

## 13. Inventory lots (Raw / Processed / Sellable)

### 13.1 Lot list (preferred for filters / Trace)
```http
GET /api/lot?page=1&limit=500&status=&q=&filters={"lotId":123}
```
**Permission:** `inventory.view`  
Triggers lot reconcile + financial backfill.

### 13.2 Lot list via inventory alias (Inventory tab)
```http
GET /api/inventory?page=1&limit=500&status=
```
Same lot shape; web Inventory tab uses this.

### Lot object
```json
{
  "id": 1,
  "lotId": 1,
  "lotNumber": "LOT-...",
  "itemId": 10,
  "item": { /* mapItem lite */ },
  "purchaseId": 3,
  "vendor": { "id": 5, "name": "..." },
  "warehouseId": 1,
  "warehouse": { "id": 1, "name": "Main" },
  "receivedQty": 100,
  "rawQty": 40,
  "processingQty": 10,
  "processedQty": 50,
  "availableQty": 90,
  "status": "RAW",
  "purchaseAmount": 0,
  "processingAmount": 0,
  "sellingAmount": 0,
  "profitAmount": 0,
  "grades": [{ "id": 1, "grade": "A", "quantity": 50, "availableQty": 50 }],
  "unitCategory": null,
  "unitValue": null,
  "measureUnit": null,
  "specifications": {},
  "createdAt": "...",
  "updatedAt": "..."
}
```

### Lot actions

| Method | Path | Permission | Body |
|--------|------|------------|------|
| GET | `/api/lot/:id/summary` | `inventory.view` | → `{ rawQty, processingQty, processedQty, batches }` |
| GET | `/api/lot/:id/processings` | `inventory.view` | processing batches |
| POST | `/api/lot/:id/start-processing` | `lot_processing.process` | `{ inputQty > 0, noteMessage? }` |
| POST | `/api/lot/processing/:processingId/complete` | `lot_processing.process` | `{ grades:[{grade,quantity}], processingCost?, noteMessage? }` |
| POST | `/api/lot/:id/send-for-selling` | `lot_processing.process` | `{ rawQty?, grades?, noteMessage? }` |
| POST | `/api/inventory/direct-stock/allocate` | `inventory.manage` \| `lot_processing.process` | see below |

**Allocate direct stock (web Inventory modal):**
```json
{
  "itemId": 10,
  "quantity": 5,
  "warehouseId": 1,
  "destination": "processed",
  "noteMessage": "Required note"
}
```
`destination`: `"processed"` | `"sellable"`  
Response: `{ lotId, lotNumber, destination, quantity, status }`

### Processing batch object
```json
{
  "id": 9,
  "lotId": 1,
  "batchNumber": "...",
  "inputQty": 10,
  "outputQty": null,
  "status": "IN_PROGRESS",
  "processingCost": 0,
  "grades": [],
  "createdAt": "...",
  "completedAt": null
}
```

### Sellable Inventory tab
- `GET /api/lot?page=1&limit=500` — filter client-side `SELLING` / `SELLING_APPROVAL_PENDING`
- `GET /api/sales?page=1&limit=200` — pending orders (`PENDING_APPROVAL`) to mark reserved lots

### Processed lots & FG tab (extra Production APIs)
| Method | Path | Body |
|--------|------|------|
| GET | `/api/production/work-orders` | `page`, `limit` |
| POST | `/api/production/work-orders/:id/finish-from-qc` | QC + `acceptedQty`, `packedQty`, `warehouse`, `receiptNo?` |
| POST | `/api/production/work-orders/:id/complete` | if FG already posted |

---

## 14. Stock movements

### 14.1 Stock IN
```http
POST /api/inventory/stock-in
```
**Permission:** `inventory.manage` | `product.manage`

```json
{
  "itemId": 10,
  "warehouseId": 1,
  "quantity": 25,
  "unitCost": 50,
  "referenceNo": "REF-1",
  "notes": "optional"
}
```
`quantity` must be a **positive integer**.

### 14.2 Stock OUT
```http
POST /api/inventory/stock-out
```

```json
{
  "itemId": 10,
  "warehouseId": 1,
  "quantity": 5,
  "referenceNo": "",
  "notes": "",
  "generateBill": true,
  "customerId": 3,
  "partyName": "Buyer Pvt Ltd",
  "partyGstin": "27AAAAA0000A1Z5",
  "partyPhone": "9876543210",
  "partyEmail": "a@b.com",
  "partyAddress": "...",
  "partyCity": "...",
  "partyState": "...",
  "partyPincode": "400001",
  "deliveryLocation": "",
  "paymentTerms": "",
  "buyerOrderNo": "",
  "destination": "",
  "vehicleNo": "",
  "otherReferences": "",
  "unitRate": 100,
  "gstRate": 18,
  "hsnSac": "3919"
}
```

If `generateBill` is true (default): **partyName**, **unitRate > 0**, and valid **GSTIN** are required; phone/email/pincode validated when present.

**Web Stock OUT product picker is not the full catalog.** Eligible SKUs = sellable lots + processed lots + FG work orders with qty (web loads `/api/items`, `/api/inventory`, `/api/production/work-orders`).

**Success `data`:**
```json
{
  "transactionId": 1,
  "itemId": 10,
  "itemName": "...",
  "warehouseId": 1,
  "warehouseName": "Main",
  "quantity": 5,
  "signedQuantity": -5,
  "type": "STOCK_OUT",
  "currentStock": 115,
  "referenceNo": null,
  "notes": null,
  "createdAt": "...",
  "bill": { "id": 1, "billNo": "SOB-..." }
}
```

### 14.3 Per-item warehouse stock (chips)
```http
GET /api/inventory/stock-out/warehouse-stock?itemId=10
```

### 14.4 Stock OUT Bills
| Method | Path |
|--------|------|
| GET | `/api/inventory/stock-out/bills?page=&limit=` |
| GET | `/api/inventory/stock-out/bills/:id` |

**Bill fields used by web:** `billNo`, `partyName`, `itemName`, `quantity`, `totalAmount`, `paymentStatus`, `warehouseName`, `createdAt`

**Payments (Accounts):**
| Method | Path | Body |
|--------|------|------|
| GET | `/api/accounts/payments-received` | — |
| POST | `/api/accounts/payments-received` | `{ customer, billNo, amount, method, receivedAt, note }` |

### 14.5 Stock transfer (API ready; not used by Inventory UI today)
```http
POST /api/inventory/stock-transfer
```
```json
{
  "itemId": 10,
  "fromWarehouseId": 1,
  "toWarehouseId": 2,
  "quantity": 5,
  "referenceNo": "",
  "notes": ""
}
```
**Permission:** `inventory.transfer` | `inventory.manage`

---

## 15. Warehouses

**Web:** `/inventory/inventory?tab=warehouses`

| Method | Path | Body |
|--------|------|------|
| GET | `/api/warehouse` | `page`, `limit` → `{ data, pagination }` |
| POST | `/api/warehouse` | `{ name, address?, status?: "ACTIVE"|"INACTIVE" }` |
| PUT | `/api/warehouse` | `{ id, name, address?, status? }` |

Duplicate name → **409**.  
Row: `{ id, name, address, status, createdAt, updatedAt, createdBy, updatedBy, createdByName, updatedByName }`

---

## 16. Movement Ledger (Adjustments)

**Web:** `/inventory/inventory?tab=adjustments`

```http
GET /api/inventory/transactions?page=1&limit=500&direction=&type=&itemId=
```
**Permission:** `inventory.view`  
`direction`: `in` | `out`  
`limit` max **500**

**Row:**
```json
{
  "id": 1,
  "itemId": 10,
  "itemName": "...",
  "itemSku": "...",
  "productCode": "...",
  "type": "STOCK_IN",
  "quantity": 25,
  "direction": "IN",
  "warehouseId": 1,
  "warehouseName": "Main",
  "referenceId": null,
  "referenceNo": "SJ-12",
  "notes": null,
  "createdAt": "..."
}
```
Legacy `STOCK_TRANSFER` with qty `0` is expanded into OUT + IN rows.

---

## 17. Reports

### 17.1 Stock report (in-module tab)
```http
GET /api/inventory/report
```
**Permission:** `inventory_report.view`  
Array of `{ id, name, sku, unit, currentStock, reorderLevel }`

### 17.2 Low stock
```http
GET /api/inventory/low-stock
```
**Permission:** `inventory_report.view` | `inventory.view`  
Mapped items (same item shape as list).

### 17.3 Warehouse stock (all)
```http
GET /api/inventory/warehouse-stock
```
**Permission:** `inventory_report.view`  
`[{ id, itemId, item, warehouseId, warehouse, quantity }]`  
Defined in web service; not currently called from Inventory pages (dashboard/stock lookup may use related endpoints).

### 17.4 Financial report
```http
GET /api/inventory/reports/financial?months=12
```
`months`: number or `all`  
**Fields used by web:**  
`period`, `purchaseCost`, `purchaseCount`, `stockOutSubtotal`, `stockOutBillCount`, `stockOutGst`, `stockOutQty`, `stockOutCogs`, `stockOutGrossProfit`, `totalRevenueExGst`, `totalRevenueWithGst`, `netProfitEstimate`, `inventoryValueAtCost`, `inventoryValueAtB2b`, `inventoryUnits`, `byProduct[]`

### 17.5 Full Reports page
**Web:** `/inventory/reports` — combines dashboard stats + stock report + transactions + low stock + financial + lots.

---

## 18. Documents

**Web:** `/inventory/documents`

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/documents` | `page`, `limit`, `lotId?`, `startDate?`, `q?` |
| POST | `/api/documents` | multipart `file` **or** JSON `{ url }` |

**Create FormData:** `name` (required), `type?`, `lotId?`, `file`  
**Row:** `{ id, lotId, processingId, vendorId, type, name, url, createdAt, updatedAt }`  
Resolve `url` with API origin (same as web `resolveUploadUrl`).

---

## 19. Approvals (Inventory)

Used heavily by purchase demand and many write flows.

All are **POST** under `/api/approvals/...`

| Path | Permission | Body |
|------|------------|------|
| `/list` | `approval.view` \| `myApproval.view` | `{ page?, limit?, status?, type? }` |
| `/approve` | `approval.approve` \| `myApproval.view` | `{ requestId, note?, data? }` |
| `/reject` | `approval.reject` \| `approval.approve` | `{ requestId, note? }` |
| `/forward` | `approval.forward` | `{ requestId, forwardToUserId (uuid), note? }` |
| `/my-requests` | `approval.view` | `{ page?, limit? }` |
| `/my-pending` | `myApproval.view` | same as list |
| `/my-resubmit` | `myApproval.view` | `{ requestId }` |
| `/my-update` | `myApproval.view` | `{ requestId, data: {} }` |

**Approval types you will see from Inventory:**  
`PURCHASE_CREATE`, `PURCHASE_RECEIVE`, `ITEM_CREATE`/`ITEM_UPDATE`, `VENDOR_CREATE`/`VENDOR_UPDATE`, `CUSTOMER_CREATE`/`CUSTOMER_UPDATE`, `SALES_CREATE`, `LOT_PROCESSING_START`, `LOT_PROCESSING_COMPLETE`, `LOT_SEND_FOR_SELLING`, category delete, etc.

---

## 20. Sales APIs still on Inventory router (legacy)

Web Inventory sales tabs **redirect to Sales CRM**, but these endpoints remain and match older Inventory sales pages:

| Method | Path | Permission | Body / notes |
|--------|------|------------|--------------|
| GET | `/api/customers` | `customer.view` | `page`, `limit`, `q` → `{ customers, pagination }` |
| POST | `/api/customers` | `customer.manage` | see customer body |
| PUT | `/api/customers/:id` | `customer.manage` | same |
| DELETE | `/api/customers/:id` | `customer.manage` | hard delete |
| GET | `/api/sales` | `sales_order.view` | `q` on invoice_no |
| POST | `/api/sales` | `sales_order.manage` | lot-based lines |
| POST | `/api/sales/auto` | `sales_order.manage` | MRP auto flow |
| POST | `/api/sales/:id/fulfill` | `sales_order.manage` | deduct stock → COMPLETED |
| GET | `/api/invoices` | `invoice.view` | `page`, `limit`, `q` |

**Customer body:** `name` required; optional `email`, `phone`, `address`, `gstNumber`, `panNumber`, `gstSlabId`, `bankAccountHolder`, `bankName`, `bankAccountNo`, `bankIfsc`, `bankBranch`  
GST slabs: `GET /api/accounts/gst-slabs?activeOnly=true`

**Sales create (lot-based):**
```json
{
  "customerId": 3,
  "items": [{ "lotId": 1, "gradeId": null, "quantity": 2, "price": 100 }]
}
```

**Sales auto:**
```json
{
  "customerId": 3,
  "items": [{ "itemId": 10, "quantity": 5, "price": 100 }]
}
```

**Related Accounts (legacy Inventory sales screens):**  
`/api/accounts/payments-received`, `/api/accounts/credit-notes`, `/api/accounts/sales-returns`, `PATCH /api/accounts/sales-returns/:id/status`

---

## 21. Legacy production (Inventory router)

| Method | Path | Body |
|--------|------|------|
| GET | `/api/production` | list `ProductionOrder` |
| POST | `/api/production` | `{ itemId, quantity }` → DRAFT |
| POST | `/api/production/:id/complete` | `{ rmWarehouse?, fgWarehouse?, workOrderId? }` |

Prefer Production module work-order APIs for FG flows (see §13).

---

## 22. Inventory Accounts (embedded section)

**Web:** `/inventory/accounts` embeds Accounts Inventory APIs:

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/accounts/inventory/stock-reconciliation` | qty × cost vs ledgers |
| GET | `/api/accounts/inventory/stock-journals` | `limit`, `journalType` |
| POST | `/api/accounts/inventory/stock-journals` | `TRANSFER` \| `SHORTAGE` \| `SURPLUS` |
| GET | `/api/accounts/inventory/godown-stock-valuation` | valuation |

---

## 23. Suggested mobile screen → API checklist

Implement screens in this order for web parity:

| # | Mobile screen | Primary APIs |
|---|---------------|--------------|
| 1 | Dashboard | `GET /dashboard/stats`, low-stock, financial, lots |
| 2 | Stock Lookup | `GET /items`, warehouse-stock by item |
| 3 | Products | items CRUD + import + next-code + cost-history |
| 4 | Categories | categories CRUD |
| 5 | Warehouses | warehouse CRUD |
| 6 | Stock IN / OUT | stock-in, stock-out, warehouse-stock chips, customers |
| 7 | Stock OUT Bills | bills list/detail + payments-received |
| 8 | Movement Ledger | transactions |
| 9 | Inventory lots | `/inventory` or `/lot` + allocate + start-processing + send-for-selling |
| 10 | Processed / FG | processings complete + production work-orders |
| 11 | Sellable | lots + sales list |
| 12 | Vendors | vendors CRUD + import |
| 13 | Purchase Orders | purchase create/list/import |
| 14 | Purchase Received | receive / reject + bill from purchase |
| 15 | Purchase Demand | purchase-demands + approvals |
| 16 | Bills / Payments | bills + vendor-payments + vendor-credits |
| 17 | BOM | bom CRUD + lookups/items |
| 18 | Documents | documents GET/POST |
| 19 | Reports | report + financial + low-stock + transactions |
| 20 | Approvals | approvals POST actions |

**Do not implement (web stubs / no API):** Price Lists, Packages, Shipments.

---

## 24. Path aliases (do not mix)

| Prefer (web) | Also works | Avoid |
|--------------|------------|-------|
| `/api/inventory/stock-in` | `/api/inventory/inventory/stock-in` | confusing double mount |
| `/api/items` | `/api/inventory/items` | — |
| `/api/lot` | `/api/inventory/lot` | — |
| `/api/bom` or `/api/inventory/bom` | both | web BOM uses `/inventory/bom` relative to base |

Rule: copy paths from `frontend-erp-system/src/config/api.js` / service files exactly.

---

## 25. Common client unwrap helpers

Web unwraps several shapes — mobile should mirror:

```text
payload.data                          // object or array
payload.data.data                     // paginated lists
payload.data.items / vendors / customers
payload.approvalId                    // pending approval
Array.isArray(payload)                // rare
```

On write success with `approvalId`, show “Sent for approval” (same as web toasts) instead of treating empty `data: []` as failure.

---

## 26. Endpoint index (Inventory router)

| Area | Count (approx) |
|------|----------------|
| Items | 7 |
| Categories | 4 |
| Vendors | 5 |
| BOM | 5 |
| Approvals | 8 |
| Stock movements | 6 |
| Payables | 4 |
| Dashboard / warehouse / purchase / bills / customers / sales / lots / documents / inventory reports / production | ~40 |
| Lookups (inventory-related) | 4 |
| Accounts inventory | 4 |

---

*Generated to match live web Inventory behavior. Prefer this file over partial MVP docs when building full Inventory on mobile. For dashboard KPI field details see `Inventory_Dashboard_Mobile_APIs.md`; for stock-search-only MVP see `Inventory_Stock_Lookup_Mobile_APIs.md`.*
