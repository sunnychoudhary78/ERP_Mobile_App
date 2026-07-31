# Immortal ERP Mobile — Junior Handoff

**Auth + Punch + HRMS logic** are ready. Build polished UI on the wired providers.

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
| Approvals | `/approvals` | Done — `approvalsInboxProvider` (leave only) | Thin stub — polish UI |
| Notifications | `/notifications` | Done — `notificationProvider` | Thin stub — polish UI |

### Provider cheat sheet

| Screen | Watch | Actions |
|--------|-------|---------|
| Leave balance | `leaveBalanceProvider` | `.notifier.refresh()` |
| Leave apply | `leaveBalanceProvider`, `leaveApplyProvider` | `.notifier.submitLeave(data:, document:)` then `.reset()` |
| Leave status | `leaveStatusProvider` | `.notifier.revokeLeave(id)`, details via `leaveDetailsProvider(id)` |
| Approvals | `approvalsInboxProvider` | `.notifier.approveLeave(item, comment:, dates:)`, `.rejectLeave(item, comment:)` |
| Notifications | `notificationProvider`, `unreadCountProvider` | `.notifier.markAsRead(id)`, `.deleteNotification(id)` |

Leave apply payload keys: `leaveTypeId`, `startDate`, `endDate`, `isHalfDay`, `halfDayPart`, `reason` (+ optional document file).

Endpoints live in [`lib/core/network/api_endpoints.dart`](lib/core/network/api_endpoints.dart).

## Suggested UI build order

1. Leave balance → leave apply → leave status
2. Approvals inbox (approve / reject + comment)
3. Notifications polish
4. Later: CRM (leads → visits) — **backend CRM module not ready yet**
5. Later: stock lookup + work order status

## Out of scope (for now)

- Auth settings / permissions UI
- Accounts, Assets
- Billing create, deep inventory/production, deeper HRMS (payroll, recruitment, …)
- CRM approvals (endpoint placeholder only)

## Must routes (Home quick links)

| Route | Screen |
|-------|--------|
| `/punch` | Attendance punch |
| `/leave-balance` `/leave-apply` `/leave-status` | Leave |
| `/approvals` | Approvals inbox |
| `/notifications` | Notifications |
| `/crm/leads` `/detail` `/form` | Leads |
| `/crm/contacts` … | Contacts |
| `/crm/customers` … | Customers |
| `/crm/pipeline` | Pipeline |
| `/crm/activities` | Activities |
| `/crm/quotes` … | Quotes |
| `/crm/visits` `/crm/tracking` | Visits + tracking |
| `/stock-lookup` | Stock lookup |
| `/work-orders` | Work orders |
