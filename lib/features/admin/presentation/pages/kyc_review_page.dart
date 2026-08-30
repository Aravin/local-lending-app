import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/kyc_review_cubit.dart';
import 'package:local_lending_app/shared/widgets/app_choice_chip.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';

class KycReviewPage extends StatelessWidget {
  const KycReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KycReviewCubit>()..load(),
      child: const _KycReviewView(),
    );
  }
}

class _KycReviewView extends StatelessWidget {
  const _KycReviewView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC review')),
      body: BlocBuilder<KycReviewCubit, KycReviewState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppChoiceChip(
                    label: 'All',
                    selected: state.filter == null,
                    onSelected: (_) =>
                        context.read<KycReviewCubit>().setFilter(null),
                  ),
                  for (final status in [
                    KycStatus.submitted,
                    KycStatus.expired,
                    KycStatus.verified,
                    KycStatus.rejected,
                  ])
                    AppChoiceChip(
                      label: status.label,
                      selected: state.filter == status,
                      onSelected: (_) =>
                          context.read<KycReviewCubit>().setFilter(status),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('No KYC records in this filter.')),
                )
              else
                ...state.visible.map(
                  (profile) => _KycReviewCard(profile: profile),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _KycReviewCard extends StatelessWidget {
  const _KycReviewCard({required this.profile});

  final KycProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                StatusChip.kyc(profile.status),
              ],
            ),
            const SizedBox(height: 6),
            if (profile.submittedAt != null)
              Text(
                'Submitted ${AppDateUtils.formatDisplay(profile.submittedAt!)}',
              ),
            if (profile.verifiedAt != null)
              Text(
                'Last completed ${AppDateUtils.formatDisplay(profile.verifiedAt!)}',
              ),
            if (profile.expiresAt != null)
              Text(
                'Valid until ${AppDateUtils.formatDisplay(profile.expiresAt!)}',
              ),
            if (profile.rejectionReason != null)
              Text('Reason: ${profile.rejectionReason}'),
            if (profile.idProofPath != null ||
                profile.addressProofPath != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (profile.idProofPath != null)
                    TextButton.icon(
                      onPressed: () => _showDocument(
                        context,
                        profile.idProofPath!,
                        'Identity proof',
                      ),
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Identity proof'),
                    ),
                  if (profile.addressProofPath != null)
                    TextButton.icon(
                      onPressed: () => _showDocument(
                        context,
                        profile.addressProofPath!,
                        'Address proof',
                      ),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Address proof'),
                    ),
                ],
              ),
            ],
            if (profile.status == KycStatus.submitted) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => context.read<KycReviewCubit>().decide(
                      ReviewKycParams(
                        userId: profile.userId,
                        status: KycStatus.verified,
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
                  OutlinedButton(
                    onPressed: () => _reject(context, profile),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDocument(
    BuildContext context,
    String path,
    String title,
  ) async {
    final result = await getIt<AdminRepository>().getKycDocument(path);
    if (!context.mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (bytes) {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: InteractiveViewer(child: Image.memory(bytes)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reject(BuildContext context, KycProfile profile) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject KYC'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!context.mounted || reason == null || reason.trim().isEmpty) {
      return;
    }
    await context.read<KycReviewCubit>().decide(
      ReviewKycParams(
        userId: profile.userId,
        status: KycStatus.rejected,
        rejectionReason: reason.trim(),
      ),
    );
  }
}
