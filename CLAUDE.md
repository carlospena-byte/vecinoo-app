# gates-app

- **Feedback messages:** always use `showGatesToast` (`lib/core/widgets/gates_toast.dart`, Figma "Toast"). Never use `SnackBar` / `showSnackBar` / `MaterialBanner`; `test/no_raw_snackbar_test.dart` fails if you do.
- **Pickers:** use the shared spinner time picker and shared calendar bottom sheet, never Material defaults.
- **Colors:** never hardcode colors; read semantic tokens via `context.palette` (`lib/core/theme/gates_palette.dart`, Figma "Vecinoo / Color" Light/Dark). Secondary text uses `context.gatesText`. Text on filled buttons uses `textOnBrand` / `textOnDanger`, not white. `test/no_hardcoded_colors_test.dart` and `test/theme_contrast_test.dart` enforce this.
- **Accessibility:** icon-only controls need a `tooltip`/`Semantics` label (`GatesAddButton` takes `semanticLabel`); tappable custom widgets wrap their content in `Semantics(button: true, …)` and expose `selected` when they can be selected; form fields announce their label (visible label text is wrapped in `ExcludeSemantics`); touch targets ≥ 44pt; layouts must not overflow up to 3x text (`test/text_scale_test.dart`, `test/accessibility_test.dart`).
