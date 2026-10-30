import '../../features/auth/presentation/providers/auth_state.dart';
import 'app_permissions.dart';

/// Gate for the Sales Tracking surfaces, per doc 05 — User & Team Management.
///
/// Sales Tracking (docs 01/02/04) is shown only when the company has the
/// `sales` module *and* the `tracking` feature entitlement, plus the matching
/// permission. Keeping this in one place stops each screen from re-deriving it.
extension SalesEntitlement on AuthState {
  bool get canTrack =>
      entitlements.moduleSales &&
      entitlements.featureTracking &&
      can(AppPermissions.salesTrackingSync);

  bool get canVisit => canTrack && can(AppPermissions.salesVisitsManage);

  bool get canClaim =>
      entitlements.featureTracking &&
      can(AppPermissions.salesDistanceClaimsView);

  bool get canReviewClaims =>
      can(AppPermissions.salesDistanceClaimsReview) ||
      can(AppPermissions.salesDistanceClaimsManage);

  bool get canCrm =>
      entitlements.moduleSales && can(AppPermissions.salesCrmLeadsView);
}

/// Const-friendly predicates so the tracking surfaces can be gated from
/// `const` link lists (home sections, CRM quick actions) and route maps.
bool salesCanTrack(AuthState auth) => auth.canTrack;
bool salesCanVisit(AuthState auth) => auth.canVisit;
bool salesCanClaim(AuthState auth) => auth.canClaim;
