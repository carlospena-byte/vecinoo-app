import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/gates_button.dart';
import '../widgets/gates_text_action.dart';
import '../widgets/vecinoo_brand.dart';
import 'biometric_service.dart';

/// Covers the app with a lock screen while biometric unlock is on: at launch
/// and every time the app comes back from the background. Only active for a
/// signed-in resident.
class BiometricLockGate extends ConsumerStatefulWidget {
  const BiometricLockGate({super.key, required this.child});

  final Widget? child;

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate>
    with WidgetsBindingObserver {
  bool _locked = true;
  bool _prompting = false;
  bool _startupChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _enabled =>
      ref.read(biometricEnabledProvider).value == true &&
      ref.read(currentUserProvider) != null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `paused` = really in the background. `inactive` also fires while the
    // system biometric sheet itself is up, so it must not re-lock.
    if (state == AppLifecycleState.paused && _enabled && !_prompting) {
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked && _enabled) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    _prompting = true;
    final authenticator = ref.read(biometricAuthenticatorProvider);
    final reason = context.l10n.lockReason;
    var ok = false;
    try {
      if (!await authenticator.isAvailable()) {
        // Biometrics were removed from the device: don't trap the resident.
        await ref.read(biometricEnabledProvider.notifier).disable();
        ok = true;
      } else {
        ok = await authenticator.authenticate(reason);
      }
    } finally {
      _prompting = false;
    }
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(biometricEnabledProvider);
    final signedIn = ref.watch(currentUserProvider) != null;

    // First frame with a known preference: lock (and prompt) at startup.
    if (!_startupChecked && enabled.hasValue) {
      _startupChecked = true;
      if (enabled.value == true && signedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _unlock();
        });
      } else {
        _locked = false;
      }
    }

    final showLock =
        _locked && enabled.value == true && signedIn && _startupChecked;
    // Wait for the preference before showing anything that could flash.
    if (!_startupChecked) return const SizedBox.shrink();

    return Stack(
      children: [
        if (widget.child != null) Positioned.fill(child: widget.child!),
        if (showLock)
          Positioned.fill(
            child: _LockScreen(onUnlock: _unlock, onLogout: _logout),
          ),
      ],
    );
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) setState(() => _locked = false);
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock, required this.onLogout});

  final VoidCallback onUnlock;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: context.palette.bgSurface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VecinooWordmark(),
              const VecinooMark(),
              Text(l10n.lockTitle, style: GatesTypography.headingLarge),
              const SizedBox(height: 12),
              Text(
                l10n.lockBody,
                style: GatesTypography.body.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const Spacer(),
              GatesButton(label: l10n.lockUnlock, onPressed: onUnlock),
              const SizedBox(height: 8),
              GatesTextAction(label: l10n.commonLogout, onPressed: onLogout),
            ],
          ),
        ),
      ),
    );
  }
}
