import 'dart:io';
import 'dart:typed_data';
import 'package:erp_app/features/crm/shared/presentation/providers/sales_workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';



Future<String> _saveAndOpenPdfBytes(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) {
    throw Exception(result.message);
  }
  return file.path;
}

Future<String> saveAndOpenQuotePdf(WidgetRef ref, String quoteId) async {
  final api = ref.read(salesCrmApiProvider);
  final bytes = await api.downloadQuotePdf(quoteId);
  return _saveAndOpenPdfBytes(bytes, 'quote_$quoteId.pdf');
}

Future<String> saveAndOpenBillPdf(WidgetRef ref, String billId) async {
  final api = ref.read(salesCrmApiProvider);
  final bytes = await api.downloadBillPdf(billId);
  return _saveAndOpenPdfBytes(bytes, 'bill_$billId.pdf');
}