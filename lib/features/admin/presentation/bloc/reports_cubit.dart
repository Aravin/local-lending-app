import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/utils/document_exporter.dart';
import 'package:local_lending_app/features/admin/domain/entities/delinquency_bucket.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_portfolio_report.dart';

class ReportsState extends Equatable {
  const ReportsState({
    this.loading = true,
    this.report,
    this.errorMessage,
    this.exportMessage,
  });

  final bool loading;
  final PortfolioReport? report;
  final String? errorMessage;
  final String? exportMessage;

  ReportsState copyWith({
    bool? loading,
    PortfolioReport? report,
    String? errorMessage,
    String? exportMessage,
  }) {
    return ReportsState(
      loading: loading ?? this.loading,
      report: report ?? this.report,
      errorMessage: errorMessage,
      exportMessage: exportMessage,
    );
  }

  @override
  List<Object?> get props => [loading, report, errorMessage, exportMessage];
}

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({required this._getPortfolioReport})
    : super(const ReportsState());

  final GetPortfolioReport _getPortfolioReport;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await _getPortfolioReport();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (report) => emit(state.copyWith(loading: false, report: report)),
    );
  }

  Future<void> exportCsv() async {
    final report = state.report;
    if (report == null) return;
    await DocumentExporter.shareCsv(
      filename: 'portfolio-report.csv',
      csv: DocumentExporter.portfolioCsv(report),
    );
    emit(state.copyWith(exportMessage: 'CSV ready to share.'));
  }

  Future<void> exportPdf() async {
    final report = state.report;
    if (report == null) return;
    await DocumentExporter.sharePortfolioPdf(report);
    emit(state.copyWith(exportMessage: 'PDF ready to share.'));
  }
}
