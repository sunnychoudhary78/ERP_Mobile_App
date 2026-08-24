# Immortal ERP Mobile App Report

**Prepared:** 24 August 2026  
**Platform:** Flutter / Dart 3.10.8  
**Version:** 1.0.0+1

## 1. Executive Summary

Immortal ERP Mobile is a Flutter client for ERP operations across authentication, HRMS, attendance, Sales CRM, inventory, and production. The application has a feature-first structure, Riverpod state management, centralized Dio networking, JWT session handling, secure token storage, encrypted API payloads, and Android/iOS/web/desktop platform targets.

The main business logic is substantially wired. HRMS and CRM providers expose the expected load and mutation operations, attendance supports location and selfie-based punch actions, inventory supports stock and reporting workflows, and production supports work-order execution and QC flows. The current delivery is best described as **functionally integrated but not release-ready**: several screens remain thin or incomplete, automated coverage is limited, and there are release/security issues that should be addressed before production distribution.

## 2. Current Verification

| Check | Result | Notes |
|---|---|---|
| `flutter analyze` | Completed with no blocking analyzer errors | There are numerous infos/warnings, including deprecated APIs, dead code, unused elements, and null-safety cleanup items. |
| `flutter test` | Passed | The default test suite reports all tests passing. |
| Test discovery | Limited | One test is in `test/`; the production work-order test is under `lib/test/`, outside the conventional test location. |
| Release build | Not run in this review | Signing and application identity still require release configuration. |

## 3. Architecture

- **Application shell:** `MaterialApp`, global navigator key, app theme, splash/loading state, subscription-expired state, and restartable `ProviderScope` are defined in [main.dart](lib/main.dart) and [app_root.dart](lib/app/app_root.dart).
- **State management:** Riverpod is used across the application. Newer features use `Notifier`/`AsyncNotifier`; production also contains legacy `StateNotifier` patterns.
- **Feature organization:** Most modules separate models/API services, repositories or providers, and presentation screens under `lib/features/`.
- **Networking:** [dio_client.dart](lib/core/network/dio_client.dart) and [api_service.dart](lib/core/network/api_service.dart) centralize authorization headers, encryption/decryption, timeouts, multipart requests, common errors, and subscription handling.
- **Routing:** Named routes are centralized in [app_routes.dart](lib/app/app_routes.dart). Permission checks are implemented through [permission_gate.dart](lib/shared/widgets/permission_gate.dart), but route protection is not applied consistently.
- **Configuration:** API environments and base URLs are controlled through [api_constants.dart](lib/core/network/api_constants.dart). The handoff documents local, Android emulator, physical-device, UAT, and production usage.

## 4. Implemented Capability

### Authentication and session management

- Login supports email or employee ID with password.
- JWT tokens are stored using `FlutterSecureStorage`.
- Profile and permissions are loaded after login and on cold start.
- Bearer authentication, logout, subscription expiry handling, and app restart are wired.
- Password-forgot API support exists, but the corresponding screen is empty.

### Attendance

- Punch in/out flow is present.
- Mobile configuration and today-session state are loaded from the backend.
- Location permissions/GPS and selfie capture are integrated.
- Conflict and refresh handling are present.

### HRMS

- Dashboard and attendance summary.
- Leave balance, leave application, leave status/details, and leave revocation.
- Leave approval inbox with approve/reject actions.
- Notifications with read/delete operations.

The underlying providers and API services are present, but the handoff identifies several HRMS screens as thin implementations requiring UI polish and interaction completion.

### Sales CRM

- Leads, lead details/forms, qualification, won/lost actions, and customer linking.
- Pipeline view.
- Follow-up activities and completion.
- CRM approvals for won leads and quotes.
- Contacts and customers.
- Quotes, PDF generation, sending, approval, and rejection.
- Visit check-in and visit tracking list.

CRM data is primarily loaded through the sales workspace and managed by [sales_workspace_provider.dart](lib/features/crm/shared/presentation/providers/sales_workspace_provider.dart). Orders and billing are explicitly deferred for mobile. Team tracking currently has list-based visit data; map UI is pending.

### Inventory

- Stock lookup.
- Warehouse stock and low-stock views.
- Inventory dashboard statistics.
- Stock and financial reporting models/services.

### Production

- Work-order list, summary, and details.
- Work-order execution actions.
- QC hold/release and completion flows.
- Notes and provider refresh/invalidation.

## 5. Priority Findings and Risks

### High priority

1. **Post-login navigation targets an undefined route.** [auth_provider.dart](lib/features/auth/presentation/providers/auth_provider.dart) calls `pushNamedAndRemoveUntil('/')`, while [app_routes.dart](lib/app/app_routes.dart) defines `/home` and does not define `/`. A successful login may therefore end in an unknown-route failure. Change the destination to the intended home route and add an integration test.

