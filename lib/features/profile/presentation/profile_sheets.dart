import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_text_action.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/otp_code_field.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/auth_controller.dart' show withFailureDetail;
import '../domain/profile.dart';
import 'change_email_controller.dart';
import 'profile_controller.dart';

/// "April 30, 2027" in the app's language.
String formatProfileDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(date);

/// Keeps a sheet's content above the keyboard and scrollable on small
/// screens.
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        GatesSpacing.space24,
        0,
        GatesSpacing.space24,
        GatesSpacing.space24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GatesSheetHeader(title: title),
          const SizedBox(height: GatesSpacing.space16),
          ...children,
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GatesSpacing.space12),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: context.gatesText.caption.copyWith(
            color: context.palette.statusError,
          ),
        ),
      ),
    );
  }
}

/// Edits first and last name. Resolves to true once saved.
Future<bool?> showEditNameSheet(BuildContext context, Profile profile) =>
    showGatesSheet<bool>(context, (_) => _EditNameSheet(profile: profile));

class _EditNameSheet extends ConsumerStatefulWidget {
  const _EditNameSheet({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<_EditNameSheet> {
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);
  bool _saving = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  String? _required(String? value) => _submitted && (value ?? '').trim().isEmpty
      ? context.l10n.profileFieldRequired
      : null;

  Future<void> _save() async {
    setState(() => _submitted = true);
    final first = _first.text.trim();
    final last = _last.text.trim();
    if (first.isEmpty || last.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateMine(firstName: first, lastName: last);
      ref.invalidate(myProfileProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = withFailureDetail(
          failureDetail(context.l10n, Failure.from(error)),
          context.l10n.profileSaveFailed,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SheetBody(
      title: l10n.profileEditName,
      children: [
        GatesTextField(
          label: l10n.profileFirstName,
          controller: _first,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          errorText: _required(_first.text),
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: GatesSpacing.space12),
        GatesTextField(
          label: l10n.profileLastName,
          controller: _last,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          errorText: _required(_last.text),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: GatesSpacing.space16),
        if (_error != null) _InlineError(_error!),
        GatesButton(
          label: l10n.profileSave,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

/// The two-step email change. Resolves to true once the new email is
/// confirmed with the code sent to it.
Future<bool?> showChangeEmailSheet(
  BuildContext context,
  String? currentEmail,
) => showGatesSheet<bool>(
  context,
  (_) => _ChangeEmailSheet(currentEmail: currentEmail),
);

class _ChangeEmailSheet extends ConsumerStatefulWidget {
  const _ChangeEmailSheet({required this.currentEmail});

  final String? currentEmail;

  @override
  ConsumerState<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends ConsumerState<_ChangeEmailSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  String? _errorText(ChangeEmailState state) {
    final l10n = context.l10n;
    return switch (state.error) {
      null => null,
      ChangeEmailError.invalidEmail => l10n.profileEmailInvalid,
      ChangeEmailError.sameEmail => l10n.profileEmailSame,
      ChangeEmailError.incompleteCode ||
      ChangeEmailError.invalidCode => l10n.profileEmailInvalidCode,
      ChangeEmailError.rateLimited => l10n.profileEmailRateLimited,
      ChangeEmailError.failed => withFailureDetail(
        state.failure == null ? null : failureDetail(l10n, state.failure!),
        l10n.profileEmailChangeFailed,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = changeEmailControllerProvider(widget.currentEmail);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    ref.listen(provider.select((s) => s.done), (_, done) {
      if (done) Navigator.of(context).pop(true);
    });
    final error = _errorText(state);

    if (state.step == ChangeEmailStep.enterEmail) {
      return _SheetBody(
        title: l10n.profileChangeEmail,
        children: [
          Text(l10n.profileEmailChangeBody, style: GatesTypography.body),
          const SizedBox(height: GatesSpacing.space16),
          GatesTextField(
            label: l10n.profileNewEmail,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            errorText: error,
            autofocus: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: GatesSpacing.space16),
          GatesButton(
            label: l10n.profileEmailSendCode,
            loading: state.isBusy,
            onPressed: state.isBusy
                ? null
                : () => controller.sendCode(_email.text),
          ),
        ],
      );
    }

    return _SheetBody(
      title: l10n.profileChangeEmail,
      children: [
        Text(
          l10n.profileEmailCodeSentTo(state.newEmail),
          style: GatesTypography.body,
        ),
        const SizedBox(height: GatesSpacing.space16),
        OtpCodeField(
          controller: _code,
          label: l10n.profileEmailCodeLabel,
          errorText: error,
          autofillHints: const [AutofillHints.oneTimeCode],
          onCompleted: controller.confirm,
        ),
        const SizedBox(height: GatesSpacing.space16),
        GatesButton(
          label: l10n.profileEmailConfirm,
          loading: state.isBusy,
          onPressed: state.isBusy ? null : () => controller.confirm(_code.text),
        ),
        const SizedBox(height: GatesSpacing.space8),
        GatesTextAction(
          label: state.cooldownRemaining > 0
              ? l10n.profileEmailResendIn(state.cooldownRemaining.toString())
              : l10n.profileEmailResend,
          onPressed: state.cooldownRemaining > 0 || state.isBusy
              ? null
              : controller.resend,
        ),
        GatesTextAction(
          label: l10n.profileEmailUseOther,
          onPressed: state.isBusy
              ? null
              : () {
                  _code.clear();
                  controller.useOtherEmail();
                },
        ),
      ],
    );
  }
}

/// Asks the resident to confirm the deletion request. True when confirmed.
Future<bool?> showDeleteAccountSheet(BuildContext context) =>
    showGatesSheet<bool>(context, (context) {
      final l10n = context.l10n;
      return _SheetBody(
        title: l10n.profileDeleteTitle,
        children: [
          Text(l10n.profileDeleteBody, style: GatesTypography.body),
          const SizedBox(height: GatesSpacing.space24),
          GatesButton(
            label: l10n.profileDeleteConfirm,
            style: GatesButtonStyle.destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: GatesSpacing.space8),
          GatesTextAction(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    });

/// Asks the resident to confirm signing out. True when confirmed.
Future<bool?> showLogoutConfirmSheet(BuildContext context) =>
    showGatesSheet<bool>(context, (context) {
      final l10n = context.l10n;
      return _SheetBody(
        title: l10n.profileLogoutConfirmTitle,
        children: [
          GatesButton(
            label: l10n.commonLogout,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: GatesSpacing.space8),
          GatesTextAction(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    });
