import '../../../l10n/l10n.dart';
import '../domain/incident.dart';

String incidentStatusLabel(AppLocalizations l10n, IncidentStatus status) {
  switch (status) {
    case IncidentStatus.newIncident:
      return l10n.incidentsStatusNew;
    case IncidentStatus.inProgress:
      return l10n.incidentsStatusInProgress;
    case IncidentStatus.resolved:
      return l10n.incidentsStatusResolved;
    case IncidentStatus.closed:
      return l10n.incidentsStatusClosed;
    case IncidentStatus.cancelled:
      return l10n.incidentsStatusCancelled;
  }
}

String incidentPriorityLabel(AppLocalizations l10n, IncidentPriority priority) {
  switch (priority) {
    case IncidentPriority.low:
      return l10n.incidentsPriorityLow;
    case IncidentPriority.medium:
      return l10n.incidentsPriorityMedium;
    case IncidentPriority.high:
      return l10n.incidentsPriorityHigh;
    case IncidentPriority.urgent:
      return l10n.incidentsPriorityUrgent;
  }
}
