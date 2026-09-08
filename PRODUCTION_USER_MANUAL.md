# Immortal ERP Mobile
## Production User Manual

**Audience:** Production operators, shop-floor supervisors, and QC users  
**Module:** Production  
**Document status:** Based on the current mobile app build

## 1. Purpose

Use the Production module to monitor work orders, review order details, record shop-floor output, track scrap, move an order between production steps, place an order on QC hold, release a hold, and complete an order.

The app is a mobile operational view. Your company ERP and backend remain the system of record.

## 2. Before You Start

You need:

- An active ERP employee account.
- Production-module permission assigned by your administrator.
- A working internet connection when loading or saving data.
- The correct environment selected by your IT or system administrator.

Only users with the required permission see Production links or can open Production screens. If Production is missing from the menu, contact your administrator rather than creating a second account.

## 3. Sign In and Open Production

1. Open the app.
2. Sign in with your email address or employee ID and password.
3. On the home dashboard, open the menu using the menu icon.
4. Under **Production**, choose **Dashboard** or **Orders**.

Use **Dashboard** for a quick operational summary. Use **Orders** to find and open a specific work order.

To leave the app, use the logout icon on the home dashboard. Do not use logout while an action is still saving.

## 4. Production Dashboard

The dashboard loads the latest production summary when opened.

### Production Units Breakdown

This section shows work orders grouped into:

- **In Process:** Orders currently being worked.
- **Completed:** Orders marked finished.
- **Material Shortage:** Orders affected by missing material.
- **QC Hold:** Orders waiting for a quality decision.

Tap the section or **See All** to open the Work Orders list.

### Production Stage Overview

This section shows counts for:

- **Released**
- **In Production**
- **QC Hold**
- **Completed**

It also shows a production-efficiency percentage calculated from the displayed released, in-production, QC-hold, and completed counts. Treat this as an operational indicator, not as a replacement for the approved production report.

### Refreshing the dashboard

Pull down on the dashboard to refresh it. If a refresh fails after data has already loaded, the app keeps showing cached data and displays a refresh warning. Verify the connection and try again before making an operational decision.

## 5. Find a Work Order

1. Open **Production > Orders**.
2. Review the list of open work orders.
3. Use the search box to search by:
   - Work order number.
   - Item name.
   - Customer name.
4. Tap a work-order card to open its details.
5. Pull down on the list to refresh the open-order data.
6. Use the clear icon in the search box to remove the search term.

If the list says **No Open Work Orders**, there are currently no orders returned as open. If it says **No matches found**, broaden or clear the search.

Completed, cancelled, QC-passed, and finished-goods-received orders are excluded from the open-order list. An order can therefore disappear from this list after a status-changing action.

## 6. Read Work Order Details

The Work Order Details screen can contain:

- Work-order number and current status.
- Active production step.
- Item and required quantity.
- Warehouse and factory.
- Production stages and each stage's output and scrap quantities.
- Execution logs, including operator, timestamp, note, output, and scrap.
- Due date and priority.
- Source document and customer.

Pull down on the detail screen to reload the order. If loading fails, choose **Retry**. Check the work-order number before reporting a problem so support can identify the exact order.

## 7. Record Shop-Floor Execution

The Shop Floor screen records an execution entry against a work order.

### Enter the execution data

1. Enter the **Operator name**. This field is required.
2. Enter the **Machine / line**. This field is required.
3. Enter **Output qty** for the quantity produced in this entry.
4. Enter **Scrap qty** for the quantity rejected or scrapped in this entry.
5. Enter an optional **Note**, such as `Started production`, a downtime reason, or a handover note.
6. For each listed stage:
   - Tick the checkbox when the stage is complete.
   - Enter that stage's output quantity.
   - Enter that stage's scrap quantity.
7. Choose **Log Execution**.

The app shows **Execution logged** when the save succeeds. A failed save shows an error; correct the data or connection problem and submit again. Do not repeatedly submit if the first attempt may have succeeded. Refresh the work order and check the Execution Logs first.

Logging execution can move a work order toward **IN_PROCESS**. When all stages are complete with output greater than zero, the backend may move the order toward QC hold according to the configured workflow.

### Move the active step

Use the **Move Step** section when the order must be explicitly assigned to the next workflow step:

- Demand
- Shop Floor
- QC
- Release

Select the correct **Active step**, then choose **Move Step**. Confirm the success message before leaving the screen. Only move an order when the physical or quality process has actually reached that step.

