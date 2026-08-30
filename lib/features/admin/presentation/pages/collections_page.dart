import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/collections_cubit.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CollectionsCubit>()..load(DateTime.now()),
      child: const _CollectionsView(),
    );
  }
}

class _CollectionsView extends StatelessWidget {
  const _CollectionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection Sheet')),
      body: BlocBuilder<CollectionsCubit, CollectionsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final grouped = <String, List<CollectionEntry>>{};
          for (final entry in state.entries) {
            grouped.putIfAbsent(entry.frequency.label, () => []).add(entry);
          }
          if (state.entries.isEmpty) {
            return const Center(child: Text('No dues for today.'));
          }
          return ListView(
            children: grouped.entries.expand((group) {
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    group.key,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ...group.value.map(
                  (entry) => ListTile(
                    title: Text(entry.borrowerName),
                    subtitle: Text(
                      'Inst #${entry.installmentNumber} • ${CurrencyFormatter.format(entry.dueAmountRupees)}',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Mark paid',
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: state.collecting
                              ? null
                              : () => context.read<CollectionsCubit>().collect(
                                  loanId: entry.loanId,
                                  installmentNumber: entry.installmentNumber,
                                  amount: entry.outstandingRupees,
                                  collectedAmount: entry.collectedAmountRupees,
                                  method: PaymentMethod.cash,
                                ),
                        ),
                        IconButton(
                          tooltip: 'Partial',
                          icon: const Icon(Icons.pie_chart_outline),
                          onPressed: state.collecting
                              ? null
                              : () => context.read<CollectionsCubit>().collect(
                                  loanId: entry.loanId,
                                  installmentNumber: entry.installmentNumber,
                                  amount: entry.outstandingRupees / 2,
                                  collectedAmount: entry.collectedAmountRupees,
                                  method: PaymentMethod.cash,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            }).toList(),
          );
        },
      ),
    );
  }
}
