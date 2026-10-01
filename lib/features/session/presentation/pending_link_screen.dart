import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/register_screen.dart'
    show pendingInvitationCodePrefsKey;
import 'session_controller.dart';
import '../../../l10n/l10n.dart';

/// Shown when the resident has signed in but no admin has linked them to
/// a unit yet (see `unit_members` in gates-admin). Also where an
/// invitation code is redeemed: either automatically, if one was saved
/// during registration because email confirmation was pending (see
/// register_screen.dart), or typed in manually here.
class PendingLinkScreen extends ConsumerStatefulWidget {
  const PendingLinkScreen({super.key});

  @override
  ConsumerState<PendingLinkScreen> createState() => _PendingLinkScreenState();
}

class _PendingLinkScreenState extends ConsumerState<PendingLinkScreen> {
  final _codeController = TextEditingController();
  bool _isRedeeming = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _redeemSavedCodeIfAny();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemSavedCodeIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(pendingInvitationCodePrefsKey);
    if (savedCode == null) return;
    await prefs.remove(pendingInvitationCodePrefsKey);
    if (!mounted) return;
    await _redeem(savedCode);
  }

  Future<void> _redeem(String code) async {
    if (code.trim().isEmpty) return;
    setState(() {
      _isRedeeming = true;
      _errorText = null;
    });
    try {
      await ref.read(sessionRepositoryProvider).acceptInvitation(code.trim());
      ref.invalidate(myMembershipsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = context.l10n.authInvitationInvalid);
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bgSubtle,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: context.l10n.commonLogout,
                  icon: Icon(
                    Icons.logout,
                    color: context.palette.textSecondary,
                  ),
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'gates',
                    style: GatesTypography.headingMedium.copyWith(
                      color: context.palette.textBrand,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space4),
                  Text(
                    context.l10n.commonForResidents,
                    style: context.gatesText.caption,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                context.l10n.sessionPendingTitle,
                style: GatesTypography.headingLarge,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.sessionPendingBody,
                style: GatesTypography.body.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              GatesTextField(
                label: context.l10n.authInvitationCode,
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                helperText: context.l10n.sessionCodeDigitsHelper,
                errorText: _errorText,
                enabled: !_isRedeeming,
              ),
              const SizedBox(height: 16),
              GatesButton(
                label: context.l10n.sessionUseCode,
                onPressed: _isRedeeming
                    ? null
                    : () => _redeem(_codeController.text),
                loading: _isRedeeming,
              ),
              const SizedBox(height: 12),
              GatesButton(
                label: context.l10n.sessionAlreadyLinkedRetry,
                style: GatesButtonStyle.secondary,
                onPressed: () => ref.invalidate(myMembershipsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