## 8. QC and Completion

The QC / Completion screen provides three different actions. Choose carefully because they have different business meanings.

### Place an order on QC hold

Use **Hold** when quality inspection has identified a problem or the order must wait for a QC decision.

1. Enter an optional remark describing the issue.
2. Choose **Hold**.
3. Confirm the success message and verify that the status is **QC_HOLD**.

QC hold is for quality control only. It is not a general shop-floor pause.

### Release a QC hold

Use **Release Hold** only after the quality issue or inspection requirement has been resolved.

1. Enter an optional remark if needed.
2. Choose **Release Hold**.
3. Confirm the success message.

The button is available only when the order is currently on QC hold.

### Finish from QC

Use **Finish from QC** for the normal completion path when the order has gone through QC. This is the preferred action for an order that requires quality control before completion.

1. Complete the inspection and record any required remark.
2. Choose **Finish from QC**.
3. Verify the resulting status in the order details or after returning to the list.

### Complete (skip QC check)

Use **Complete (skip QC check)** only when your approved business process allows completion without a prior QC check. The app asks for confirmation because this action may issue materials and post finished goods and does not verify that QC was completed.

Do not use this action to bypass a required inspection. When QC is required, use **Finish from QC** instead.

## 9. Status Guide

| Status | Meaning | Typical action |
|---|---|---|
| `DEMAND_OPEN` | Demand has been created but production has not started. | Review demand and prepare the order. |
| `IN_PROCESS` | Work is being executed. | Record output, scrap, notes, and stage completion. |
| `QC_HOLD` | The order is waiting on a quality decision. | Inspect, add a remark, then release or finish from QC. |
| `QC_PASSED` | QC has passed. | Follow the configured release/completion process. |
| `COMPLETED` | The work order is complete. | No further shop-floor execution should be recorded. |
| `FG_RECEIVED` | Finished goods have been received. | Follow warehouse or inventory procedures. |
| `CANCELLED` | The work order has been cancelled. | Do not continue production against it. |

The exact next action may depend on your company workflow and your user permission.

## 10. Data Entry Rules

- Use the actual operator name and machine or line used for the work.
- Enter quantities for the current execution entry, not the entire order, unless your supervisor instructs otherwise.
- Record scrap separately from good output.
- Use notes for information the next operator or supervisor needs.
- Check the work-order number and item before saving.
- Do not mark a stage complete until the stage is physically complete.
- Do not use QC hold for ordinary machine downtime or a break.
- Do not use **Complete (skip QC check)** when QC is required.

## 11. Connection, Loading, and Save Problems

### A screen keeps loading

Check the network connection, wait for the current request to finish, and pull down to refresh. If the problem continues, note the work-order number and contact support.

### The dashboard shows cached data

The warning means the latest refresh did not complete. Do not assume the counts are current. Retry when connected.

### A work order is missing

Clear the search, refresh the list, and confirm that the order is not already completed, cancelled, QC-passed, or finished-goods-received. If it still does not appear, ask a supervisor to confirm the order exists and that your account has access.

### An action fails

Read the displayed error, verify required fields, and confirm that you have a connection. Refresh the order before trying again so you do not duplicate a successful action. Escalate with the work-order number, action attempted, time, and error message.

### Permission denied or Production is not visible

Ask an administrator to verify your Production permission. Do not change permissions on the device or attempt to use another employee's account.

## 12. Current Build Notes

In the current mobile build:

- The reachable Production workflow is **Dashboard -> Orders -> Work Order Details**.
- The Shop Floor and QC / Completion screens are implemented in the app, but the Work Order Details screen does not currently expose a visible Start Production or QC navigation button, and these screens are not registered as named routes.
- If your organization expects operators to record execution or perform QC from mobile, the app administrator or development team must expose those screens in the production navigation before this part of the procedure can be used by ordinary operators.
- The dashboard's Production Overview area currently has no visible KPI tiles. Use the Units Breakdown and Production Stage Overview sections for the available summary information.

This section describes the current software behavior, not a recommended business process. Confirm the enabled workflow with your implementation team before rollout.

## 13. Support Checklist

When reporting a problem, provide:

- Your employee ID or account name.
- Work-order number.
- Screen and action, for example `QC / Completion - Release Hold`.
- Date and time of the attempt.
- Exact error text.
- Whether the order was refreshed before retrying.

Never include your password in a support request.
