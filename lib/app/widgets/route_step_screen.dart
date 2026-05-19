import 'package:flutter/material.dart';

class RouteStepScreen extends StatelessWidget {
  const RouteStepScreen({
    super.key,
    required this.title,
    required this.description,
    this.eyebrow,
    this.actions = const [],
    this.details = const [],
  });

  final String title;
  final String description;
  final String? eyebrow;
  final List<Widget> actions;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            if (eyebrow != null) ...[
              Text(
                eyebrow!,
                style: textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(description, style: textTheme.bodyLarge),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 28),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final detail in details)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(detail)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 32),
              for (final action in actions) ...[
                action,
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
