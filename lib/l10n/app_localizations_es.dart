// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get amenitiesBack => 'Volver';

  @override
  String get amenitiesClose => 'Cerrar';

  @override
  String get amenitiesCancel => 'Cancelar';

  @override
  String get amenitiesSave => 'Guardar';

  @override
  String get amenitiesContinue => 'Continuar';

  @override
  String get amenitiesChange => 'Cambiar';

  @override
  String get amenitiesEdit => 'Editar';

  @override
  String get amenitiesTryAgain => 'Intenta de nuevo.';

  @override
  String get amenitiesDayMon => 'Lun';

  @override
  String get amenitiesDayTue => 'Mar';

  @override
  String get amenitiesDayWed => 'Mié';

  @override
  String get amenitiesDayThu => 'Jue';

  @override
  String get amenitiesDayFri => 'Vie';

  @override
  String get amenitiesDaySat => 'Sáb';

  @override
  String get amenitiesDaySun => 'Dom';

  @override
  String get amenitiesPaymentCash => 'Efectivo';

  @override
  String get amenitiesPaymentCard => 'Tarjeta';

  @override
  String get amenitiesPaymentTransfer => 'Transferencia';

  @override
  String get amenitiesPeriodDay => 'día';

  @override
  String get amenitiesPeriodWeek => 'semana';

  @override
  String get amenitiesPeriodMonth => 'mes';

  @override
  String amenitiesBookingLimit(int count, String period) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Máximo $count reservas por $period',
      one: 'Máximo 1 reserva por $period',
    );
    return '$_temp0';
  }

  @override
  String amenitiesDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String amenitiesDurationMinutes(int count) {
    return '$count minutos';
  }

  @override
  String amenitiesBlackoutWithReason(String range, String reason) {
    return '$range · $reason';
  }

  @override
  String amenitiesBlackoutClosed(String range) {
    return 'Cerrado $range';
  }

  @override
  String amenitiesBlackoutClosedWithReason(String range, String reason) {
    return 'Cerrado $range: $reason';
  }

  @override
  String amenitiesBlackoutRangeWithReason(String range, String reason) {
    return '$range: $reason';
  }

  @override
  String get amenitiesNewBooking => 'Nueva reserva';

  @override
  String get amenitiesListLoadError => 'No se pudieron cargar las amenidades.';

  @override
  String get amenitiesListEmpty =>
      'Tu residencial aún no tiene amenidades configuradas.';

  @override
  String get amenitiesListHeading => 'Amenidades';

  @override
  String amenitiesCapacity(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '1 persona',
    );
    return '$_temp0';
  }

  @override
  String get amenitiesBookingRequiredBadge => 'Reserva obligatoria';

  @override
  String get amenitiesNoBookingBadge => 'Sin reserva';

  @override
  String get amenitiesDetailTitle => 'Amenidad';

  @override
  String get amenitiesDetailLoadError => 'No se pudo cargar la amenidad.';

  @override
  String amenitiesPhotoLabel(int index, int total) {
    return 'Fotografía $index de $total';
  }

  @override
  String get amenitiesPhotoHint => 'Toca dos veces para ampliar';

  @override
  String get amenitiesBookingRequired => 'Reservación necesaria';

  @override
  String get amenitiesFreeAccess => 'Acceso libre';

  @override
  String get amenitiesOffersHeading => 'Lo que ofrece este espacio';

  @override
  String get amenitiesViewAllServices => 'Ver todos los servicios';

  @override
  String get amenitiesAllServices => 'Todos los servicios';

  @override
  String get amenitiesAboutHeading => 'Un espacio para compartir';

  @override
  String get amenitiesScheduleHeading => 'Horarios de uso';

  @override
  String get amenitiesBeforeBookingHeading => 'Antes de reservar';

  @override
  String get amenitiesDurationPerBooking => 'Duración por reserva';

  @override
  String get amenitiesLimitPerResident => 'Límite por residente';

  @override
  String get amenitiesClosedDates => 'Fechas cerradas';

  @override
  String get amenitiesCostHeading => 'Costo de la reserva';

  @override
  String get amenitiesNoCost => 'Sin costo';

  @override
  String amenitiesPerBookingOf(String duration) {
    return 'Por reserva de $duration';
  }

  @override
  String get amenitiesAcceptedMethods => 'Métodos aceptados';

  @override
  String get amenitiesTerms => 'Términos y condiciones';

  @override
  String get amenitiesPerBooking => 'por reserva';

  @override
  String amenitiesPerBookingDuration(String duration) {
    return 'por reserva · $duration';
  }

  @override
  String get amenitiesPickDate => 'Elegir fecha';

  @override
  String get amenitiesCostInfoNote =>
      'El costo y los métodos son informativos; esta app no procesa pagos.';

  @override
  String get amenitiesNotesOptional => 'Notas (opcional)';

  @override
  String get amenitiesNotesHint => 'Agrega una nota para tu reserva';

  @override
  String get amenitiesDateTimeTitle => 'Fecha y horario';

  @override
  String get amenitiesEndAfterStartError =>
      'La hora de fin debe ser después de la hora de inicio.';

  @override
  String get amenitiesStart => 'Inicio';

  @override
  String get amenitiesEnd => 'Fin';

  @override
  String get amenitiesEndsAt => 'Termina a las';

  @override
  String amenitiesEachBookingLasts(String duration) {
    return 'Cada reserva dura $duration.';
  }

  @override
  String get amenitiesReviewTitle => 'Revisar reserva';

  @override
  String get amenitiesErrorPastDateTitle => 'Fecha en el pasado';

  @override
  String get amenitiesErrorPastDateMessage =>
      'La fecha seleccionada ya pasó. Elige una fecha actual o futura.';

  @override
  String get amenitiesErrorScheduleTitle => 'Error de horario';

  @override
  String get amenitiesErrorConflictTitle => 'Horario no disponible';

  @override
  String get amenitiesErrorConflictMessage =>
      'Otra reserva ocupa este horario. Tus notas se conservaron.';

  @override
  String get amenitiesErrorBlackoutTitle => 'Fecha cerrada';

  @override
  String get amenitiesErrorBlackoutMessage =>
      'La amenidad estará cerrada el día elegido. Selecciona otra fecha.';

  @override
  String get amenitiesErrorSubmitTitle => 'No se pudo enviar la reserva';

  @override
  String get amenitiesErrorSubmitMessage =>
      'Intenta de nuevo en unos segundos.';

  @override
  String get amenitiesDate => 'Fecha';

  @override
  String get amenitiesSchedule => 'Horario';

  @override
  String get amenitiesNoNotes => 'Sin notas';

  @override
  String get amenitiesCancelFutureHint =>
      'Puedes cancelar una reserva futura desde Mis reservas.';

  @override
  String get amenitiesConfirmBooking => 'Confirmar reserva';

  @override
  String get amenitiesResultConfirmedHeading => 'Todo listo para tu reserva';

  @override
  String get amenitiesPendingConfirmation => 'Pendiente de confirmación';

  @override
  String get amenitiesResultConfirmedSubtext =>
      'Consulta los datos y el estado desde Mis reservas.';

  @override
  String get amenitiesResultPendingSubtext =>
      'Tu solicitud fue enviada. Aún no está confirmada; consulta su estado en Mis reservas.';

  @override
  String get amenitiesResultConfirmedTitle => 'Reserva confirmada';

  @override
  String get amenitiesResultPendingTitle => 'Solicitud enviada';

  @override
  String amenitiesNotesValue(String notes) {
    return 'Notas: $notes';
  }

  @override
  String get amenitiesViewMyBookings => 'Ver mis reservas';

  @override
  String get amenitiesStatusConfirmed => 'Confirmada';

  @override
  String get amenitiesStatusPending => 'Pendiente';

  @override
  String get amenitiesStatusCancelled => 'Cancelada';

  @override
  String get amenitiesStatusExpired => 'Expirada';

  @override
  String get amenitiesBannerConfirmedMessage =>
      'La reserva se registró correctamente.';

  @override
  String get amenitiesBannerPendingMessage =>
      'La solicitud espera confirmación.';

  @override
  String get amenitiesBookingsTitle => 'Reservas';

  @override
  String get amenitiesTabPending => 'Pendientes';

  @override
  String get amenitiesTabConfirmed => 'Confirmadas';

  @override
  String get amenitiesTabHistory => 'Historial';

  @override
  String get amenitiesBookingsLoadError =>
      'No se pudieron cargar tus reservas.';

  @override
  String get amenitiesEmptyPending => 'No tienes reservas pendientes.';

  @override
  String get amenitiesEmptyConfirmed => 'No tienes reservas confirmadas.';

  @override
  String get amenitiesEmptyHistory => 'Aún no tienes historial de reservas.';

  @override
  String get amenitiesPillConfirmed => 'Reserva confirmada';

  @override
  String get amenitiesPillPast => 'Reserva pasada';

  @override
  String get amenitiesPillCancelled => 'Reserva cancelada';

  @override
  String get amenitiesPillExpired => 'Reserva expirada';

  @override
  String get amenitiesBookingDetailTitle => 'Detalle de reserva';

  @override
  String get amenitiesSpace => 'Espacio';

  @override
  String get amenitiesReason => 'Motivo';

  @override
  String get amenitiesReasonOptional => 'Motivo (opcional)';

  @override
  String get amenitiesReasonHint => 'Cuéntanos por qué cancelas, si quieres';

  @override
  String get amenitiesSwipeToCancel => 'Desliza para cancelar';

  @override
  String get amenitiesCancelFailedTitle => 'No pudimos cancelar la reserva';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonProfile => 'Perfil';

  @override
  String get commonLogout => 'Cerrar sesión';

  @override
  String get commonForResidents => 'PARA RESIDENTES';

  @override
  String get commonToastSuccess => 'Éxito';

  @override
  String get commonToastInfo => 'Información';

  @override
  String get commonToastWarning => 'Advertencia';

  @override
  String get commonToastError => 'Error';

  @override
  String get commonMonth => 'Mes';

  @override
  String get commonDate => 'Fecha';

  @override
  String get commonCountry => 'País';

  @override
  String get commonPhone => 'Teléfono';

  @override
  String commonCountryCode(String dialCode) {
    return 'Código de país $dialCode';
  }

  @override
  String commonCharactersCount(int length) {
    return '$length caracteres';
  }

  @override
  String get commonTapTwiceToConfirm => 'Toca dos veces para confirmar';

  @override
  String get commonDoormanNotesLabel => 'Notas para portería (opcional)';

  @override
  String get commonDoormanNotesHint => 'Agrega una indicación';

  @override
  String get commonUploadFormats => 'JPG o PNG · hasta 10 MB';

  @override
  String get commonUploadReady => 'Foto lista';

  @override
  String get commonUploadUploading => 'Subiendo foto…';

  @override
  String get commonUploadPreparing => 'Preparando…';

  @override
  String get commonUploadErrorDefault =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get commonUploadDocument => 'Subir documento';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get commonChooseFile => 'Elegir archivo';

  @override
  String get commonCountryHonduras => 'Honduras';

  @override
  String get commonCountryGuatemala => 'Guatemala';

  @override
  String get commonCountryElSalvador => 'El Salvador';

  @override
  String get commonCountryNicaragua => 'Nicaragua';

  @override
  String get commonCountryCostaRica => 'Costa Rica';

  @override
  String get commonCountryPanama => 'Panamá';

  @override
  String get commonCountryMexico => 'México';

  @override
  String get commonCountryUnitedStates => 'Estados Unidos';

  @override
  String get authBiometricTitle => 'Entra más rápido';

  @override
  String get authBiometricBody =>
      'Usa tu rostro o huella para entrar.\nPuedes configurarlo más adelante.';

  @override
  String get authBiometricSetup => 'Configurar biometría';

  @override
  String get authBiometricSkip => 'Omitir por ahora';

  @override
  String get authInvitationPending =>
      'Ya tienes una invitación pendiente. Usa tu código de invitación para activar tu cuenta.';

  @override
  String get authEmailUnknown =>
      'No reconocemos ese correo. Por favor comunícate con el administrador de tu residencial.';

  @override
  String get authSendCodeFailed =>
      'No se pudo enviar el código. Intenta de nuevo.';

  @override
  String get authLoginTitle => 'Tu hogar,\nen un solo lugar.';

  @override
  String get authLoginSubtitle =>
      'Pagos, avisos y visitas.\nTodo cerca, todo en vecinoo.';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authEmailHint => 'nombre@correo.com';

  @override
  String get authEmailInvalid => 'Correo inválido';

  @override
  String get authHaveInvitationCode =>
      '¿Tienes un código de invitación? Ingrésalo aquí.';

  @override
  String get authOtpIntroEmail =>
      'Para iniciar sesión, ingresa el nuevo código de 6 dígitos que enviamos a';

  @override
  String get authOtpIntroSms =>
      'Para iniciar sesión, ingresa el nuevo código de 6 dígitos que enviamos por SMS a';

  @override
  String authEnterDigits(int length) {
    return 'Ingresa los $length dígitos';
  }

  @override
  String get authOtpWrongOrExpired => 'Código incorrecto o expirado.';

  @override
  String get authOtpResentTitle => 'Código reenviado';

  @override
  String get authOtpResentMessage => 'Puedes pedir otro en 60 segundos.';

  @override
  String get authOtpResendFailedTitle => 'No pudimos reenviar el código';

  @override
  String get authOtpResendFailedMessage => 'Intenta de nuevo en un minuto.';

  @override
  String get authInvitationValidated => 'Invitación validada';

  @override
  String get authCheckEmail => 'Revisa tu correo';

  @override
  String get authCheckPhone => 'Revisa tu teléfono';

  @override
  String get authVerificationCode => 'Código de verificación';

  @override
  String get authVerifyAndSignIn => 'Verificar e iniciar sesión';

  @override
  String get authSending => 'Enviando...';

  @override
  String authResendIn(int seconds) {
    return 'Reenviar código en ${seconds}s';
  }

  @override
  String get authResend => 'Reenviar código';

  @override
  String get authCommunityAccess => 'Tu acceso a la comunidad';

  @override
  String authResidentName(String name) {
    return '$name · Residente';
  }

  @override
  String get authInvitationInvalid => 'Código inválido, ya usado o expirado.';

  @override
  String get authSupportTitle => 'Contacta a soporte';

  @override
  String get authSupportMessage => 'Escríbenos a soporte@vecinoo.app';

  @override
  String get authValidateCodeTitle => 'Valida tu código';

  @override
  String authValidateCodeBody(int length) {
    return 'Ingresa el código de $length dígitos que recibiste en tu invitación.';
  }

  @override
  String get authInvitationCode => 'Código de invitación';

  @override
  String get authInvitationHelper =>
      'Revisa tu tarjeta o correo de bienvenida.';

  @override
  String get authAcceptInvitation => 'Aceptar invitación';

  @override
  String get authNoInvitationContactSupport =>
      '¿No recibiste tu invitación? Contactar soporte';

  @override
  String get sessionPendingTitle => 'Cuenta pendiente';

  @override
  String get sessionPendingBody =>
      'Todavía no tienes una unidad vinculada. Pide al administrador que te vincule o ingresa un código de invitación.';

  @override
  String get sessionCodeDigitsHelper => '6 dígitos.';

  @override
  String get sessionUseCode => 'Usar código';

  @override
  String get sessionAlreadyLinkedRetry => 'Ya me vincularon, reintentar';

  @override
  String get sessionSelectUnitTitle => 'Selecciona tu unidad';

  @override
  String get sessionSelectUnitBody => 'Elige la unidad que quieres consultar.';

  @override
  String get profileLoadFailed => 'No se pudo cargar tu perfil.';

  @override
  String get profileChangeUnit => 'Cambiar unidad';

  @override
  String get profileAppearance => 'Apariencia';

  @override
  String get profileThemeLight => 'Claro';

  @override
  String get profileThemeDark => 'Oscuro';

  @override
  String get profileThemeSystem => 'Sistema';

  @override
  String get homeNavHome => 'Inicio';

  @override
  String get homeIncidents => 'Incidencias';

  @override
  String get homeReservations => 'Reservas';

  @override
  String get homeVisits => 'Visitas';

  @override
  String get homeComingSoon => 'Próximamente';

  @override
  String get homeGreeting => 'Hola';

  @override
  String homeGreetingNamed(String name) {
    return 'Hola, $name';
  }

  @override
  String get homeTagline => 'Tu comunidad, más cerca.';

  @override
  String get homeNotifications => 'Notificaciones';

  @override
  String get homeToday => 'Hoy';

  @override
  String get homeTomorrow => 'Mañana';

  @override
  String get homePm => 'p. m.';

  @override
  String get homeAm => 'a. m.';

  @override
  String get homeBookingsLoadFailed => 'No se pudieron cargar tus reservas.';

  @override
  String get homeNoBookingsTitle => 'Un espacio para disfrutar';

  @override
  String get homeNoBookingsDetail => 'Aún no tienes reservas próximas.';

  @override
  String get homeExploreAmenities => 'Explorar amenidades';

  @override
  String homeVisitsSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visitas\npara hoy',
      one: '1 visita\npara hoy',
      zero: 'Sin visitas\nprevistas',
    );
    return '$_temp0';
  }

  @override
  String homeIncidentsSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reportes\nen seguimiento',
      one: '1 reporte\nen seguimiento',
      zero: 'Sin incidencias\nreportadas',
    );
    return '$_temp0';
  }

  @override
  String get homeInvite => 'Invitar';

  @override
  String get homeViewVisits => 'Ver visitas';

  @override
  String get homeReport => 'Reportar';

  @override
  String get homeViewReport => 'Ver reporte';

  @override
  String get incidentsStatusNew => 'Nueva';

  @override
  String get incidentsStatusInProgress => 'En progreso';

  @override
  String get incidentsStatusResolved => 'Resuelta';

  @override
  String get incidentsStatusClosed => 'Cerrada';

  @override
  String get incidentsStatusCancelled => 'Cancelada';

  @override
  String get incidentsPriorityLow => 'Baja';

  @override
  String get incidentsPriorityMedium => 'Media';

  @override
  String get incidentsPriorityHigh => 'Alta';

  @override
  String get incidentsPriorityUrgent => 'Urgente';

  @override
  String get incidentsEditorDescriptionLabel => 'Descripción (opcional)';

  @override
  String get incidentsEditorBold => 'Negrita';

  @override
  String get incidentsEditorItalic => 'Cursiva';

  @override
  String get incidentsEditorList => 'Lista';

  @override
  String get incidentsEditorLink => 'Enlace';

  @override
  String get incidentsEditorDescriptionHint => 'Describe qué ocurrió y dónde…';

  @override
  String get incidentsEditorLinkInvalid => 'Escribe un enlace válido.';

  @override
  String get incidentsEditorAddLink => 'Agregar enlace';

  @override
  String get incidentsEditorLinkNoSelection =>
      'Sin texto seleccionado, se insertará el enlace tal cual.';

  @override
  String get incidentsEditorLinkHint => 'https://…';

  @override
  String get incidentsListEmptyPending => 'No tienes incidencias pendientes.';

  @override
  String get incidentsListEmptyInProgress => 'No tienes incidencias en curso.';

  @override
  String get incidentsListEmptyHistory =>
      'Aún no tienes historial de incidencias.';

  @override
  String get incidentsListTitle => 'Incidencias';

  @override
  String get incidentsTabPending => 'Pendientes';

  @override
  String get incidentsTabInProgress => 'En curso';

  @override
  String get incidentsTabHistory => 'Historial';

  @override
  String get incidentsListLoadError => 'No se pudieron cargar las incidencias.';

  @override
  String get incidentsDetailLoadError => 'No se pudo cargar la incidencia.';

  @override
  String get incidentsEditAction => 'Editar incidencia';

  @override
  String get incidentsCancelAction => 'Cancelar incidencia';

  @override
  String get incidentsCancelSheetBody =>
      'Ya no se le dará seguimiento. La incidencia seguirá en tu historial como cancelada.';

  @override
  String get incidentsCancelConfirm => 'Sí, cancelar incidencia';

  @override
  String get incidentsCancelledToast => 'Incidencia cancelada';

  @override
  String get incidentsCancelFailedTitle => 'No pudimos cancelar la incidencia';

  @override
  String get incidentsTryAgain => 'Intenta de nuevo.';

  @override
  String get incidentsDetailTitle => 'Incidencia';

  @override
  String incidentsDetailReportedOn(String date) {
    return 'Reportada el $date';
  }

  @override
  String get incidentsDetailDescription => 'Descripción';

  @override
  String get incidentsDetailPhotos => 'Fotografías';

  @override
  String get incidentsAttachedPhoto => 'Fotografía adjunta';

  @override
  String get incidentsAttachedPhotoHint => 'Toca dos veces para ampliar';

  @override
  String incidentsReportMaxPhotos(int count) {
    return 'Máximo $count fotografías';
  }

  @override
  String incidentsReportAddedFirst(int count) {
    return 'Agregamos las primeras $count.';
  }

  @override
  String get incidentsReportPhotosOpenFailed =>
      'No pudimos abrir las fotografías';

  @override
  String get incidentsReportPhotosPermissions =>
      'Revisa los permisos e intenta de nuevo.';

  @override
  String get incidentsReportSaveFailed => 'No pudimos guardar los cambios';

  @override
  String get incidentsReportSaveFailedBody =>
      'Tus cambios se conservaron. Intenta de nuevo.';

  @override
  String get incidentsReportSendFailed => 'No pudimos enviar el reporte';

  @override
  String get incidentsReportSendFailedBody =>
      'Tus datos se conservaron. Intenta de nuevo.';

  @override
  String get incidentsReportChangesSaved => 'Cambios guardados';

  @override
  String get incidentsReportDiscardTitle => '¿Descartar cambios?';

  @override
  String get incidentsReportDiscardBody =>
      'Si sales ahora, los cambios que hiciste no se guardarán.';

  @override
  String get incidentsReportDiscardAction => 'Descartar cambios';

  @override
  String get incidentsReportKeepEditing => 'Seguir editando';

  @override
  String get incidentsReportEditTitle => 'Editar incidencia';

  @override
  String get incidentsReportIntro =>
      'Cuéntanos qué ocurrió. Un administrador dará seguimiento.';

  @override
  String get incidentsReportCategoryLabel => 'Categoría (opcional)';

  @override
  String get incidentsReportCategoryPlaceholder => 'Seleccionar categoría';

  @override
  String get incidentsReportTitleLabel => 'Título *';

  @override
  String get incidentsReportTitleHint => '¿Qué problema quieres reportar?';

  @override
  String get incidentsReportSaveChanges => 'Guardar cambios';

  @override
  String get incidentsReportSavingChanges => 'Estamos guardando tus cambios';

  @override
  String get incidentsReportSending => 'Estamos enviando tu reporte';

  @override
  String get incidentsReportWaitMessage =>
      'Espera un momento mientras guardamos los datos y las fotografías.';

  @override
  String get incidentsReportSendingButton => 'Enviando…';

  @override
  String get incidentsReportPhotoErrorTitle => 'Una foto no se pudo subir';

  @override
  String get incidentsReportPhotoErrorBody =>
      'Reintenta la carga o elimina esa foto para continuar.';

  @override
  String get incidentsReportRetryPhoto => 'Reintentar fotografía';

  @override
  String get incidentsReportDone => 'Listo';

  @override
  String get incidentsReportSentTitle => 'Incidencia enviada';

  @override
  String get incidentsReportSentHeadline => 'Tu reporte fue enviado';

  @override
  String get incidentsReportSentBody =>
      'Un administrador dará seguimiento a la incidencia.';

  @override
  String get incidentsReportReceived => 'Reporte recibido';

  @override
  String get incidentsReportBackHome => 'Volver al inicio';

  @override
  String get incidentsReportPhotosOptional => 'Fotografías (opcional)';

  @override
  String get incidentsReportAddPhotos => 'Agregar fotografías';

  @override
  String get incidentsReportAddMorePhotos => 'Agregar más fotos';

  @override
  String incidentsReportUpToPhotos(int count) {
    return 'Hasta $count fotografías';
  }

  @override
  String get incidentsReportRemovePhoto => 'Eliminar fotografía';

  @override
  String get incidentsReportUploading => 'Subiendo…';

  @override
  String get incidentsReportRetryUploadPhoto =>
      'Reintentar subida de la fotografía';

  @override
  String get incidentsReportRetry => 'Reintentar';

  @override
  String get incidentsReportPhotoSourceBody =>
      'Elige cómo quieres agregar tus fotos.';

  @override
  String get incidentsReportTakePhoto => 'Tomar foto';

  @override
  String get incidentsReportChooseGallery => 'Elegir de la galería';

  @override
  String get incidentsReportCancel => 'Cancelar';

  @override
  String get incidentsReportAction => 'Reportar incidencia';

  @override
  String get visitsStatusPendingRegistration => 'Pendiente de registro';

  @override
  String get visitsStatusScheduled => 'Programada';

  @override
  String get visitsStatusActive => 'Activa';

  @override
  String get visitsStatusInside => 'Dentro';

  @override
  String get visitsStatusCompleted => 'Completada';

  @override
  String get visitsStatusCancelled => 'Cancelada';

  @override
  String get visitsStatusRejected => 'Rechazada';

  @override
  String get visitsStatusExpired => 'Expirada';

  @override
  String get visitsTypeFrequent => 'Frecuente';

  @override
  String get visitsTypeDelivery => 'Delivery/Proveedor';

  @override
  String get visitsTypeFastlane => 'FastLane';

  @override
  String get visitsRoleFamiliar => 'Familiar';

  @override
  String get visitsRoleEntrenador => 'Entrenador';

  @override
  String get visitsRoleEmpleado => 'Empleado';

  @override
  String get visitsRoleProveedor => 'Proveedor';

  @override
  String get visitsRoleVisitante => 'Visitante';

  @override
  String get visitsRoleInvitado => 'Invitado';

  @override
  String get visitsProviderKindProveedor => 'Proveedor';

  @override
  String get visitsProviderKindDelivery => 'Delivery';

  @override
  String get visitsProviderKindPaqueteria => 'Paquetería';

  @override
  String get visitsRecurrenceMonFri => 'Lunes a viernes';

  @override
  String get visitsRecurrenceMonSat => 'Lunes a sábado';

  @override
  String get visitsRecurrenceDaily => 'Todos los días';

  @override
  String get visitsRecurrenceCustom => 'Personalizado';

  @override
  String get visitsWeekdayMon => 'Lun';

  @override
  String get visitsWeekdayTue => 'Mar';

  @override
  String get visitsWeekdayWed => 'Mié';

  @override
  String get visitsWeekdayThu => 'Jue';

  @override
  String get visitsWeekdayFri => 'Vie';

  @override
  String get visitsWeekdaySat => 'Sáb';

  @override
  String get visitsWeekdaySun => 'Dom';

  @override
  String get visitsFrequentAccess => 'Acceso frecuente';

  @override
  String get visitsAllDay => 'Todo el día';

  @override
  String get visitsMovementDayToday => 'hoy';

  @override
  String get visitsMovementDayYesterday => 'ayer';

  @override
  String visitsMovementDayDate(String date) {
    return 'el $date';
  }

  @override
  String visitsLastEntry(String day, String time) {
    return 'Ingreso $day, $time';
  }

  @override
  String visitsLastExit(String day, String time) {
    return 'Salida $day, $time';
  }

  @override
  String get visitsToday => 'Hoy';

  @override
  String get visitsTomorrow => 'Mañana';

  @override
  String get visitsPendingInvitationName => 'Invitación por completar';

  @override
  String get visitsListEmptyPending => 'No tienes visitas pendientes.';

  @override
  String get visitsListEmptyOngoing => 'No tienes visitas en curso.';

  @override
  String get visitsListEmptyHistory => 'Aún no tienes historial de visitas.';

  @override
  String visitsListGroupToday(String dayMonth) {
    return 'Accesos para hoy · $dayMonth';
  }

  @override
  String visitsListGroupTomorrow(String dayMonth) {
    return 'Mañana · $dayMonth';
  }

  @override
  String visitsListFastlaneSchedule(String day, String time) {
    return '$day · Llegada prevista $time';
  }

  @override
  String get visitsDeliveryOrProvider => 'Delivery o proveedor';

  @override
  String visitsListSubtitleDeliveryKind(String kind) {
    return 'Delivery o proveedor · $kind';
  }

  @override
  String get visitsListSubtitleFastlane => 'Invitado · FastLane';

  @override
  String get visitsListTitle => 'Visitas';

  @override
  String get visitsListNewVisit => 'Nueva visita';

  @override
  String get visitsTabPending => 'Pendientes';

  @override
  String get visitsTabOngoing => 'En curso';

  @override
  String get visitsTabHistory => 'Historial';

  @override
  String get visitsListShowFrequent => 'Mostrar visitas frecuentes';

  @override
  String get visitsListLoadError => 'No se pudieron cargar tus visitas.';

  @override
  String visitsListHiddenFrequent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accesos frecuentes ocultos',
      one: '1 acceso frecuente oculto',
    );
    return 'Tienes $_temp0.';
  }

  @override
  String get visitsListFrequentHeading => 'Accesos frecuentes';

  @override
  String get visitsListDailyVisit => 'Visita del día';

  @override
  String get visitsBack => 'Volver';

  @override
  String get visitsCatalogTitleService => 'Elige un servicio';

  @override
  String get visitsCatalogTitleCompany => 'Elige una empresa';

  @override
  String get visitsCatalogSearchLabel => 'Buscar';

  @override
  String get visitsCatalogSearchHint => 'Servicio o proveedor';

  @override
  String get visitsCatalogOther => 'Otro';

  @override
  String get visitsCatalogLoadError => 'No pudimos cargar el catálogo.';

  @override
  String get visitsCatalogNoResultsTitle => 'No encontramos resultados';

  @override
  String get visitsCatalogNoResultsBody =>
      'Puedes registrar la visita con un nombre personalizado.';

  @override
  String get visitsCatalogRegisterCustom =>
      'Registrar con nombre personalizado';

  @override
  String get visitsTryAgain => 'Intenta de nuevo.';

  @override
  String get visitsUnit => 'Unidad';

  @override
  String get visitsPlate => 'Placa';

  @override
  String get visitsGateNotes => 'Notas para portería';

  @override
  String get visitsCancelVisit => 'Cancelar visita';

  @override
  String get visitsCancelAccess => 'Cancelar acceso';

  @override
  String get visitsDetailTitle => 'Detalle de visita';

  @override
  String get visitsDetailCancelledToast => 'Visita cancelada';

  @override
  String get visitsDetailCancelError => 'No pudimos cancelar la visita';

  @override
  String get visitsDetailValidity => 'Vigencia';

  @override
  String visitsDetailValiditySameDay(String day, String from, String until) {
    return '$day, $from a $until';
  }

  @override
  String visitsDetailValidityRange(String from, String until) {
    return '$from a $until';
  }

  @override
  String get visitsFrequentDefaultName => 'Tu visita';

  @override
  String visitsFrequentCancelBody(String name) {
    return '$name ya no podrá ingresar con este acceso frecuente.';
  }

  @override
  String get visitsFrequentCancelConfirm => 'Sí, cancelar acceso';

  @override
  String get visitsFrequentCancelledToast => 'Acceso cancelado';

  @override
  String get visitsFrequentCancelError => 'No pudimos cancelar el acceso';

  @override
  String get visitsFrequentLoadError => 'No se pudo cargar el acceso.';

  @override
  String get visitsFrequentActiveIntro =>
      'Tu visita puede ingresar en los días y horarios que definiste.';

  @override
  String get visitsFrequentInactiveIntro =>
      'Este acceso ya no está disponible.';

  @override
  String get visitsFrequentEditAccess => 'Editar acceso';

  @override
  String get visitsFrequentVisitCaption => 'Visita';

  @override
  String visitsFrequentVisitCaptionRole(String role) {
    return 'Visita · $role';
  }

  @override
  String get visitsFrequentNoName => 'Sin nombre';

  @override
  String get visitsFrequentActiveStatus => 'Acceso activo';

  @override
  String get visitsFrequentValidUntilCancelled =>
      'Vigente hasta que lo canceles.';

  @override
  String get visitsFrequentDaysAndHours => 'Días y horario';

  @override
  String get visitsFrequentVehicle => 'Vehículo';

  @override
  String get visitsFrequentLastMovement => 'Último movimiento';

  @override
  String visitsArrivalToday(String rest) {
    return 'Hoy, $rest';
  }

  @override
  String visitsArrivalTomorrow(String rest) {
    return 'Mañana, $rest';
  }

  @override
  String visitsDateToday(String date) {
    return 'Hoy, $date';
  }

  @override
  String get visitsPendingLinkCopied => 'Enlace copiado';

  @override
  String get visitsPendingShareTitle => 'Invitación FastLane';

  @override
  String visitsPendingShareTitleResidential(String residential) {
    return 'Invitación a $residential';
  }

  @override
  String get visitsPendingCancel => 'Cancelar invitación';

  @override
  String get visitsPendingCancelBody =>
      'El enlace dejará de funcionar y tu visita ya no podrá registrarse con él.';

  @override
  String get visitsPendingCancelConfirm => 'Sí, cancelar invitación';

  @override
  String get visitsPendingCancelledToast => 'Invitación cancelada';

  @override
  String get visitsPendingCancelError => 'No pudimos cancelar la invitación';

  @override
  String get visitsPendingTitle => 'Invitación creada';

  @override
  String get visitsPendingIntro =>
      'Comparte el enlace para que tu visitante complete sus datos.';

  @override
  String get visitsPendingShare => 'Compartir invitación';

  @override
  String get visitsPendingCopyLink => 'Copiar enlace';

  @override
  String get visitsPendingEdit => 'Editar invitación';

  @override
  String get visitsPendingGoToVisits => 'Ir a mis visitas';

  @override
  String get visitsPendingExpectedArrival => 'Llegada prevista';

  @override
  String get visitsPendingDataStatus => 'Pendiente de datos';

  @override
  String get visitsPendingVisitorWillComplete =>
      'Tu visitante completará sus datos al abrir el enlace.';

  @override
  String get visitsPendingLinkLabel => 'Enlace de invitación';

  @override
  String get visitsFastlaneVisitDate => 'Fecha de visita';

  @override
  String get visitsFastlaneUpdatedToast => 'Invitación actualizada';

  @override
  String get visitsSaveError => 'No pudimos guardar los cambios';

  @override
  String get visitsFastlaneCreateError => 'No pudimos crear la invitación';

  @override
  String get visitsFastlaneTitle => 'Invitar con FastLane';

  @override
  String get visitsUnitUpper => 'UNIDAD';

  @override
  String get visitsFastlaneNameLabel => 'Nombre de referencia *';

  @override
  String get visitsFastlaneNameHint => 'Visita de...';

  @override
  String get visitsFastlaneNameRequired =>
      'Escribe un nombre para identificar la visita.';

  @override
  String get visitsFastlaneDateHelper => 'Fecha prevista para la visita.';

  @override
  String get visitsFastlaneArrivalLabel => 'Hora de llegada prevista *';

  @override
  String get visitsSaveChanges => 'Guardar cambios';

  @override
  String get visitsFastlaneCreate => 'Crear invitación';

  @override
  String get visitsNewTypeTitle => '¿Quién viene?';

  @override
  String get visitsNewTypeAccessFor => 'Acceso para';

  @override
  String get visitsNewTypeGuest => 'Invitado';

  @override
  String get visitsNewTypeGuestSubtitle =>
      'Crea una invitación con registro del visitante';

  @override
  String get visitsNewTypeDeliverySubtitle => 'Autoriza una entrega o servicio';

  @override
  String get visitsNewTypeFrequentSubtitle =>
      'Para personas que vienen regularmente';

  @override
  String get visitsWeekdayInitialMon => 'L';

  @override
  String get visitsWeekdayInitialTue => 'M';

  @override
  String get visitsWeekdayInitialWed => 'M';

  @override
  String get visitsWeekdayInitialThu => 'J';

  @override
  String get visitsWeekdayInitialFri => 'V';

  @override
  String get visitsWeekdayInitialSat => 'S';

  @override
  String get visitsWeekdayInitialSun => 'D';

  @override
  String visitsScheduleBlockTitle(int number) {
    return 'Bloque de horario $number';
  }

  @override
  String get visitsScheduleBlockRemove => 'Eliminar bloque';

  @override
  String get visitsScheduleFrom => 'Desde';

  @override
  String get visitsScheduleTo => 'Hasta';

  @override
  String get visitsFrequentCurrentDocument => 'Documento actual';

  @override
  String get visitsFrequentIdDocument => 'Documento de identidad';

  @override
  String get visitsFrequentTakePhoto => 'Tomar foto';

  @override
  String get visitsFrequentPickGallery => 'Elegir de la galería';

  @override
  String get visitsFrequentPhotoTooBig =>
      'La foto supera los 10 MB. Elige una más ligera.';

  @override
  String get visitsFrequentMissingData => 'Falta un dato';

  @override
  String get visitsFrequentSelectDayEachBlock =>
      'Selecciona al menos un día en cada bloque de horario.';

  @override
  String get visitsFrequentStartBeforeEnd =>
      'La hora de inicio debe ser anterior a la hora final.';

  @override
  String get visitsFrequentUpdatedToast => 'Acceso actualizado';

  @override
  String get visitsFrequentAuthorizedToast => 'Acceso frecuente autorizado';

  @override
  String get visitsFrequentAuthorizeError => 'No pudimos autorizar el acceso';

  @override
  String get visitsFrequentStep1 => '1 de 2 · Datos de la visita';

  @override
  String get visitsFrequentStep2 => '2 de 2 · Permisos de acceso';

  @override
  String get visitsContinue => 'Continuar';

  @override
  String get visitsFrequentAuthorize => 'Autorizar acceso';

  @override
  String get visitsFrequentNameLabel => 'Nombre de la visita *';

  @override
  String get visitsFrequentNameRequired => 'Escribe el nombre de la visita.';

  @override
  String get visitsFrequentTypeLabel => 'Tipo';

  @override
  String get visitsFrequentPhoneInvalid => 'Escribe un teléfono válido.';

  @override
  String get visitsFrequentIdDocumentRequired => 'Documento de identidad *';

  @override
  String get visitsFrequentIdDocumentHint =>
      'Adjunta una foto legible del documento.';

  @override
  String get visitsFrequentIdDocumentMissing =>
      'Adjunta una foto del documento para continuar.';

  @override
  String get visitsFrequentHasVehicle => 'Ingresará en vehículo';

  @override
  String get visitsFrequentHasVehicleHint => 'Activa para ingresar la placa';

  @override
  String get visitsFrequentPlateLabel => 'Placa del vehículo';

  @override
  String get visitsFrequentPlateHint => 'Ingresa la placa';

  @override
  String get visitsFrequentPlateRequired => 'Escribe la placa del vehículo.';

  @override
  String get visitsFrequentFrequencyLabel => 'Frecuencia';

  @override
  String get visitsFrequentGroupDaysHint =>
      'Agrupa los días que comparten el mismo horario.';

  @override
  String get visitsFrequentScheduleLabel => 'Horario';

  @override
  String get visitsFrequentNotifyLabel => 'Avisarme al llegar';

  @override
  String get visitsFrequentNotifyHint => 'Notificaciones de mis visitas';

  @override
  String get visitsFrequentAddBlock => '+ Agregar bloque';

  @override
  String visitsDateTomorrow(String date) {
    return 'Mañana, $date';
  }

  @override
  String get visitsDetailsAuthorizedToast => 'Visita autorizada';

  @override
  String get visitsDetailsAuthorizeError => 'No pudimos autorizar la visita';

  @override
  String get visitsDetailsTitle => 'Detalles de la visita';

  @override
  String get visitsDetailsService => 'Servicio';

  @override
  String get visitsDetailsDateHelper =>
      'Acceso válido durante el día seleccionado.';

  @override
  String get visitsDetailsPickTime => 'Elige una hora';

  @override
  String get visitsDetailsAuthorize => 'Autorizar visita';

  @override
  String get visitsDetailsNotesLabel => 'Notas para portería (opcional)';

  @override
  String get visitsDetailsNotesHint => 'Agrega una indicación';

  @override
  String get visitsDetailsChange => 'Cambiar visita';

  @override
  String get visitsDetailsNameHint => 'Escribe el nombre';

  @override
  String get visitsDetailsUseName => 'Usar este nombre';

  @override
  String get commonErrorNetwork =>
      'Sin conexión. Revisa tu internet e intenta de nuevo.';

  @override
  String get commonErrorSession =>
      'Tu sesión expiró o no tienes permiso. Inicia sesión de nuevo.';

  @override
  String get commonErrorServer =>
      'Algo salió mal de nuestro lado. Intenta de nuevo en un momento.';
}