2. **Android release configuration is still development-grade.** [build.gradle.kts](android/app/build.gradle.kts) uses the example application ID `com.example.erp_app` and signs release builds with the debug key. [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) enables cleartext traffic. A production identity, signing setup, and HTTPS-only policy are required.

3. **Sensitive data is logged.** Authentication, attendance, CRM, production, and networking code logs emails, responses, profiles, permissions, payloads, headers/errors, and business records through `print`/`debugPrint`. Remove or gate these logs behind a non-production logger before release.

### Medium priority

4. **Client cryptography has a hardcoded secret.** [crypto_helper.dart](lib/core/services/crypto_helper.dart) embeds the AES secret and uses AES-CBC with an MD5-based OpenSSL-compatible derivation and no authenticated integrity tag. This may be required for backend compatibility, but the secret can be extracted from the application. Confirm the threat model with the backend/security owner and prefer server-side TLS plus authenticated encryption for a future protocol.

5. **Authorization gates are inconsistent.** Punch, leave, selected CRM detail routes, quotes, visits, stock lookup, work orders, and low stock use `PermissionGate`; approvals, notifications, CRM leads, activities, CRM approvals, and several dashboard routes are not wrapped at the route level. Backend authorization must remain authoritative, and mobile route visibility should be standardized.

6. **iOS permission declarations appear incomplete.** [Info.plist](ios/Runner/Info.plist) does not declare location or camera usage descriptions even though attendance and visit flows use those capabilities. Verify iOS permission prompts and add the required usage descriptions before device testing/release.

7. **Automated test coverage is too small for the feature surface.** The repository contains the default widget test and one production work-order test. There are no visible focused tests for authentication, routing, permission gates, API parsing, encryption failure behavior, attendance permissions, leave mutations, CRM mutations, inventory, or production beyond the current work-order test.

### Lower priority / maintainability

8. Analyzer output contains deprecated Flutter APIs such as `withOpacity`, deprecated form-field properties, unused elements, dead/null-aware code, and ignored refresh results. These do not currently block analysis but increase maintenance cost and can hide real defects.

9. [quote_pdf_helper.dart](lib/features/crm/shared/presentation/widgets/quote_pdf_helper.dart) references `path_provider`, but `path_provider` is not declared directly in `pubspec.yaml`. Add the direct dependency if the import is required, rather than relying on a transitive package.

10. [forgot_password_screen.dart](lib/features/auth/presentation/screens/forgot_password_screen.dart) is empty, so the password recovery capability is not available as a user-facing workflow.

## 6. Incomplete or Deferred Scope

- Forgot-password UI.
- HRMS leave and notification UI polish.
- CRM UI polish across leads, pipeline, activities, approvals, contacts, customers, quotes, and visits.
- Map-based team tracking.
- Mobile orders and billing.
- Deeper inventory and production functionality.
- Accounts, assets, payroll, recruitment, and other out-of-scope ERP modules.

The authoritative implementation notes and route matrix are in [HANDOFF.md](HANDOFF.md).

## 7. Recommended Delivery Sequence

1. Fix the `/` versus `/home` navigation defect and add a login-to-home test.
2. Remove production-sensitive logging and review all error messages for data leakage.
3. Configure production API URLs, HTTPS, Android application ID, release signing, app icons, iOS bundle settings, and iOS location/camera descriptions.
4. Confirm the encryption protocol and secret-management strategy with the backend/security team.
5. Complete the HRMS screens, then CRM screens in the order: leads, pipeline, follow-ups, quotes, visits, contacts/customers, approvals.
6. Add provider/API tests for authentication, leave, attendance, CRM, inventory, and production, plus widget tests for critical user flows.
7. Move the production test into the standard `test/` tree or document the intentional test layout and ensure CI runs it explicitly.
8. Run device testing on Android emulator, Android physical device, and iOS physical device, including offline/error states and permission denial paths.
9. Run `flutter build apk --release` and the iOS archive pipeline only after signing and platform configuration are complete.

## 8. Suggested Senior Review Questions

- Is client-side payload encryption required in addition to TLS, and is the current protocol a fixed backend compatibility contract?
- Which screens are release scope versus prototype/thin UI?
- What are the expected permission matrices for HRMS, CRM, inventory, and production routes?
- Which backend environment is the supported UAT target, and how are environment secrets supplied in CI/CD?
- What is the mobile release target: Android only, or Android and iOS together?
- Are orders, billing, map tracking, push notifications, and offline behavior required for the next milestone?

## 9. Local Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/widget_test.dart
flutter test lib/test/features/production/work_order_details_screen_test.dart
flutter build apk --release
```