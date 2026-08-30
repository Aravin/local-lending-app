import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_kyc_profiles.dart';
import 'package:local_lending_app/features/admin/domain/usecases/review_kyc.dart';

class KycReviewState extends Equatable {
  const KycReviewState({
    this.loading = true,
    this.profiles = const [],
    this.filter = KycStatus.submitted,
    this.errorMessage,
    this.infoMessage,
  });

  final bool loading;
  final List<KycProfile> profiles;
  final KycStatus? filter;
  final String? errorMessage;
  final String? infoMessage;

  List<KycProfile> get visible {
    if (filter == null) return profiles;
    return profiles.where((profile) => profile.status == filter).toList();
  }

  KycReviewState copyWith({
    bool? loading,
    List<KycProfile>? profiles,
    KycStatus? filter,
    bool clearFilter = false,
    String? errorMessage,
    String? infoMessage,
  }) {
    return KycReviewState(
      loading: loading ?? this.loading,
      profiles: profiles ?? this.profiles,
      filter: clearFilter ? null : filter ?? this.filter,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    profiles,
    filter,
    errorMessage,
    infoMessage,
  ];
}

class KycReviewCubit extends Cubit<KycReviewState> {
  KycReviewCubit({required this.getKycProfiles, required this.reviewKyc})
    : super(const KycReviewState());

  final GetKycProfiles getKycProfiles;
  final ReviewKyc reviewKyc;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await getKycProfiles();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (profiles) => emit(state.copyWith(loading: false, profiles: profiles)),
    );
  }

  void setFilter(KycStatus? filter) {
    emit(state.copyWith(filter: filter, clearFilter: filter == null));
  }

  Future<void> decide(ReviewKycParams params) async {
    final result = await reviewKyc(params);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => load(),
    );
  }
}
