import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/features/kyc/presentation/bloc/kyc_cubit.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';
import 'package:local_lending_app/shared/widgets/status_timeline.dart';

class KycPage extends StatelessWidget {
  const KycPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : '';
    final name = auth is Authenticated ? auth.user.name : '';
    return BlocProvider(
      create: (_) => getIt<KycCubit>()..load(userId),
      child: _KycView(fallbackName: name),
    );
  }
}

class _KycView extends StatefulWidget {
  const _KycView({required this.fallbackName});

  final String fallbackName;

  @override
  State<_KycView> createState() => _KycViewState();
}

class _KycViewState extends State<_KycView> {
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();
  final _address = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _aadhaar.dispose();
    _pan.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KycCubit, KycState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        final profile = state.profile;
        if (profile != null && !_seeded) {
          _aadhaar.text = profile.aadhaarNumber ?? '';
          _pan.text = profile.panNumber ?? '';
          _address.text = profile.address ?? '';
          _seeded = true;
        }
      },
      builder: (context, state) {
        final profile = state.profile;
        return Scaffold(
          appBar: AppBar(title: const Text('KYC Verification')),
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _KycBanner(profile: profile),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _aadhaar,
                      readOnly: !(profile?.canSubmit() ?? true),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Aadhaar number',
                        hintText: '12-digit Aadhaar',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pan,
                      readOnly: !(profile?.canSubmit() ?? true),
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'PAN',
                        hintText: 'ABCDE1234F',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      readOnly: !(profile?.canSubmit() ?? true),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Proof of address',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        profile?.idProofUploaded == true
                            ? Icons.check_circle
                            : Icons.upload_file,
                        color: profile?.idProofUploaded == true
                            ? const Color(0xFF059669)
                            : null,
                      ),
                      title: const Text('Identity document'),
                      subtitle: Text(
                        profile?.idProofUploaded == true
                            ? 'Aadhaar / ID photo on file'
                            : 'Upload Aadhaar or government ID photo',
                      ),
                      onTap: profile?.canSubmit() ?? true
                          ? () => _pickProof(context, profile, idProof: true)
                          : null,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        profile?.addressProofUploaded == true
                            ? Icons.check_circle
                            : Icons.upload_file,
                        color: profile?.addressProofUploaded == true
                            ? const Color(0xFF059669)
                            : null,
                      ),
                      title: const Text('Address proof'),
                      subtitle: Text(
                        profile?.addressProofUploaded == true
                            ? 'Address document on file'
                            : 'Upload utility bill or address proof',
                      ),
                      onTap: profile?.canSubmit() ?? true
                          ? () => _pickProof(context, profile, idProof: false)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (profile?.canSubmit() ?? true)
                      ElevatedButton(
                        onPressed: state.submitting
                            ? null
                            : () {
                                _patch(context, profile);
                                context.read<KycCubit>().submit();
                              },
                        child: Text(
                          state.submitting
                              ? 'Submitting…'
                              : profile?.effectiveStatus() ==
                                        KycStatus.expired ||
                                    (profile?.isExpiringSoon() ?? false)
                              ? 'Renew KYC'
                              : 'Submit for review',
                        ),
                      )
                    else if (profile?.status == KycStatus.submitted)
                      const Text('Your KYC is with the lender for review.'),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _pickProof(
    BuildContext context,
    KycProfile? profile, {
    required bool idProof,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || source == null) return;

    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_pickerErrorMessage(error, source))),
      );
      return;
    }

    if (!context.mounted || file == null) return;
    final current =
        profile ??
        KycProfile(
          userId: context.read<AuthCubit>().state is Authenticated
              ? (context.read<AuthCubit>().state as Authenticated).user.id
              : '',
          fullName: widget.fallbackName,
          status: KycStatus.pending,
        );
    _patch(context, current);
    await context.read<KycCubit>().uploadDocument(
      profile: context.read<KycCubit>().state.profile ?? current,
      localPath: file.path,
      idProof: idProof,
    );
  }

  String _pickerErrorMessage(PlatformException error, ImageSource source) {
    final usingCamera = source == ImageSource.camera;
    if (error.code == 'camera_access_denied' ||
        error.code == 'photo_access_denied') {
      return usingCamera
          ? 'Camera permission is required to take a KYC photo.'
          : 'Photo library permission is required to upload KYC documents.';
    }
    if (error.code == 'channel-error' ||
        error.message?.contains('Unable to establish connection') == true) {
      return usingCamera
          ? 'Could not open the camera. Fully restart the app, then try gallery if the camera is unavailable.'
          : 'Could not open the photo picker. Fully restart the app and try again.';
    }
    return usingCamera
        ? 'Could not open the camera. Try choosing a photo from gallery instead.'
        : 'Could not open the photo library. Please try again.';
  }

  void _patch(
    BuildContext context,
    KycProfile? profile, {
    bool? id,
    bool? addressProof,
  }) {
    final auth = context.read<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : profile?.userId ?? '';
    context.read<KycCubit>().updateProfile(
      (profile ??
              KycProfile(
                userId: userId,
                fullName: widget.fallbackName,
                status: KycStatus.pending,
              ))
          .copyWith(
            fullName: widget.fallbackName,
            aadhaarNumber: _aadhaar.text.trim(),
            panNumber: _pan.text.trim(),
            address: _address.text.trim(),
            idProofUploaded: id,
            addressProofUploaded: addressProof,
          ),
    );
  }
}

