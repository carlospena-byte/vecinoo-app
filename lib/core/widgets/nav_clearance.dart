import 'package:flutter/widgets.dart';

/// Bottom padding a tab screen's scrollable needs so its last item clears the
/// floating bottom navigation (72px pill + 24px margin + safe area + a gap).
double homeNavClearance(BuildContext context) =>
    72 + 24 + MediaQuery.paddingOf(context).bottom + 24;
