import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/admin/domain/entities/portfolio_stats.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_portfolio_metrics.dart';

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.loading = true,
    this.stats,
    this.errorMessage,
  });

  final bool loading;
  final PortfolioStats? stats;
  final String? errorMessage;

  AdminDashboardState copyWith({
    bool? loading,
    PortfolioStats? stats,
    String? errorMessage,
  }) {
    return AdminDashboardState(
      loading: loading ?? this.loading,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [loading, stats, errorMessage];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit({required this._getPortfolioMetrics})
    : super(const AdminDashboardState());

  final GetPortfolioMetrics _getPortfolioMetrics;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await _getPortfolioMetrics();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (stats) => emit(state.copyWith(loading: false, stats: stats)),
    );
  }
}
