import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/reports_cubit.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReportsCubit>()..load(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Insights')),
      body: BlocConsumer<ReportsCubit, ReportsState>(
        listener: (context, state) {
          if (state.exportMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.exportMessage!)));
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = state.report;
          if (report == null) {
            return Center(child: Text(state.errorMessage ?? 'No report'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Disbursement vs collection',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= report.disbursementTrend.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(report.disbursementTrend[index].label);
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        color: FlavorConfig.primaryColor,
                        spots: [
                          for (
                            var i = 0;
                            i < report.disbursementTrend.length;
                            i++
                          )
                            FlSpot(
                              i.toDouble(),
                              report.disbursementTrend[i].amountRupees / 1000,
                            ),
                        ],
                      ),
                      LineChartBarData(
                        color: const Color(0xFF059669),
                        spots: [
                          for (
                            var i = 0;
                            i < report.collectionTrend.length;
                            i++
                          )
                            FlSpot(
                              i.toDouble(),
                              report.collectionTrend[i].amountRupees / 1000,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delinquency aging',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...report.buckets.map(
                (bucket) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(bucket.label),
                  subtitle: Text('${bucket.loanCount} overdue installments'),
                  trailing: Text(CurrencyFormatter.format(bucket.amountRupees)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.read<ReportsCubit>().exportCsv(),
                child: const Text('Export CSV'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.read<ReportsCubit>().exportPdf(),
                child: const Text('Export PDF'),
              ),
            ],
          );
        },
      ),
    );
  }
}
