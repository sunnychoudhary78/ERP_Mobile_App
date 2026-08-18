import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/repository/production_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Open work orders list (client-side filtered per doc's terminal-status rule).
final openWorkOrdersProvider = FutureProvider.autoDispose<List<WorkOrder>>((
  ref,
) async {
  final repo = ref.watch(productionRepositoryProvider);
  return repo.getOpenWorkOrders();
});

/// Raw paginated work orders — for a screen with explicit page/status/item
/// filters instead of the "open only" view above.
final workOrdersPageProvider = FutureProvider.autoDispose
    .family<WorkOrdersPage, ({int page, int limit, String? status, String? itemId})>(
  (ref, args) async {
    final repo = ref.watch(productionRepositoryProvider);
    return repo.getWorkOrders(
      page: args.page,
      limit: args.limit,
      status: args.status,
      itemId: args.itemId,
    );
  },
);

final workOrdersSummaryProvider =
    FutureProvider.autoDispose<WorkOrdersSummary>((ref) async {
  final repo = ref.watch(productionRepositoryProvider);
  return repo.getSummary();
});

final workOrderDetailProvider = FutureProvider.autoDispose
    .family<WorkOrder, String>((ref, id) async {
  final repo = ref.watch(productionRepositoryProvider);
  return repo.getWorkOrderById(id);
});

/// Drives loading/error state for shop-floor actions (log execution, QC
/// hold, transition, complete) taken from the work order detail screen.
class WorkOrderActionsController extends StateNotifier<AsyncValue<void>> {
  WorkOrderActionsController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> logExecution(
    String id, {
    required String operator,
    required String machine,
    required String note,
    num outputQty = 0,
    num scrapQty = 0,
    List<WorkOrderStage>? stages,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(productionRepositoryProvider);
      await repo.logExecution(
        id,
        operator: operator,
        machine: machine,
        note: note,
        outputQty: outputQty,
        scrapQty: scrapQty,
        stages: stages,
      );
      _ref.invalidate(workOrderDetailProvider(id));
      _ref.invalidate(openWorkOrdersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setQcHold(String id, {required bool hold}) =>
      _run(id, () => _ref.read(productionRepositoryProvider).setQcHold(id, hold: hold));

  Future<bool> transition(String id, {required String activeStep}) => _run(
        id,
        () => _ref
            .read(productionRepositoryProvider)
            .transition(id, activeStep: activeStep),
      );

  Future<bool> complete(String id) =>
      _run(id, () => _ref.read(productionRepositoryProvider).complete(id));

  Future<bool> finishFromQc(String id) =>
      _run(id, () => _ref.read(productionRepositoryProvider).finishFromQc(id));

  Future<bool> overwriteNotes(String id, {required String notes}) => _run(
        id,
        () => _ref
            .read(productionRepositoryProvider)
            .overwriteNotes(id, notes: notes),
      );

  Future<bool> _run(String id, Future<WorkOrder> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      _ref.invalidate(workOrderDetailProvider(id));
      _ref.invalidate(openWorkOrdersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final workOrderActionsControllerProvider =
    StateNotifierProvider.autoDispose<WorkOrderActionsController, AsyncValue<void>>(
  (ref) => WorkOrderActionsController(ref),
);