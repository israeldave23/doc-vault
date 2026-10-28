import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_provider.dart';
import '../../settings/screens/settings_screen.dart';

/// Three slides from the spec: privacy, reminders, then the lock.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = <(IconData, String, String)>[
    (
      Icons.lock_outline,
      'Your documents stay on your phone',
      'IDs, licenses and permits are stored encrypted on this device. '
          'No account, no server, nothing is uploaded.',
    ),
    (
      Icons.notifications_active_outlined,
      'Reminders before it is too late',
      'Get warned 90, 30, 7 and 1 day before something expires — with daily '
          'reminders through the final week.',
    ),
    (
      Icons.fingerprint,
      'Lock it with your fingerprint',
      'Add a PIN or biometric lock so nobody who picks up your phone can open '
          'the vault.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .update(settings.copyWith(onboardingCompleted: true));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Rebuilds straight to the dashboard once the flag flips.
    final done = ref.watch(settingsProvider).onboardingCompleted;
    if (done) return const DashboardReplacement();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final (icon, title, body) = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 96, color: theme.colorScheme.primary),
                        const SizedBox(height: 32),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 16),
                        Text(body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: _page == _slides.length - 1
                    ? FilledButton(
                        onPressed: _finish,
                        child: const Text('Get started'),
                      )
                    : FilledButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                        child: const Text('Next'),
                      ),
              ),
            ),
            if (_page == _slides.length - 1)
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen()),
                ),
                child: const Text('Set up app lock now'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Stand-in used while the onboarding flag flips; the app's home switches to
/// the dashboard on the next build.
class DashboardReplacement extends StatelessWidget {
  const DashboardReplacement({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
