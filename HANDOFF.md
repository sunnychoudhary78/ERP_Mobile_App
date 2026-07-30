# Immortal ERP Mobile — Junior Handoff

Foundation only: **auth works**, all must screens are stubs. Implement features one screen at a time.

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

Already wired like LMS:

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

## How to implement a feature

1. Open the stub screen under `lib/features/<module>/presentation/screens/`
2. Add `data/` next to it: `*_api_service.dart` + models
3. Add Riverpod provider under `presentation/providers/`
4. Replace `PlaceholderScreen` with real UI
5. Reuse `apiServiceProvider` / endpoints in `lib/core/network/api_endpoints.dart`

## Suggested build order

1. Punch + Leave + Approvals inbox (HRMS APIs exist)
2. Complete Sales CRM (leads → visits) — **backend CRM module not ready yet**; endpoints are placeholders under `crm/...`
3. Stock lookup + Work order status + Notifications polish

## Out of scope (for now)

- Auth settings / permissions UI
- Accounts, Assets
- Billing create, deep inventory/production, deeper HRMS

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
