import 'package:erp_app/features/crm/quotes/presentation/screens/quote_pdf_details.dart';
import 'package:erp_app/features/crm/shared/data/models/sales_quote_model.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/providers/sales_workspace_provider.dart';


class QuoteDetailScreen extends ConsumerWidget {
  const QuoteDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteId = ModalRoute.of(context)?.settings.arguments as String?;
    final SalesQuote? quote = quoteId == null
        ? null
        : ref.watch(crmQuoteByIdProvider(quoteId)) as SalesQuote?;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Quote Details'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: quote == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  quoteId == null
                      ? 'Pass quoteId via Navigator arguments.'
                      : 'Quote not found: $quoteId',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5D6D7E),
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header Section ---
                  _buildHeaderCard(quote),
                  const SizedBox(height: 16),

                  // --- Client Information Card ---
                  _buildClientCard(quote),
                  const SizedBox(height: 16),

                  // --- Line Items & Summary Card ---
                  _buildLineItemsCard(quote),

                  if (quote.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNotesCard(quote),
                  ],

                  const SizedBox(height: 24),

                  // --- Primary Action Buttons ---
                  ElevatedButton.icon(
                    onPressed: () {
                      // Trigger sendQuote action
                    },
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text(
                      'Email quote to client',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1B4F72),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _DownloadPdfButton(quote: quote),
                  const SizedBox(height: 20),

                  // --- Footer Info Box ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEFF1).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF5D6D7E),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mark the lead won in CRM when the customer accepts, then create a sales order.',
                            style: TextStyle(
                              color: Color(0xFF5D6D7E),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // Header Component (Quote number/id)
  Widget _buildHeaderCard(SalesQuote quote) {
    final String quoteNumber = (quote.number?.trim().isNotEmpty ?? false)
        ? quote.number!
        : quote.id;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4F72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quoteNumber,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F72),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Quotation Details',
                style: TextStyle(fontSize: 14, color: Color(0xFF5D6D7E)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Client Information Component
  Widget _buildClientCard(SalesQuote quote) {
    final String rawStatus = quote.approval['status']?.toString().isNotEmpty == true
        ? quote.approval['status'].toString()
        : quote.status;
    final String status = rawStatus.isNotEmpty ? rawStatus.toUpperCase() : 'UNKNOWN';
    final _StatusColors colors = _statusColors(rawStatus.toLowerCase());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'CLIENT INFORMATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF85929E),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.business_outlined,
            label: 'Account',
            value: (quote.account?.trim().isNotEmpty ?? false)
                ? quote.account!
                : '—',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Owner',
            value: quote.owner.trim().isNotEmpty ? quote.owner : '—',
          ),
          if (quote.gstNumber.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: 'GST Number',
              value: quote.gstNumber,
            ),
          ],
          if (quote.validUntil != null && quote.validUntil!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.event_outlined,
              label: 'Valid Until',
              value: _formatDate(quote.validUntil),
            ),
          ],
          // if (quote != null && quote.validUntil!.trim().isNotEmpty) ...[
          //   const SizedBox(height: 12),
          //   _buildInfoRow(
          //     icon: Icons.event_outlined,
          //     label: 'Valid Until',
          //     value: _formatDate(quote.validUntil),
          //   ),
          // ],
        ],
      ),
    );
  }

  // Line Items Component
  Widget _buildLineItemsCard(SalesQuote quote) {
    final lines = quote.lines;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LINE ITEMS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF85929E),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),

          if (lines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No line items added yet.',
                style: TextStyle(fontSize: 14, color: Color(0xFF5D6D7E)),
              ),
            )
          else
            for (int i = 0; i < lines.length; i++) ...[
              _QuoteDetailHelpers.buildItemRowFromLine(lines[i]),
              if (i != lines.length - 1)
                const Divider(height: 24, color: Color(0xFFE5E8EB)),
            ],

          const Divider(height: 28, color: Color(0xFFE5E8EB)),

          _buildSummaryRow('Subtotal', quote.subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'GST (${_formatRate(quote.gstRate)}%)',
            quote.gstAmount,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2833),
                ),
              ),
              Text(
                _formatCurrency(quote.amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F72),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF5D6D7E)),
        ),
        Text(
          _formatCurrency(value),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C2833),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(SalesQuote quote) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF85929E),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            quote.notes,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1C2833),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1C2833)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5D6D7E)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2833),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _StatusColors _statusColors(String status) {
    switch (status) {
      case 'approved':
      case 'accepted':
      case 'won':
        return const _StatusColors(
          background: Color(0xFFA9DFBF),
          text: Color(0xFF1E8449),
        );
      case 'pending':
      case 'requested':
        return const _StatusColors(
          background: Color(0xFFFDEBD0),
          text: Color(0xFFB9770E),
        );
      case 'rejected':
      case 'declined':
        return const _StatusColors(
          background: Color(0xFFF5B7B1),
          text: Color(0xFFC0392B),
        );
      case 'draft':
        return const _StatusColors(
          background: Color(0xFFE5E8EB),
          text: Color(0xFF5D6D7E),
        );
      default:
        return const _StatusColors(
          background: Color(0xFFD6EAF8),
          text: Color(0xFF1B4F72),
        );
    }
  }

  static String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  static String _formatRate(double rate) {
    return rate == rate.roundToDouble()
        ? rate.toStringAsFixed(0)
        : rate.toStringAsFixed(2);
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy').format(parsed);
  }
}

