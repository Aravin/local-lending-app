import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/utils/validators.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';

class KycState extends Equatable {
  const KycState({
    this.loading = true,
    this.submitting = false,
    this.profile,
    this.errorMessage,
    this.successMessage,
  });

  final bool loading;
  final bool submitting;
  final KycProfile? profile;
  final String? errorMessage;
  final String? successMessage;

  KycState copyWith({
    bool? loading,
    bool? submitting,
    KycProfile? profile,
    String? errorMessage,
    String? successMessage,
  }) {
    return KycState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    submitting,
    profile,
    errorMessage,
    successMessage,
  ];
}

class KycCubit extends Cubit<KycState> {
  KycCubit({required this._adminRepository}) : super(const KycState());

  final AdminRepository _adminRepository;

  Future<void> load(String userId) async {
    emit(state.copyWith(loading: true));
    final result = await _adminRepository.getKycProfile(userId);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (profile) => emit(state.copyWith(loading: false, profile: profile)),
    );
  }

  void updateProfile(KycProfile profile) {
    emit(state.copyWith(profile: profile));
  }

  Future<void> uploadDocument({
    required KycProfile profile,
    required String localPath,
    required bool idProof,
  }) async {
    emit(state.copyWith(submitting: true));
    final result = await _adminRepository.uploadKycDocument(
      userId: profile.userId,
      documentType: idProof ? 'identity' : 'address',
      localPath: localPath,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(submitting: false, errorMessage: failure.message),
      ),
      (path) => emit(
        state.copyWith(
          submitting: false,
          profile: profile.copyWith(
            idProofUploaded: idProof ? true : profile.idProofUploaded,
            addressProofUploaded: idProof ? profile.addressProofUploaded : true,
            idProofPath: idProof ? path : profile.idProofPath,
            addressProofPath: idProof ? profile.addressProofPath : path,
          ),
          successMessage: 'Document uploaded.',
        ),
      ),
    );
  }

  Future<void> submit() async {
    final profile = state.profile;
    if (profile == null) return;
    final aadhaarError = Validators.validateAadhaar(profile.aadhaarNumber);
    final panError = Validators.validatePan(profile.panNumber);
    if (aadhaarError != null ||
        panError != null ||
        (profile.address == null || profile.address!.trim().isEmpty) ||
        !profile.idProofUploaded ||
        !profile.addressProofUploaded) {
      emit(
        state.copyWith(
          errorMessage:
              aadhaarError ??
              panError ??
              'Complete address and upload both documents before submitting.',
        ),
      );
      return;
    }
    emit(state.copyWith(submitting: true));
    final result = await _adminRepository.submitKyc(profile);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(submitting: false, errorMessage: failure.message),
      ),
      (saved) => emit(
        state.copyWith(
          submitting: false,
          profile: saved,
          successMessage: 'KYC submitted for verification.',
        ),
      ),
    );
  }
}
