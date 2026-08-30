import 'package:flutter/material.dart';

enum StatusStepState { completed, current, upcoming, failed }

class StatusStep {
  const StatusStep({
    required this.title,
    this.subtitle,
    this.state = StatusStepState.upcoming,
  });

  final String title;
  final String? subtitle;
  final StatusStepState state;
}

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({required this.steps, super.key});

  final List<StatusStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          _TimelineRow(step: steps[index], isLast: index == steps.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final StatusStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = switch (step.state) {
      StatusStepState.completed => const Color(0xFF059669),
      StatusStepState.current => const Color(0xFF2563EB),
      StatusStepState.failed => const Color(0xFFBA1A1A),
      StatusStepState.upcoming => Theme.of(context).colorScheme.outline,
    };
    final icon = switch (step.state) {
      StatusStepState.completed => Icons.check_circle,
      StatusStepState.current => Icons.timelapse,
      StatusStepState.failed => Icons.cancel,
      StatusStepState.upcoming => Icons.radio_button_unchecked,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: color, size: 20),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color.withAlpha(60),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(fontWeight: FontWeight.w600, color: color),
                  ),
                  if (step.subtitle != null)
                    Text(
                      step.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
