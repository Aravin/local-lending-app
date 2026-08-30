import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/customers_cubit.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CustomersCubit>()..load(),
      child: const _CustomersView(),
    );
  }
}

class _CustomersView extends StatelessWidget {
  const _CustomersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          BlocBuilder<CustomersCubit, CustomersState>(
            buildWhen: (previous, current) =>
                previous.riskTierFilter != current.riskTierFilter ||
                previous.kycStatusFilter != current.kycStatusFilter,
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search name, phone, or email',
                      ),
                      onChanged: (value) =>
                          context.read<CustomersCubit>().load(query: value),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<RiskTier?>(
                            initialValue: state.riskTierFilter,
                            decoration: const InputDecoration(
                              labelText: 'Risk',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All risk tiers'),
                              ),
                              ...RiskTier.values.map(
                                (tier) => DropdownMenuItem(
                                  value: tier,
                                  child: Text(tier.label),
                                ),
                              ),
                            ],
                            onChanged: context
                                .read<CustomersCubit>()
                                .setRiskTierFilter,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<KycStatus?>(
                            initialValue: state.kycStatusFilter,
                            decoration: const InputDecoration(labelText: 'KYC'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All KYC statuses'),
                              ),
                              ...KycStatus.values.map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              ),
                            ],
                            onChanged: context
                                .read<CustomersCubit>()
                                .setKycStatusFilter,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<CustomersCubit, CustomersState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final customers = state.visibleCustomers;
                if (customers.isEmpty) {
                  return const Center(child: Text('No matching customers.'));
                }
                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      title: Text(customer.name),
                      subtitle: Text(
                        '${customer.activeLoansCount} active • ${(customer.lifetimeRepaymentRate * 100).toStringAsFixed(0)}% repaid',
                      ),
                      trailing: StatusChip(
                        label: customer.riskTier.label,
                        color: customer.riskTier.name == 'high'
                            ? const Color(0xFFBA1A1A)
                            : customer.riskTier.name == 'medium'
                            ? const Color(0xFFD97706)
                            : const Color(0xFF059669),
                      ),
                      onTap: () => _showDetails(context, customer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, CustomerProfile customer) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(customer.phone),
              Text(customer.email),
              if (customer.address != null) Text(customer.address!),
              const SizedBox(height: 12),
              Text(
                'Outstanding ${CurrencyFormatter.format(customer.outstandingRupees)}',
              ),
              Text('KYC: ${customer.kycStatus.label}'),
              Text('Risk: ${customer.riskTier.label}'),
            ],
          ),
        );
      },
    );
  }
}
