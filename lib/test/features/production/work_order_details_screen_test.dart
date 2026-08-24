import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:erp_app/features/production/data/models/production_model.dart';
import 'package:erp_app/features/production/data/provider/workspace_provider.dart';
import 'package:erp_app/features/production/presentation/screens/work_order_details_screen.dart';

void main() {
  testWidgets('shows work order details', (tester) async {
    final workOrder = WorkOrder(
      id: '1',
      woNumber: 'WO-00001',
      itemName: 'Test Product',
      quantity: 25,
      status: 'IN_PROCESS',
      activeStep: 'Start',
      warehouse: 'Main Warehouse',
      factoryName: 'Main Factory',
      priority: 'HIGH',
      stages: const [
        WorkOrderStage(code: 'CUTTING', completed: true),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workOrderDetailProvider('1').overrideWithValue(
            AsyncValue.data(workOrder),
          ),
        ],
        child: const MaterialApp(
          home: WorkOrderDetailScreen(workOrderId: '1'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('WO-00001'), findsOneWidget);
    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('25 units'), findsOneWidget);
    expect(find.text('CUTTING'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}