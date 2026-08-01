# Immortal ERP Mobile — Junior Handoff

**Auth + Punch + HRMS logic + Sales CRM logic** are ready. Build polished UI on the wired providers.

## Run

```bash
cd erp_app
flutter pub get
flutter run
```

## Switch API environment

Edit [`lib/core/network/api_constants.dart`](lib/core/network/api_constants.dart):

```dart
static Environment current = Environment.local; // local | uat | prod
```

- **local:** `http://localhost:3004/api`
- **Android emulator:** change localhost → `10.0.2.2` (maps to host machine)
- **Physical device:** use your PC LAN IP, e.g. `http://192.168.x.x:3004/api`

**Sales CRM** needs a backend with the **sales module** (`/api/sales/*`) — use **dev/UAT**, not an old `main` backend without Sales CRM.

## Auth (do not rebuild)

Already wired:

- Login: email **or** employee ID + password → `POST auth/login`
- JWT in `FlutterSecureStorage`
- Dio Bearer header + AES `{ payload }` encrypt/decrypt
- Auto-login on cold start (`employees/single` + `auth/permissions`)
- Logout clears JWT and restarts `ProviderScope`
- Permissions stored in `authProvider` state — **no Roles/Permissions UI**

Key files:

- `lib/features/auth/`
- `lib/core/network/`
- `lib/app/app_root.dart`

## How to implement UI for a feature

1. Open the screen under `lib/features/<module>/presentation/screens/`
2. Watch the existing Riverpod provider (already loads data)
3. Replace the thin list / TODO text with real widgets
4. Call notifier methods for actions (submit, approve, withdraw, mark read)
5. Do **not** add new Dio calls — use `data/` + providers

## HRMS status

| Feature | Route | Logic | UI |
|---------|-------|-------|----|
| Punch | `/punch` | Done | Done |
| Leave balance | `/leave-balance` | Done — `leaveBalanceProvider` | Thin stub — polish UI |
| Leave apply | `/leave-apply` | Done — `leaveApplyProvider` + balances | Thin stub — build form |
| Leave status | `/leave-status` | Done — `leaveStatusProvider`, `leaveDetailsProvider` | Thin stub — polish UI |
| Approvals (leave) | `/approvals` | Done — `approvalsInboxProvider` | Thin stub — polish UI |
| Notifications | `/notifications` | Done — `notificationProvider` | Thin stub — polish UI |

### HRMS provider cheat sheet

| Screen | Watch | Actions |
|--------|-------|---------|
| Leave balance | `leaveBalanceProvider` | `.notifier.refresh()` |
| Leave apply | `leaveBalanceProvider`, `leaveApplyProvider` | `.notifier.submitLeave(data:, document:)` then `.reset()` |
| Leave status | `leaveStatusProvider` | `.notifier.revokeLeave(id)`, details via `leaveDetailsProvider(id)` |
| Approvals | `approvalsInboxProvider` | `.notifier.approveLeave(item, comment:, dates:)`, `.rejectLeave(item, comment:)` |
| Notifications | `notificationProvider`, `unreadCountProvider` | `.notifier.markAsRead(id)`, `.deleteNotification(id)` |

Leave apply payload keys: `leaveTypeId`, `startDate`, `endDate`, `isHalfDay`, `halfDayPart`, `reason` (+ optional document file).

## Sales CRM status (web: Sales → Sales CRM)

Primary load: `GET /api/sales/workspace` via `salesWorkspaceProvider`.

| Feature | Route | Logic | UI |
|---------|-------|-------|----|
| Leads | `/crm/leads` `/detail` `/form` | Done — `crmLeadsProvider` | Thin stub |
| Pipeline | `/crm/pipeline` | Done — `crmPipelineProvider` | Thin stub |
| Follow-ups | `/crm/activities` | Done — `crmActivitiesProvider` | Thin stub |
| CRM Approvals | `/crm/approvals` | Done — `crmApprovalsProvider` | Thin stub |
| Contacts | `/crm/contacts` … | Done — derived `crmContactsProvider` | Thin stub |
| Customers | `/crm/customers` … | Done — `crmCustomersProvider` (`/api/customers`) | Thin stub |
| Quotes | `/crm/quotes` … | Done — `crmQuotesProvider` | Thin stub |
| Visits | `/crm/visits` | Done — check-in + `crmVisitsProvider` | Thin stub |
| Team tracking | `/crm/tracking` | Done — visits list (map UI pending) | Thin stub |
| Orders / Billing | — | **Deferred** (web-only for now) | — |

Shared code: `lib/features/crm/shared/` (`sales_crm_api_service.dart`, models, `sales_workspace_provider.dart`).

### Sales CRM provider cheat sheet

| Screen | Watch | Actions (`salesWorkspaceProvider.notifier`) |
|--------|-------|-----------------------------------------------|
| Leads | `crmLeadsProvider` | `createLead`, `updateLead`, `qualifyLead`, `markWon`/`markLost`, `ensureCustomer`/`linkCustomer` |
| Pipeline | `crmPipelineProvider` | same lead mutations |
| Follow-ups | `crmActivitiesProvider` | `logFollowUp`, `completeActivity` |
| Approvals | `crmApprovalsProvider` | `approveWon`/`rejectWon`, `approveQuote`/`rejectQuote` |
| Contacts | `crmContactsProvider` | edit via lead `updateLead` |
| Customers | `crmCustomersProvider` | refresh; link via lead helpers |
| Quotes | `crmQuotesProvider` | `createQuote`, `updateQuote`, `sendQuote`, approve/reject |
| Visits | `crmVisitsProvider` | `checkInVisit(payload)` |

Endpoints: [`lib/core/network/api_endpoints.dart`](lib/core/network/api_endpoints.dart) (`sales/*`, `customers`).

## Suggested UI build order

1. Leave balance → leave apply → leave status → leave approvals → notifications
2. Sales CRM: leads → pipeline → follow-ups → quotes → visits → contacts/customers → CRM approvals
3. Later: stock lookup + work order status
4. Later: Orders / Billing (web Sales CRM tabs — not wired on mobile yet)

## Out of scope (for now)

- Auth settings / permissions UI
- Accounts, Assets
- Sales CRM Orders / Billing mobile screens
- Deep inventory/production, deeper HRMS (payroll, recruitment, …)

## Must routes (Home quick links)

| Route | Screen |
|-------|--------|
| `/punch` | Attendance punch |
| `/leave-balance` `/leave-apply` `/leave-status` | Leave |
| `/approvals` | Leave approvals inbox |
| `/notifications` | Notifications |
| `/crm/leads` `/detail` `/form` | Leads |
| `/crm/pipeline` | Pipeline |
| `/crm/activities` | Follow-ups |
| `/crm/approvals` | CRM approvals |
| `/crm/contacts` … | Contacts |
| `/crm/customers` … | Customers |
| `/crm/quotes` … | Quotes |
| `/crm/visits` `/crm/tracking` | Visits + tracking |
| `/stock-lookup` | Stock lookup |
| `/work-orders` | Work orders |