class _StatusColors {
  final Color background;
  final Color text;
  const _StatusColors({required this.background, required this.text});
}

/// Generates the quote PDF and writes it straight to the device — no
/// print dialog, no share sheet. Android: saved to Downloads. iOS: saved
/// to the app's Documents, visible in the Files app. Web: a normal
/// browser file download.
class _DownloadPdfButton extends StatefulWidget {
  const _DownloadPdfButton({required this.quote});

  final SalesQuote quote;

  @override
  State<_DownloadPdfButton> createState() => _DownloadPdfButtonState();
}

class _DownloadPdfButtonState extends State<_DownloadPdfButton> {
  bool _isGenerating = false;

  Future<void> _handleDownload() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final bytes = await QuotePdfService.generate(widget.quote);
      final quoteNumber = (widget.quote.number?.trim().isNotEmpty ?? false)
          ? widget.quote.number!
          : widget.quote.id;

      final savedPath = await FileSaver.instance.saveFile(
        name: '$quoteNumber.pdf',
        bytes: bytes,
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        final isWeb = kIsWeb;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(
              isWeb ? 'Quote PDF downloaded' : 'Saved: $savedPath',
              overflow: TextOverflow.ellipsis,
            ),
            action: isWeb
                ? null
                : SnackBarAction(
                    label: 'Open',
                    onPressed: () => OpenFilex.open(savedPath),
                  ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not download PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isGenerating ? null : _handleDownload,
      icon: _isGenerating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1C2833),
              ),
            )
          : const Icon(
              Icons.download_rounded,
              size: 20,
              color: Color(0xFF1C2833),
            ),
      label: Text(
        _isGenerating ? 'Preparing PDF…' : 'Download PDF',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1C2833),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFFD5D8DC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _QuoteDetailHelpers {
  /// `lines` items ka exact shape SalesQuote model me `List<dynamic>` hai,
  /// isliye har item ko safely Map ki tarah padhte hain aur common key
  /// names (name/description/title, qty/quantity, rate/price, amount/total)
  /// try karte hain. Jaise hi tumhare paas proper QuoteLine model ho, ye
  /// helper us model se seedha padhne ke liye replace kar dena.
  static Widget buildItemRowFromLine(dynamic line) {
    final Map<String, dynamic> item =
        line is Map ? Map<String, dynamic>.from(line) : const {};

    final String title = (item['name'] ??
            item['title'] ??
            item['description'] ??
            item['productName'] ??
            'Item')
        .toString();

    final num qty = _asNum(item['qty'] ?? item['quantity'] ?? 1);

    final num? rate = item['rate'] != null || item['price'] != null
        ? _asNum(item['rate'] ?? item['price'])
        : null;

    final num amount = item['amount'] != null || item['total'] != null
        ? _asNum(item['amount'] ?? item['total'])
        : (rate != null ? rate * qty : 0);

    final String subtitle = rate != null
        ? 'Qty: ${_formatQty(qty)} × ${QuoteDetailScreen._formatCurrency(rate.toDouble())}'
        : 'Qty: ${_formatQty(qty)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2833),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5D6D7E)),
              ),
            ],
          ),
        ),
        Text(
          QuoteDetailScreen._formatCurrency(amount.toDouble()),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C2833),
          ),
        ),
      ],
    );
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  static String _formatQty(num qty) {
    return qty == qty.roundToDouble()
        ? qty.toStringAsFixed(0)
        : qty.toString();
  }
}