class _KycBanner extends StatelessWidget {
  const _KycBanner({this.profile});

  final KycProfile? profile;

  @override
  Widget build(BuildContext context) {
    final status = profile?.effectiveStatus() ?? KycStatus.pending;
    final color = switch (status) {
      KycStatus.verified => const Color(0xFF059669),
      KycStatus.rejected => const Color(0xFFBA1A1A),
      KycStatus.submitted => const Color(0xFF2563EB),
      KycStatus.pending => const Color(0xFFD97706),
      KycStatus.expired => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verification status: ${status.label}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              StatusChip.kyc(status),
            ],
          ),
          if (profile?.verifiedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last completed ${AppDateUtils.formatDisplay(profile!.verifiedAt!)}',
            ),
          ],
          if (profile?.expiresAt != null)
            Text(
              'Valid until ${AppDateUtils.formatDisplay(profile!.expiresAt!)}',
            ),
          if (profile?.rejectionReason != null) ...[
            const SizedBox(height: 4),
            Text('Reason: ${profile!.rejectionReason}'),
          ],
          const SizedBox(height: 16),
          StatusTimeline(steps: _stepsFor(profile)),
        ],
      ),
    );
  }

  List<StatusStep> _stepsFor(KycProfile? profile) {
    final status = profile?.effectiveStatus() ?? KycStatus.pending;
    final submitted = profile?.submittedAt == null
        ? null
        : AppDateUtils.formatDisplay(profile!.submittedAt!);
    final completed = profile?.verifiedAt == null
        ? null
        : AppDateUtils.formatDisplay(profile!.verifiedAt!);
    final expiry = profile?.expiresAt == null
        ? null
        : AppDateUtils.formatDisplay(profile!.expiresAt!);
    return [
      StatusStep(
        title: 'Documents submitted',
        subtitle: submitted,
        state: status == KycStatus.pending
            ? StatusStepState.upcoming
            : StatusStepState.completed,
      ),
      StatusStep(
        title: 'Under review',
        subtitle: status == KycStatus.submitted ? 'Lender is reviewing' : null,
        state: status == KycStatus.pending
            ? StatusStepState.upcoming
            : status == KycStatus.submitted
            ? StatusStepState.current
            : StatusStepState.completed,
      ),
      if (status == KycStatus.rejected)
        StatusStep(
          title: 'Rejected',
          subtitle: profile?.rejectionReason,
          state: StatusStepState.failed,
        )
      else
        StatusStep(
          title: status == KycStatus.expired ? 'Renewal due' : 'Verified',
          subtitle: completed,
          state: status == KycStatus.verified
              ? StatusStepState.completed
              : status == KycStatus.expired
              ? StatusStepState.failed
              : StatusStepState.upcoming,
        ),
      StatusStep(
        title: 'Annual validity',
        subtitle: expiry ?? 'Valid for 1 year after approval',
        state: status == KycStatus.verified
            ? StatusStepState.completed
            : status == KycStatus.expired
            ? StatusStepState.failed
            : StatusStepState.upcoming,
      ),
    ];
  }
}
