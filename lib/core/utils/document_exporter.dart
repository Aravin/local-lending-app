import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/admin/domain/entities/delinquency_bucket.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class DocumentExporter {
  const DocumentExporter._();

  static Future<void> shareCsv({
    required String filename,
    required String csv,
  }) {
    return SharePlus.instance.share(
      ShareParams(text: csv, subject: filename, title: filename),
    );
  }

  static Future<void> sharePortfolioPdf(PortfolioReport report) {
    return Printing.layoutPdf(
      name: 'portfolio-report.pdf',
      onLayout: (format) async {
        final doc = pw.Document();
        doc.addPage(
          pw.MultiPage(
            build: (context) => [
              pw.Text(
                'Portfolio report',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Delinquency aging', style: _heading),
              pw.TableHelper.fromTextArray(
                headers: const ['Bucket', 'Count', 'Amount'],
                data: [
                  for (final bucket in report.buckets)
                    [
                      bucket.label,
                      '${bucket.loanCount}',
                      CurrencyFormatter.format(bucket.amountRupees),
                    ],
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Disbursement trend', style: _heading),
              ...report.disbursementTrend.map(
                (point) => pw.Text(
                  '${point.label}: ${CurrencyFormatter.format(point.amountRupees)}',
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Collection trend', style: _heading),
              ...report.collectionTrend.map(
                (point) => pw.Text(
                  '${point.label}: ${CurrencyFormatter.format(point.amountRupees)}',
                ),
              ),
            ],
          ),
        );
        return doc.save();
      },
    );
  }

  static Future<void> shareLoanStatement({
    required Loan loan,
    required List<RepaymentRecord> records,
  }) {
    return Printing.layoutPdf(
      name: 'loan-statement-${loan.id}.pdf',
      onLayout: (format) async {
        final doc = pw.Document();
        doc.addPage(
          pw.MultiPage(
            build: (context) => [
              pw.Text(
                'Loan statement',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('${loan.borrowerName} • ${loan.purpose.label}'),
              pw.Text(
                '${loan.frequency.label} • Principal ${CurrencyFormatter.format(loan.principalRupees)}',
              ),
              pw.SizedBox(height: 16),
              pw.Text('Installments', style: _heading),
              pw.TableHelper.fromTextArray(
                headers: const ['#', 'Due', 'Amount', 'Status'],
                data: [
                  for (final item in loan.schedule.installments)
                    [
                      '${item.installmentNumber}',
                      AppDateUtils.formatDisplay(item.dueDate),
                      CurrencyFormatter.format(item.amountRupees),
                      item.status.name,
                    ],
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Payments', style: _heading),
              if (records.isEmpty)
                pw.Text('No payments recorded.')
              else
                pw.TableHelper.fromTextArray(
                  headers: const ['Date', 'Amount', 'Method', 'Reference'],
                  data: [
                    for (final record in records)
                      [
                        AppDateUtils.formatDisplay(record.paidAt),
                        CurrencyFormatter.format(record.amountRupees),
                        record.method.label,
                        record.reference ?? '-',
                      ],
                  ],
                ),
            ],
          ),
        );
        return doc.save();
      },
    );
  }

  static pw.TextStyle get _heading =>
      const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold);

  static String portfolioCsv(PortfolioReport report) {
    final buffer = StringBuffer()
      ..writeln('Bucket,Count,Amount')
      ..writeln(
        report.buckets
            .map(
              (bucket) =>
                  '${bucket.label},${bucket.loanCount},${bucket.amountRupees.toStringAsFixed(2)}',
            )
            .join('\n'),
      )
      ..writeln()
      ..writeln('Month,Disbursed,Collected');
    for (var i = 0; i < report.disbursementTrend.length; i++) {
      final disbursed = report.disbursementTrend[i];
      final collected = i < report.collectionTrend.length
          ? report.collectionTrend[i].amountRupees
          : 0;
      buffer.writeln(
        '${disbursed.label},${disbursed.amountRupees.toStringAsFixed(2)},${collected.toStringAsFixed(2)}',
      );
    }
    return buffer.toString();
  }
}
