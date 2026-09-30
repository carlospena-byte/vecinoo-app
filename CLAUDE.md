# gates-app

- **Feedback messages:** always use `showGatesToast` (`lib/core/widgets/gates_toast.dart`, Figma "Toast"). Never use `SnackBar` / `showSnackBar` / `MaterialBanner`; `test/no_raw_snackbar_test.dart` fails if you do.
- **Pickers:** use the shared spinner time picker and shared calendar bottom sheet, never Material defaults.
