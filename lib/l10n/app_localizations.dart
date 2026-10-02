import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @amenitiesBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get amenitiesBack;

  /// No description provided for @amenitiesClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get amenitiesClose;

  /// No description provided for @amenitiesCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get amenitiesCancel;

  /// No description provided for @amenitiesSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get amenitiesSave;

  /// No description provided for @amenitiesContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get amenitiesContinue;

  /// No description provided for @amenitiesChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get amenitiesChange;

  /// No description provided for @amenitiesEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get amenitiesEdit;

  /// No description provided for @amenitiesTryAgain.
  ///
  /// In es, this message translates to:
  /// **'Intenta de nuevo.'**
  String get amenitiesTryAgain;

  /// No description provided for @amenitiesDayMon.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get amenitiesDayMon;

  /// No description provided for @amenitiesDayTue.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get amenitiesDayTue;

  /// No description provided for @amenitiesDayWed.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get amenitiesDayWed;

  /// No description provided for @amenitiesDayThu.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get amenitiesDayThu;

  /// No description provided for @amenitiesDayFri.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get amenitiesDayFri;

  /// No description provided for @amenitiesDaySat.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get amenitiesDaySat;

  /// No description provided for @amenitiesDaySun.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get amenitiesDaySun;

  /// No description provided for @amenitiesPaymentCash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get amenitiesPaymentCash;

  /// No description provided for @amenitiesPaymentCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get amenitiesPaymentCard;

  /// No description provided for @amenitiesPaymentTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get amenitiesPaymentTransfer;

  /// No description provided for @amenitiesPeriodDay.
  ///
  /// In es, this message translates to:
  /// **'día'**
  String get amenitiesPeriodDay;

  /// No description provided for @amenitiesPeriodWeek.
  ///
  /// In es, this message translates to:
  /// **'semana'**
  String get amenitiesPeriodWeek;

  /// No description provided for @amenitiesPeriodMonth.
  ///
  /// In es, this message translates to:
  /// **'mes'**
  String get amenitiesPeriodMonth;

  /// No description provided for @amenitiesBookingLimit.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Máximo 1 reserva por {period}} other{Máximo {count} reservas por {period}}}'**
  String amenitiesBookingLimit(int count, String period);

  /// No description provided for @amenitiesDurationHours.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hora} other{{count} horas}}'**
  String amenitiesDurationHours(int count);

  /// No description provided for @amenitiesDurationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{count} minutos'**
  String amenitiesDurationMinutes(int count);

  /// No description provided for @amenitiesBlackoutWithReason.
  ///
  /// In es, this message translates to:
  /// **'{range} · {reason}'**
  String amenitiesBlackoutWithReason(String range, String reason);

  /// No description provided for @amenitiesBlackoutClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado {range}'**
  String amenitiesBlackoutClosed(String range);

  /// No description provided for @amenitiesBlackoutClosedWithReason.
  ///
  /// In es, this message translates to:
  /// **'Cerrado {range}: {reason}'**
  String amenitiesBlackoutClosedWithReason(String range, String reason);

  /// No description provided for @amenitiesBlackoutRangeWithReason.
  ///
  /// In es, this message translates to:
  /// **'{range}: {reason}'**
  String amenitiesBlackoutRangeWithReason(String range, String reason);

  /// No description provided for @amenitiesNewBooking.
  ///
  /// In es, this message translates to:
  /// **'Nueva reserva'**
  String get amenitiesNewBooking;

  /// No description provided for @amenitiesListLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las amenidades.'**
  String get amenitiesListLoadError;

  /// No description provided for @amenitiesListEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu residencial aún no tiene amenidades configuradas.'**
  String get amenitiesListEmpty;

  /// No description provided for @amenitiesListHeading.
  ///
  /// In es, this message translates to:
  /// **'Amenidades'**
  String get amenitiesListHeading;

  /// No description provided for @amenitiesCapacity.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 persona} other{{count} personas}}'**
  String amenitiesCapacity(int count);

  /// No description provided for @amenitiesBookingRequiredBadge.
  ///
  /// In es, this message translates to:
  /// **'Reserva obligatoria'**
  String get amenitiesBookingRequiredBadge;

  /// No description provided for @amenitiesNoBookingBadge.
  ///
  /// In es, this message translates to:
  /// **'Sin reserva'**
  String get amenitiesNoBookingBadge;

  /// No description provided for @amenitiesDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Amenidad'**
  String get amenitiesDetailTitle;

  /// No description provided for @amenitiesDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la amenidad.'**
  String get amenitiesDetailLoadError;

  /// No description provided for @amenitiesPhotoLabel.
  ///
  /// In es, this message translates to:
  /// **'Fotografía {index} de {total}'**
  String amenitiesPhotoLabel(int index, int total);

  /// No description provided for @amenitiesPhotoHint.
  ///
  /// In es, this message translates to:
  /// **'Toca dos veces para ampliar'**
  String get amenitiesPhotoHint;

  /// No description provided for @amenitiesBookingRequired.
  ///
  /// In es, this message translates to:
  /// **'Reservación necesaria'**
  String get amenitiesBookingRequired;

  /// No description provided for @amenitiesFreeAccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso libre'**
  String get amenitiesFreeAccess;

  /// No description provided for @amenitiesOffersHeading.
  ///
  /// In es, this message translates to:
  /// **'Lo que ofrece este espacio'**
  String get amenitiesOffersHeading;

  /// No description provided for @amenitiesViewAllServices.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los servicios'**
  String get amenitiesViewAllServices;

  /// No description provided for @amenitiesAllServices.
  ///
  /// In es, this message translates to:
  /// **'Todos los servicios'**
  String get amenitiesAllServices;

  /// No description provided for @amenitiesAboutHeading.
  ///
  /// In es, this message translates to:
  /// **'Un espacio para compartir'**
  String get amenitiesAboutHeading;

  /// No description provided for @amenitiesScheduleHeading.
  ///
  /// In es, this message translates to:
  /// **'Horarios de uso'**
  String get amenitiesScheduleHeading;

  /// No description provided for @amenitiesBeforeBookingHeading.
  ///
  /// In es, this message translates to:
  /// **'Antes de reservar'**
  String get amenitiesBeforeBookingHeading;

  /// No description provided for @amenitiesDurationPerBooking.
  ///
  /// In es, this message translates to:
  /// **'Duración por reserva'**
  String get amenitiesDurationPerBooking;

  /// No description provided for @amenitiesLimitPerResident.
  ///
  /// In es, this message translates to:
  /// **'Límite por residente'**
  String get amenitiesLimitPerResident;

  /// No description provided for @amenitiesClosedDates.
  ///
  /// In es, this message translates to:
  /// **'Fechas cerradas'**
  String get amenitiesClosedDates;

  /// No description provided for @amenitiesCostHeading.
  ///
  /// In es, this message translates to:
  /// **'Costo de la reserva'**
  String get amenitiesCostHeading;

  /// No description provided for @amenitiesNoCost.
  ///
  /// In es, this message translates to:
  /// **'Sin costo'**
  String get amenitiesNoCost;

  /// No description provided for @amenitiesPerBookingOf.
  ///
  /// In es, this message translates to:
  /// **'Por reserva de {duration}'**
  String amenitiesPerBookingOf(String duration);

  /// No description provided for @amenitiesAcceptedMethods.
  ///
  /// In es, this message translates to:
  /// **'Métodos aceptados'**
  String get amenitiesAcceptedMethods;

  /// No description provided for @amenitiesTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get amenitiesTerms;

  /// No description provided for @amenitiesPerBooking.
  ///
  /// In es, this message translates to:
  /// **'por reserva'**
  String get amenitiesPerBooking;

  /// No description provided for @amenitiesPerBookingDuration.
  ///
  /// In es, this message translates to:
  /// **'por reserva · {duration}'**
  String amenitiesPerBookingDuration(String duration);

  /// No description provided for @amenitiesPickDate.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get amenitiesPickDate;

  /// No description provided for @amenitiesCostInfoNote.
  ///
  /// In es, this message translates to:
  /// **'El costo y los métodos son informativos; esta app no procesa pagos.'**
  String get amenitiesCostInfoNote;

  /// No description provided for @amenitiesNotesOptional.
  ///
  /// In es, this message translates to:
  /// **'Notas (opcional)'**
  String get amenitiesNotesOptional;

  /// No description provided for @amenitiesNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega una nota para tu reserva'**
  String get amenitiesNotesHint;

  /// No description provided for @amenitiesDateTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Fecha y horario'**
  String get amenitiesDateTimeTitle;

  /// No description provided for @amenitiesEndAfterStartError.
  ///
  /// In es, this message translates to:
  /// **'La hora de fin debe ser después de la hora de inicio.'**
  String get amenitiesEndAfterStartError;

  /// No description provided for @amenitiesStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get amenitiesStart;

  /// No description provided for @amenitiesEnd.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get amenitiesEnd;

  /// No description provided for @amenitiesEndsAt.
  ///
  /// In es, this message translates to:
  /// **'Termina a las'**
  String get amenitiesEndsAt;

  /// No description provided for @amenitiesEachBookingLasts.
  ///
  /// In es, this message translates to:
  /// **'Cada reserva dura {duration}.'**
  String amenitiesEachBookingLasts(String duration);

  /// No description provided for @amenitiesReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar reserva'**
  String get amenitiesReviewTitle;

  /// No description provided for @amenitiesErrorPastDateTitle.
  ///
  /// In es, this message translates to:
  /// **'Fecha en el pasado'**
  String get amenitiesErrorPastDateTitle;

  /// No description provided for @amenitiesErrorPastDateMessage.
  ///
  /// In es, this message translates to:
  /// **'La fecha seleccionada ya pasó. Elige una fecha actual o futura.'**
  String get amenitiesErrorPastDateMessage;

  /// No description provided for @amenitiesErrorScheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Error de horario'**
  String get amenitiesErrorScheduleTitle;

  /// No description provided for @amenitiesErrorConflictTitle.
  ///
  /// In es, this message translates to:
  /// **'Horario no disponible'**
  String get amenitiesErrorConflictTitle;

  /// No description provided for @amenitiesErrorConflictMessage.
  ///
  /// In es, this message translates to:
  /// **'Otra reserva ocupa este horario. Tus notas se conservaron.'**
  String get amenitiesErrorConflictMessage;

  /// No description provided for @amenitiesErrorBlackoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Fecha cerrada'**
  String get amenitiesErrorBlackoutTitle;

  /// No description provided for @amenitiesErrorBlackoutMessage.
  ///
  /// In es, this message translates to:
  /// **'La amenidad estará cerrada el día elegido. Selecciona otra fecha.'**
  String get amenitiesErrorBlackoutMessage;

  /// No description provided for @amenitiesErrorSubmitTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la reserva'**
  String get amenitiesErrorSubmitTitle;

  /// No description provided for @amenitiesErrorSubmitMessage.
  ///
  /// In es, this message translates to:
  /// **'Intenta de nuevo en unos segundos.'**
  String get amenitiesErrorSubmitMessage;

  /// No description provided for @amenitiesDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get amenitiesDate;

  /// No description provided for @amenitiesSchedule.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get amenitiesSchedule;

  /// No description provided for @amenitiesNoNotes.
  ///
  /// In es, this message translates to:
  /// **'Sin notas'**
  String get amenitiesNoNotes;

  /// No description provided for @amenitiesCancelFutureHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes cancelar una reserva futura desde Mis reservas.'**
  String get amenitiesCancelFutureHint;

  /// No description provided for @amenitiesConfirmBooking.
  ///
  /// In es, this message translates to:
  /// **'Confirmar reserva'**
  String get amenitiesConfirmBooking;

  /// No description provided for @amenitiesResultConfirmedHeading.
  ///
  /// In es, this message translates to:
  /// **'Todo listo para tu reserva'**
  String get amenitiesResultConfirmedHeading;

  /// No description provided for @amenitiesPendingConfirmation.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de confirmación'**
  String get amenitiesPendingConfirmation;

  /// No description provided for @amenitiesResultConfirmedSubtext.
  ///
  /// In es, this message translates to:
  /// **'Consulta los datos y el estado desde Mis reservas.'**
  String get amenitiesResultConfirmedSubtext;

  /// No description provided for @amenitiesResultPendingSubtext.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud fue enviada. Aún no está confirmada; consulta su estado en Mis reservas.'**
  String get amenitiesResultPendingSubtext;

  /// No description provided for @amenitiesResultConfirmedTitle.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada'**
  String get amenitiesResultConfirmedTitle;

  /// No description provided for @amenitiesResultPendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get amenitiesResultPendingTitle;

  /// No description provided for @amenitiesNotesValue.
  ///
  /// In es, this message translates to:
  /// **'Notas: {notes}'**
  String amenitiesNotesValue(String notes);

  /// No description provided for @amenitiesViewMyBookings.
  ///
  /// In es, this message translates to:
  /// **'Ver mis reservas'**
  String get amenitiesViewMyBookings;

  /// No description provided for @amenitiesStatusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get amenitiesStatusConfirmed;

  /// No description provided for @amenitiesStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get amenitiesStatusPending;

  /// No description provided for @amenitiesStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get amenitiesStatusCancelled;

  /// No description provided for @amenitiesStatusExpired.
  ///
  /// In es, this message translates to:
  /// **'Expirada'**
  String get amenitiesStatusExpired;

  /// No description provided for @amenitiesBannerConfirmedMessage.
  ///
  /// In es, this message translates to:
  /// **'La reserva se registró correctamente.'**
  String get amenitiesBannerConfirmedMessage;

  /// No description provided for @amenitiesBannerPendingMessage.
  ///
  /// In es, this message translates to:
  /// **'La solicitud espera confirmación.'**
  String get amenitiesBannerPendingMessage;

  /// No description provided for @amenitiesBookingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get amenitiesBookingsTitle;

  /// No description provided for @amenitiesTabPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get amenitiesTabPending;

  /// No description provided for @amenitiesTabConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmadas'**
  String get amenitiesTabConfirmed;

  /// No description provided for @amenitiesTabHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get amenitiesTabHistory;

  /// No description provided for @amenitiesBookingsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus reservas.'**
  String get amenitiesBookingsLoadError;

  /// No description provided for @amenitiesEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No tienes reservas pendientes.'**
  String get amenitiesEmptyPending;

  /// No description provided for @amenitiesEmptyConfirmed.
  ///
  /// In es, this message translates to:
  /// **'No tienes reservas confirmadas.'**
  String get amenitiesEmptyConfirmed;

  /// No description provided for @amenitiesEmptyHistory.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes historial de reservas.'**
  String get amenitiesEmptyHistory;

  /// No description provided for @amenitiesPillConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada'**
  String get amenitiesPillConfirmed;

  /// No description provided for @amenitiesPillPast.
  ///
  /// In es, this message translates to:
  /// **'Reserva pasada'**
  String get amenitiesPillPast;

  /// No description provided for @amenitiesPillCancelled.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada'**
  String get amenitiesPillCancelled;

  /// No description provided for @amenitiesPillExpired.
  ///
  /// In es, this message translates to:
  /// **'Reserva expirada'**
  String get amenitiesPillExpired;

  /// No description provided for @amenitiesBookingDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de reserva'**
  String get amenitiesBookingDetailTitle;

  /// No description provided for @amenitiesSpace.
  ///
  /// In es, this message translates to:
  /// **'Espacio'**
  String get amenitiesSpace;

  /// No description provided for @amenitiesReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get amenitiesReason;

  /// No description provided for @amenitiesReasonOptional.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get amenitiesReasonOptional;

  /// No description provided for @amenitiesReasonHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos por qué cancelas, si quieres'**
  String get amenitiesReasonHint;

  /// No description provided for @amenitiesSwipeToCancel.
  ///
  /// In es, this message translates to:
  /// **'Desliza para cancelar'**
  String get amenitiesSwipeToCancel;

  /// No description provided for @amenitiesCancelFailedTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cancelar la reserva'**
  String get amenitiesCancelFailedTitle;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonLoadMoreError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar más elementos.'**
  String get commonLoadMoreError;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get commonDone;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get commonProfile;

  /// No description provided for @commonLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get commonLogout;

  /// No description provided for @commonForResidents.
  ///
  /// In es, this message translates to:
  /// **'PARA RESIDENTES'**
  String get commonForResidents;

  /// No description provided for @commonToastSuccess.
  ///
  /// In es, this message translates to:
  /// **'Éxito'**
  String get commonToastSuccess;

  /// No description provided for @commonToastInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get commonToastInfo;

  /// No description provided for @commonToastWarning.
  ///
  /// In es, this message translates to:
  /// **'Advertencia'**
  String get commonToastWarning;

  /// No description provided for @commonToastError.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get commonToastError;

  /// No description provided for @commonMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get commonMonth;

  /// No description provided for @commonDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get commonDate;

  /// No description provided for @commonCountry.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get commonCountry;

  /// No description provided for @commonPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get commonPhone;

  /// No description provided for @commonCountryCode.
  ///
  /// In es, this message translates to:
  /// **'Código de país {dialCode}'**
  String commonCountryCode(String dialCode);

  /// No description provided for @commonCharactersCount.
  ///
  /// In es, this message translates to:
  /// **'{length} caracteres'**
  String commonCharactersCount(int length);

  /// No description provided for @commonTapTwiceToConfirm.
  ///
  /// In es, this message translates to:
  /// **'Toca dos veces para confirmar'**
  String get commonTapTwiceToConfirm;

  /// No description provided for @commonDoormanNotesLabel.
  ///
  /// In es, this message translates to:
  /// **'Notas para portería (opcional)'**
  String get commonDoormanNotesLabel;

  /// No description provided for @commonDoormanNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega una indicación'**
  String get commonDoormanNotesHint;

  /// No description provided for @commonUploadFormats.
  ///
  /// In es, this message translates to:
  /// **'JPG o PNG · hasta 10 MB'**
  String get commonUploadFormats;

  /// No description provided for @commonUploadReady.
  ///
  /// In es, this message translates to:
  /// **'Foto lista'**
  String get commonUploadReady;

  /// No description provided for @commonUploadUploading.
  ///
  /// In es, this message translates to:
  /// **'Subiendo foto…'**
  String get commonUploadUploading;

  /// No description provided for @commonUploadPreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando…'**
  String get commonUploadPreparing;

  /// No description provided for @commonUploadErrorDefault.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get commonUploadErrorDefault;

  /// No description provided for @commonUploadDocument.
  ///
  /// In es, this message translates to:
  /// **'Subir documento'**
  String get commonUploadDocument;

  /// No description provided for @commonRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get commonRemove;

  /// No description provided for @commonChooseFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get commonChooseFile;

  /// No description provided for @commonCountryHonduras.
  ///
  /// In es, this message translates to:
  /// **'Honduras'**
  String get commonCountryHonduras;

  /// No description provided for @commonCountryGuatemala.
  ///
  /// In es, this message translates to:
  /// **'Guatemala'**
  String get commonCountryGuatemala;

  /// No description provided for @commonCountryElSalvador.
  ///
  /// In es, this message translates to:
  /// **'El Salvador'**
  String get commonCountryElSalvador;

  /// No description provided for @commonCountryNicaragua.
  ///
  /// In es, this message translates to:
  /// **'Nicaragua'**
  String get commonCountryNicaragua;

  /// No description provided for @commonCountryCostaRica.
  ///
  /// In es, this message translates to:
  /// **'Costa Rica'**
  String get commonCountryCostaRica;

  /// No description provided for @commonCountryPanama.
  ///
  /// In es, this message translates to:
  /// **'Panamá'**
  String get commonCountryPanama;

  /// No description provided for @commonCountryMexico.
  ///
  /// In es, this message translates to:
  /// **'México'**
  String get commonCountryMexico;

  /// No description provided for @commonCountryUnitedStates.
  ///
  /// In es, this message translates to:
  /// **'Estados Unidos'**
  String get commonCountryUnitedStates;

  /// No description provided for @authBiometricTitle.
  ///
  /// In es, this message translates to:
  /// **'Entra más rápido'**
  String get authBiometricTitle;

  /// No description provided for @authBiometricBody.
  ///
  /// In es, this message translates to:
  /// **'Usa tu rostro o huella para entrar.\nPuedes configurarlo más adelante.'**
  String get authBiometricBody;

  /// No description provided for @authBiometricSetup.
  ///
  /// In es, this message translates to:
  /// **'Configurar biometría'**
  String get authBiometricSetup;

  /// No description provided for @authBiometricSkip.
  ///
  /// In es, this message translates to:
  /// **'Omitir por ahora'**
  String get authBiometricSkip;

  /// No description provided for @authInvitationPending.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una invitación pendiente. Usa tu código de invitación para activar tu cuenta.'**
  String get authInvitationPending;

  /// No description provided for @authEmailUnknown.
  ///
  /// In es, this message translates to:
  /// **'No reconocemos ese correo. Por favor comunícate con el administrador de tu residencial.'**
  String get authEmailUnknown;

  /// No description provided for @authSendCodeFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el código. Intenta de nuevo.'**
  String get authSendCodeFailed;

  /// No description provided for @authLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu hogar,\nen un solo lugar.'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pagos, avisos y visitas.\nTodo cerca, todo en vecinoo.'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In es, this message translates to:
  /// **'nombre@correo.com'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo inválido'**
  String get authEmailInvalid;

  /// No description provided for @authHaveInvitationCode.
  ///
  /// In es, this message translates to:
  /// **'¿Tienes un código de invitación? Ingrésalo aquí.'**
  String get authHaveInvitationCode;

  /// No description provided for @authOtpIntroEmail.
  ///
  /// In es, this message translates to:
  /// **'Para iniciar sesión, ingresa el nuevo código de 6 dígitos que enviamos a'**
  String get authOtpIntroEmail;

  /// No description provided for @authOtpIntroSms.
  ///
  /// In es, this message translates to:
  /// **'Para iniciar sesión, ingresa el nuevo código de 6 dígitos que enviamos por SMS a'**
  String get authOtpIntroSms;

  /// No description provided for @authEnterDigits.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los {length} dígitos'**
  String authEnterDigits(int length);

  /// No description provided for @authOtpWrongOrExpired.
  ///
  /// In es, this message translates to:
  /// **'Código incorrecto o expirado.'**
  String get authOtpWrongOrExpired;

  /// No description provided for @authOtpResentTitle.
  ///
  /// In es, this message translates to:
  /// **'Código reenviado'**
  String get authOtpResentTitle;

  /// No description provided for @authOtpResentMessage.
  ///
  /// In es, this message translates to:
  /// **'Puedes pedir otro en 60 segundos.'**
  String get authOtpResentMessage;

  /// No description provided for @authOtpResendFailedTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos reenviar el código'**
  String get authOtpResendFailedTitle;

  /// No description provided for @authOtpResendFailedMessage.
  ///
  /// In es, this message translates to:
  /// **'Intenta de nuevo en un minuto.'**
  String get authOtpResendFailedMessage;

  /// No description provided for @authInvitationValidated.
  ///
  /// In es, this message translates to:
  /// **'Invitación validada'**
  String get authInvitationValidated;

  /// No description provided for @authCheckEmail.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo'**
  String get authCheckEmail;

  /// No description provided for @authCheckPhone.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu teléfono'**
  String get authCheckPhone;

  /// No description provided for @authVerificationCode.
  ///
  /// In es, this message translates to:
  /// **'Código de verificación'**
  String get authVerificationCode;

  /// No description provided for @authVerifyAndSignIn.
  ///
  /// In es, this message translates to:
  /// **'Verificar e iniciar sesión'**
  String get authVerifyAndSignIn;

  /// No description provided for @authSending.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get authSending;

  /// No description provided for @authResendIn.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código en {seconds}s'**
  String authResendIn(int seconds);

  /// No description provided for @authResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get authResend;

  /// No description provided for @authCommunityAccess.
  ///
  /// In es, this message translates to:
  /// **'Tu acceso a la comunidad'**
  String get authCommunityAccess;

  /// No description provided for @authResidentName.
  ///
  /// In es, this message translates to:
  /// **'{name} · Residente'**
  String authResidentName(String name);

  /// No description provided for @authInvitationInvalid.
  ///
  /// In es, this message translates to:
  /// **'Código inválido, ya usado o expirado.'**
  String get authInvitationInvalid;

  /// No description provided for @authSupportTitle.
  ///
  /// In es, this message translates to:
  /// **'Contacta a soporte'**
  String get authSupportTitle;

  /// No description provided for @authSupportMessage.
  ///
  /// In es, this message translates to:
  /// **'Escríbenos a soporte@vecinoo.app'**
  String get authSupportMessage;

  /// No description provided for @authValidateCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Valida tu código'**
  String get authValidateCodeTitle;

  /// No description provided for @authValidateCodeBody.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código de {length} dígitos que recibiste en tu invitación.'**
  String authValidateCodeBody(int length);

  /// No description provided for @authInvitationCode.
  ///
  /// In es, this message translates to:
  /// **'Código de invitación'**
  String get authInvitationCode;

  /// No description provided for @authInvitationHelper.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu tarjeta o correo de bienvenida.'**
  String get authInvitationHelper;

  /// No description provided for @authAcceptInvitation.
  ///
  /// In es, this message translates to:
  /// **'Aceptar invitación'**
  String get authAcceptInvitation;

  /// No description provided for @authNoInvitationContactSupport.
  ///
  /// In es, this message translates to:
  /// **'¿No recibiste tu invitación? Contactar soporte'**
  String get authNoInvitationContactSupport;

  /// No description provided for @sessionPendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuenta pendiente'**
  String get sessionPendingTitle;

  /// No description provided for @sessionPendingBody.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes una unidad vinculada. Pide al administrador que te vincule o ingresa un código de invitación.'**
  String get sessionPendingBody;

  /// No description provided for @sessionCodeDigitsHelper.
  ///
  /// In es, this message translates to:
  /// **'6 dígitos.'**
  String get sessionCodeDigitsHelper;

  /// No description provided for @sessionUseCode.
  ///
  /// In es, this message translates to:
  /// **'Usar código'**
  String get sessionUseCode;

  /// No description provided for @sessionAlreadyLinkedRetry.
  ///
  /// In es, this message translates to:
  /// **'Ya me vincularon, reintentar'**
  String get sessionAlreadyLinkedRetry;

  /// No description provided for @sessionSelectUnitTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu unidad'**
  String get sessionSelectUnitTitle;

  /// No description provided for @sessionSelectUnitBody.
  ///
  /// In es, this message translates to:
  /// **'Elige la unidad que quieres consultar.'**
  String get sessionSelectUnitBody;

  /// No description provided for @profileLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu perfil.'**
  String get profileLoadFailed;

  /// No description provided for @profileChangeUnit.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de unidad activa'**
  String get profileChangeUnit;

  /// No description provided for @profileAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get profileAppearance;

  /// No description provided for @profileThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get profileThemeDark;

  /// No description provided for @profileThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get profileThemeSystem;

  /// No description provided for @profileEditName.
  ///
  /// In es, this message translates to:
  /// **'Editar nombre'**
  String get profileEditName;

  /// No description provided for @profileFirstName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profileFirstName;

  /// No description provided for @profileLastName.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get profileLastName;

  /// No description provided for @profileFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get profileFieldRequired;

  /// No description provided for @profileSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar tu perfil.'**
  String get profileSaveFailed;

  /// No description provided for @profileChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get profileChangePhoto;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In es, this message translates to:
  /// **'Foto actualizada'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir tu foto.'**
  String get profilePhotoFailed;

  /// No description provided for @profileSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionResidence.
  ///
  /// In es, this message translates to:
  /// **'Mi residencia'**
  String get profileSectionResidence;

  /// No description provided for @profileSectionSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get profileSectionSecurity;

  /// No description provided for @profileUnitManagedNote.
  ///
  /// In es, this message translates to:
  /// **'Tu unidad la gestiona la administración. Si algo no es correcto, contáctala.'**
  String get profileUnitManagedNote;

  /// No description provided for @profileChangeEmail.
  ///
  /// In es, this message translates to:
  /// **'Cambiar correo'**
  String get profileChangeEmail;

  /// No description provided for @profileEmailChangeBody.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un código al nuevo correo. Tu correo solo cambia cuando lo confirmes.'**
  String get profileEmailChangeBody;

  /// No description provided for @profileNewEmail.
  ///
  /// In es, this message translates to:
  /// **'Nuevo correo'**
  String get profileNewEmail;

  /// No description provided for @profileEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un correo válido'**
  String get profileEmailInvalid;

  /// No description provided for @profileEmailSame.
  ///
  /// In es, this message translates to:
  /// **'Ese ya es tu correo actual'**
  String get profileEmailSame;

  /// No description provided for @profileEmailSendCode.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get profileEmailSendCode;

  /// No description provided for @profileEmailCodeSentTo.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un código de 6 dígitos a {email}.'**
  String profileEmailCodeSentTo(String email);

  /// No description provided for @profileEmailCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código de 6 dígitos'**
  String get profileEmailCodeLabel;

  /// No description provided for @profileEmailConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar correo'**
  String get profileEmailConfirm;

  /// No description provided for @profileEmailInvalidCode.
  ///
  /// In es, this message translates to:
  /// **'El código es incorrecto o ya venció.'**
  String get profileEmailInvalidCode;

  /// No description provided for @profileEmailResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get profileEmailResend;

  /// No description provided for @profileEmailResendIn.
  ///
  /// In es, this message translates to:
  /// **'Reenviar en {seconds} s'**
  String profileEmailResendIn(String seconds);

  /// No description provided for @profileEmailUseOther.
  ///
  /// In es, this message translates to:
  /// **'Usar otro correo'**
  String get profileEmailUseOther;

  /// No description provided for @profileEmailRateLimited.
  ///
  /// In es, this message translates to:
  /// **'Espera un momento antes de pedir otro código.'**
  String get profileEmailRateLimited;

  /// No description provided for @profileEmailChanged.
  ///
  /// In es, this message translates to:
  /// **'Correo actualizado'**
  String get profileEmailChanged;

  /// No description provided for @profileEmailChangeFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar tu correo.'**
  String get profileEmailChangeFailed;

  /// No description provided for @profileBiometricTitle.
  ///
  /// In es, this message translates to:
  /// **'Desbloqueo biométrico'**
  String get profileBiometricTitle;

  /// No description provided for @profileBiometricDescription.
  ///
  /// In es, this message translates to:
  /// **'Usa tu rostro o huella para abrir la app.'**
  String get profileBiometricDescription;

  /// No description provided for @profileBiometricReason.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu identidad para activar el desbloqueo biométrico'**
  String get profileBiometricReason;

  /// No description provided for @profileBiometricUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo no tiene biometría configurada.'**
  String get profileBiometricUnavailable;

  /// No description provided for @profileBiometricCancelled.
  ///
  /// In es, this message translates to:
  /// **'No se activó el desbloqueo biométrico.'**
  String get profileBiometricCancelled;

  /// No description provided for @profileVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get profileVersion;

  /// No description provided for @profileVersionValue.
  ///
  /// In es, this message translates to:
  /// **'V {version}'**
  String profileVersionValue(String version);

  /// No description provided for @profileDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Enviaremos la solicitud y, pasado un mes calendario, tu cuenta y todos tus datos se borrarán de forma permanente. Mientras tanto puedes cancelarla cuando quieras.'**
  String get profileDeleteBody;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Solicitar eliminación'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeleteRequested.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get profileDeleteRequested;

  /// No description provided for @profileDeleteRequestedBody.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta se eliminará el {date}.'**
  String profileDeleteRequestedBody(String date);

  /// No description provided for @profileDeleteFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la solicitud.'**
  String get profileDeleteFailed;

  /// No description provided for @profileDeletePendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminación programada'**
  String get profileDeletePendingTitle;

  /// No description provided for @profileDeletePendingBody.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta y tus datos se borrarán el {date}.'**
  String profileDeletePendingBody(String date);

  /// No description provided for @profileDeleteCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get profileDeleteCancel;

  /// No description provided for @profileDeleteCancelled.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada'**
  String get profileDeleteCancelled;

  /// No description provided for @profileDeleteCancelFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar la solicitud.'**
  String get profileDeleteCancelFailed;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @appStatusMaintenanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Estamos en mantenimiento'**
  String get appStatusMaintenanceTitle;

  /// No description provided for @appStatusMaintenanceBody.
  ///
  /// In es, this message translates to:
  /// **'Volveremos muy pronto. Gracias por tu paciencia.'**
  String get appStatusMaintenanceBody;

  /// No description provided for @appStatusUpdateTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay una nueva versión'**
  String get appStatusUpdateTitle;

  /// No description provided for @appStatusUpdateBody.
  ///
  /// In es, this message translates to:
  /// **'Ya está disponible la versión {version} de Vecinoo con mejoras y correcciones.'**
  String appStatusUpdateBody(String version);

  /// No description provided for @appStatusUpdateForcedTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualiza para continuar'**
  String get appStatusUpdateForcedTitle;

  /// No description provided for @appStatusUpdateForcedBody.
  ///
  /// In es, this message translates to:
  /// **'Para seguir usando Vecinoo necesitas instalar la versión {version}.'**
  String appStatusUpdateForcedBody(String version);

  /// No description provided for @appStatusUpdateAction.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get appStatusUpdateAction;

  /// No description provided for @appStatusUpdateContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get appStatusUpdateContinue;

  /// No description provided for @appStatusUpdateOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir la tienda. Búscanos en la tienda de aplicaciones.'**
  String get appStatusUpdateOpenFailed;

  /// No description provided for @appStatusOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión a internet'**
  String get appStatusOfflineTitle;

  /// No description provided for @appStatusOfflineBody.
  ///
  /// In es, this message translates to:
  /// **'No pudimos conectarnos. Verifica tu Wi-Fi o datos móviles e inténtalo de nuevo.'**
  String get appStatusOfflineBody;

  /// No description provided for @lockTitle.
  ///
  /// In es, this message translates to:
  /// **'Vecinoo está bloqueado'**
  String get lockTitle;

  /// No description provided for @lockBody.
  ///
  /// In es, this message translates to:
  /// **'Desbloquea con tu rostro o huella para continuar.'**
  String get lockBody;

  /// No description provided for @lockUnlock.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get lockUnlock;

  /// No description provided for @lockReason.
  ///
  /// In es, this message translates to:
  /// **'Desbloquea para entrar a la app'**
  String get lockReason;

  /// No description provided for @homeNavHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get homeNavHome;

  /// No description provided for @homeIncidents.
  ///
  /// In es, this message translates to:
  /// **'Incidencias'**
  String get homeIncidents;

  /// No description provided for @homeReservations.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get homeReservations;

  /// No description provided for @homeVisits.
  ///
  /// In es, this message translates to:
  /// **'Visitas'**
  String get homeVisits;

  /// No description provided for @homeComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get homeComingSoon;

  /// No description provided for @homeGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola'**
  String get homeGreeting;

  /// No description provided for @homeGreetingNamed.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String homeGreetingNamed(String name);

  /// No description provided for @homeTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu comunidad, más cerca.'**
  String get homeTagline;

  /// No description provided for @homeNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get homeNotifications;

  /// No description provided for @homeToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get homeToday;

  /// No description provided for @homeTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get homeTomorrow;

  /// No description provided for @homePm.
  ///
  /// In es, this message translates to:
  /// **'p. m.'**
  String get homePm;

  /// No description provided for @homeAm.
  ///
  /// In es, this message translates to:
  /// **'a. m.'**
  String get homeAm;

  /// No description provided for @homeBookingsLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus reservas.'**
  String get homeBookingsLoadFailed;

  /// No description provided for @homeNoBookingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Un espacio para disfrutar'**
  String get homeNoBookingsTitle;

  /// No description provided for @homeNoBookingsDetail.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes reservas próximas.'**
  String get homeNoBookingsDetail;

  /// No description provided for @homeExploreAmenities.
  ///
  /// In es, this message translates to:
  /// **'Explorar amenidades'**
  String get homeExploreAmenities;

  /// No description provided for @homeVisitsSummary.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin visitas\nprevistas} =1{1 visita\npara hoy} other{{count} visitas\npara hoy}}'**
  String homeVisitsSummary(int count);

  /// No description provided for @homeIncidentsSummary.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin incidencias\nreportadas} =1{1 reporte\nen seguimiento} other{{count} reportes\nen seguimiento}}'**
  String homeIncidentsSummary(int count);

  /// No description provided for @homeInvite.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get homeInvite;

  /// No description provided for @homeViewVisits.
  ///
  /// In es, this message translates to:
  /// **'Ver visitas'**
  String get homeViewVisits;

  /// No description provided for @homeReport.
  ///
  /// In es, this message translates to:
  /// **'Reportar'**
  String get homeReport;

  /// No description provided for @homeViewReport.
  ///
  /// In es, this message translates to:
  /// **'Ver reporte'**
  String get homeViewReport;

  /// No description provided for @homeBulletins.
  ///
  /// In es, this message translates to:
  /// **'Boletines'**
  String get homeBulletins;

  /// No description provided for @homeBulletinsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay\nboletines'**
  String get homeBulletinsEmpty;

  /// No description provided for @homeBulletinsSummary.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin boletines\nnuevos} =1{1 boletín\nnuevo} other{{count} boletines\nnuevos}}'**
  String homeBulletinsSummary(int count);

  /// No description provided for @homeViewBulletins.
  ///
  /// In es, this message translates to:
  /// **'Ver boletines'**
  String get homeViewBulletins;

  /// No description provided for @homeViewBulletin.
  ///
  /// In es, this message translates to:
  /// **'Ver boletín'**
  String get homeViewBulletin;

  /// No description provided for @homeViewBulletinsHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial'**
  String get homeViewBulletinsHistory;

  /// No description provided for @bulletinsTitle.
  ///
  /// In es, this message translates to:
  /// **'Boletines'**
  String get bulletinsTitle;

  /// No description provided for @bulletinsDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Boletín'**
  String get bulletinsDetailTitle;

  /// No description provided for @bulletinsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay boletines publicados.'**
  String get bulletinsEmpty;

  /// No description provided for @bulletinsListLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los boletines.'**
  String get bulletinsListLoadError;

  /// No description provided for @bulletinsDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el boletín. Puede que ya no esté disponible.'**
  String get bulletinsDetailLoadError;

  /// No description provided for @bulletinsPublishedOn.
  ///
  /// In es, this message translates to:
  /// **'Publicado el {date}'**
  String bulletinsPublishedOn(String date);

  /// No description provided for @bulletinsImageCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 imagen} other{{count} imágenes}}'**
  String bulletinsImageCount(int count);

  /// No description provided for @bulletinsPdfCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 PDF} other{{count} PDF}}'**
  String bulletinsPdfCount(int count);

  /// No description provided for @bulletinsDocumentsSection.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get bulletinsDocumentsSection;

  /// No description provided for @bulletinsAttachedImage.
  ///
  /// In es, this message translates to:
  /// **'Imagen adjunta'**
  String get bulletinsAttachedImage;

  /// No description provided for @bulletinsAttachedImageHint.
  ///
  /// In es, this message translates to:
  /// **'Toca dos veces para ampliar'**
  String get bulletinsAttachedImageHint;

  /// No description provided for @bulletinsOpenPdfHint.
  ///
  /// In es, this message translates to:
  /// **'Toca dos veces para abrir el documento'**
  String get bulletinsOpenPdfHint;

  /// No description provided for @bulletinsOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el documento'**
  String get bulletinsOpenFailed;

  /// No description provided for @bulletinsTabNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevos'**
  String get bulletinsTabNew;

  /// No description provided for @bulletinsTabHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get bulletinsTabHistory;

  /// No description provided for @bulletinsEmptyNew.
  ///
  /// In es, this message translates to:
  /// **'No tienes boletines nuevos.'**
  String get bulletinsEmptyNew;

  /// No description provided for @bulletinsEmptyHistory.
  ///
  /// In es, this message translates to:
  /// **'Los boletines que leas aparecerán aquí.'**
  String get bulletinsEmptyHistory;

  /// No description provided for @incidentsStatusNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva'**
  String get incidentsStatusNew;

  /// No description provided for @incidentsStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get incidentsStatusInProgress;

  /// No description provided for @incidentsStatusResolved.
  ///
  /// In es, this message translates to:
  /// **'Resuelta'**
  String get incidentsStatusResolved;

  /// No description provided for @incidentsStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get incidentsStatusClosed;

  /// No description provided for @incidentsStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get incidentsStatusCancelled;

  /// No description provided for @incidentsPriorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get incidentsPriorityLow;

  /// No description provided for @incidentsPriorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get incidentsPriorityMedium;

  /// No description provided for @incidentsPriorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get incidentsPriorityHigh;

  /// No description provided for @incidentsPriorityUrgent.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get incidentsPriorityUrgent;

  /// No description provided for @incidentsEditorDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get incidentsEditorDescriptionLabel;

  /// No description provided for @incidentsEditorBold.
  ///
  /// In es, this message translates to:
  /// **'Negrita'**
  String get incidentsEditorBold;

  /// No description provided for @incidentsEditorItalic.
  ///
  /// In es, this message translates to:
  /// **'Cursiva'**
  String get incidentsEditorItalic;

  /// No description provided for @incidentsEditorList.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get incidentsEditorList;

  /// No description provided for @incidentsEditorLink.
  ///
  /// In es, this message translates to:
  /// **'Enlace'**
  String get incidentsEditorLink;

  /// No description provided for @incidentsEditorDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Describe qué ocurrió y dónde…'**
  String get incidentsEditorDescriptionHint;

  /// No description provided for @incidentsEditorLinkInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un enlace válido.'**
  String get incidentsEditorLinkInvalid;

  /// No description provided for @incidentsEditorAddLink.
  ///
  /// In es, this message translates to:
  /// **'Agregar enlace'**
  String get incidentsEditorAddLink;

  /// No description provided for @incidentsEditorLinkNoSelection.
  ///
  /// In es, this message translates to:
  /// **'Sin texto seleccionado, se insertará el enlace tal cual.'**
  String get incidentsEditorLinkNoSelection;

  /// No description provided for @incidentsEditorLinkHint.
  ///
  /// In es, this message translates to:
  /// **'https://…'**
  String get incidentsEditorLinkHint;

  /// No description provided for @incidentsListEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No tienes incidencias pendientes.'**
  String get incidentsListEmptyPending;

  /// No description provided for @incidentsListEmptyInProgress.
  ///
  /// In es, this message translates to:
  /// **'No tienes incidencias en curso.'**
  String get incidentsListEmptyInProgress;

  /// No description provided for @incidentsListEmptyHistory.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes historial de incidencias.'**
  String get incidentsListEmptyHistory;

  /// No description provided for @incidentsListTitle.
  ///
  /// In es, this message translates to:
  /// **'Incidencias'**
  String get incidentsListTitle;

  /// No description provided for @incidentsTabPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get incidentsTabPending;

  /// No description provided for @incidentsTabInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get incidentsTabInProgress;

  /// No description provided for @incidentsTabHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get incidentsTabHistory;

  /// No description provided for @incidentsListLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las incidencias.'**
  String get incidentsListLoadError;

  /// No description provided for @incidentsDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la incidencia.'**
  String get incidentsDetailLoadError;

  /// No description provided for @incidentsEditAction.
  ///
  /// In es, this message translates to:
  /// **'Editar incidencia'**
  String get incidentsEditAction;

  /// No description provided for @incidentsCancelAction.
  ///
  /// In es, this message translates to:
  /// **'Cancelar incidencia'**
  String get incidentsCancelAction;

  /// No description provided for @incidentsCancelSheetBody.
  ///
  /// In es, this message translates to:
  /// **'Ya no se le dará seguimiento. La incidencia seguirá en tu historial como cancelada.'**
  String get incidentsCancelSheetBody;

  /// No description provided for @incidentsCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar incidencia'**
  String get incidentsCancelConfirm;

  /// No description provided for @incidentsCancelledToast.
  ///
  /// In es, this message translates to:
  /// **'Incidencia cancelada'**
  String get incidentsCancelledToast;

  /// No description provided for @incidentsCancelFailedTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cancelar la incidencia'**
  String get incidentsCancelFailedTitle;

  /// No description provided for @incidentsTryAgain.
  ///
  /// In es, this message translates to:
  /// **'Intenta de nuevo.'**
  String get incidentsTryAgain;

  /// No description provided for @incidentsDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Incidencia'**
  String get incidentsDetailTitle;

  /// No description provided for @incidentsDetailReportedOn.
  ///
  /// In es, this message translates to:
  /// **'Reportada el {date}'**
  String incidentsDetailReportedOn(String date);

  /// No description provided for @incidentsDetailDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get incidentsDetailDescription;

  /// No description provided for @incidentsDetailPhotos.
  ///
  /// In es, this message translates to:
  /// **'Fotografías'**
  String get incidentsDetailPhotos;

  /// No description provided for @incidentsAttachedPhoto.
  ///
  /// In es, this message translates to:
  /// **'Fotografía adjunta'**
  String get incidentsAttachedPhoto;

  /// No description provided for @incidentsAttachedPhotoHint.
  ///
  /// In es, this message translates to:
  /// **'Toca dos veces para ampliar'**
  String get incidentsAttachedPhotoHint;

  /// No description provided for @incidentsReportMaxPhotos.
  ///
  /// In es, this message translates to:
  /// **'Máximo {count} fotografías'**
  String incidentsReportMaxPhotos(int count);

  /// No description provided for @incidentsReportAddedFirst.
  ///
  /// In es, this message translates to:
  /// **'Agregamos las primeras {count}.'**
  String incidentsReportAddedFirst(int count);

  /// No description provided for @incidentsReportPhotosOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir las fotografías'**
  String get incidentsReportPhotosOpenFailed;

  /// No description provided for @incidentsReportPhotosPermissions.
  ///
  /// In es, this message translates to:
  /// **'Revisa los permisos e intenta de nuevo.'**
  String get incidentsReportPhotosPermissions;

  /// No description provided for @incidentsReportSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los cambios'**
  String get incidentsReportSaveFailed;

  /// No description provided for @incidentsReportSaveFailedBody.
  ///
  /// In es, this message translates to:
  /// **'Tus cambios se conservaron. Intenta de nuevo.'**
  String get incidentsReportSaveFailedBody;

  /// No description provided for @incidentsReportSendFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar el reporte'**
  String get incidentsReportSendFailed;

  /// No description provided for @incidentsReportSendFailedBody.
  ///
  /// In es, this message translates to:
  /// **'Tus datos se conservaron. Intenta de nuevo.'**
  String get incidentsReportSendFailedBody;

  /// No description provided for @incidentsReportChangesSaved.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados'**
  String get incidentsReportChangesSaved;

  /// No description provided for @incidentsReportDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar cambios?'**
  String get incidentsReportDiscardTitle;

  /// No description provided for @incidentsReportDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'Si sales ahora, los cambios que hiciste no se guardarán.'**
  String get incidentsReportDiscardBody;

  /// No description provided for @incidentsReportDiscardAction.
  ///
  /// In es, this message translates to:
  /// **'Descartar cambios'**
  String get incidentsReportDiscardAction;

  /// No description provided for @incidentsReportKeepEditing.
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get incidentsReportKeepEditing;

  /// No description provided for @incidentsReportEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar incidencia'**
  String get incidentsReportEditTitle;

  /// No description provided for @incidentsReportIntro.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué ocurrió. Un administrador dará seguimiento.'**
  String get incidentsReportIntro;

  /// No description provided for @incidentsReportCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría (opcional)'**
  String get incidentsReportCategoryLabel;

  /// No description provided for @incidentsReportCategoryPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar categoría'**
  String get incidentsReportCategoryPlaceholder;

  /// No description provided for @incidentsReportTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título *'**
  String get incidentsReportTitleLabel;

  /// No description provided for @incidentsReportTitleHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué problema quieres reportar?'**
  String get incidentsReportTitleHint;

  /// No description provided for @incidentsReportSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get incidentsReportSaveChanges;

  /// No description provided for @incidentsReportSavingChanges.
  ///
  /// In es, this message translates to:
  /// **'Estamos guardando tus cambios'**
  String get incidentsReportSavingChanges;

  /// No description provided for @incidentsReportSending.
  ///
  /// In es, this message translates to:
  /// **'Estamos enviando tu reporte'**
  String get incidentsReportSending;

  /// No description provided for @incidentsReportWaitMessage.
  ///
  /// In es, this message translates to:
  /// **'Espera un momento mientras guardamos los datos y las fotografías.'**
  String get incidentsReportWaitMessage;

  /// No description provided for @incidentsReportSendingButton.
  ///
  /// In es, this message translates to:
  /// **'Enviando…'**
  String get incidentsReportSendingButton;

  /// No description provided for @incidentsReportPhotoErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Una foto no se pudo subir'**
  String get incidentsReportPhotoErrorTitle;

  /// No description provided for @incidentsReportPhotoErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Reintenta la carga o elimina esa foto para continuar.'**
  String get incidentsReportPhotoErrorBody;

  /// No description provided for @incidentsReportRetryPhoto.
  ///
  /// In es, this message translates to:
  /// **'Reintentar fotografía'**
  String get incidentsReportRetryPhoto;

  /// No description provided for @incidentsReportDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get incidentsReportDone;

  /// No description provided for @incidentsReportSentTitle.
  ///
  /// In es, this message translates to:
  /// **'Incidencia enviada'**
  String get incidentsReportSentTitle;

  /// No description provided for @incidentsReportSentHeadline.
  ///
  /// In es, this message translates to:
  /// **'Tu reporte fue enviado'**
  String get incidentsReportSentHeadline;

  /// No description provided for @incidentsReportSentBody.
  ///
  /// In es, this message translates to:
  /// **'Un administrador dará seguimiento a la incidencia.'**
  String get incidentsReportSentBody;

  /// No description provided for @incidentsReportReceived.
  ///
  /// In es, this message translates to:
  /// **'Reporte recibido'**
  String get incidentsReportReceived;

  /// No description provided for @incidentsReportBackHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get incidentsReportBackHome;

  /// No description provided for @incidentsReportPhotosOptional.
  ///
  /// In es, this message translates to:
  /// **'Fotografías (opcional)'**
  String get incidentsReportPhotosOptional;

  /// No description provided for @incidentsReportAddPhotos.
  ///
  /// In es, this message translates to:
  /// **'Agregar fotografías'**
  String get incidentsReportAddPhotos;

  /// No description provided for @incidentsReportAddMorePhotos.
  ///
  /// In es, this message translates to:
  /// **'Agregar más fotos'**
  String get incidentsReportAddMorePhotos;

  /// No description provided for @incidentsReportUpToPhotos.
  ///
  /// In es, this message translates to:
  /// **'Hasta {count} fotografías'**
  String incidentsReportUpToPhotos(int count);

  /// No description provided for @incidentsReportRemovePhoto.
  ///
  /// In es, this message translates to:
  /// **'Eliminar fotografía'**
  String get incidentsReportRemovePhoto;

  /// No description provided for @incidentsReportUploading.
  ///
  /// In es, this message translates to:
  /// **'Subiendo…'**
  String get incidentsReportUploading;

  /// No description provided for @incidentsReportRetryUploadPhoto.
  ///
  /// In es, this message translates to:
  /// **'Reintentar subida de la fotografía'**
  String get incidentsReportRetryUploadPhoto;

  /// No description provided for @incidentsReportRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get incidentsReportRetry;

  /// No description provided for @incidentsReportPhotoSourceBody.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo quieres agregar tus fotos.'**
  String get incidentsReportPhotoSourceBody;

  /// No description provided for @incidentsReportTakePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get incidentsReportTakePhoto;

  /// No description provided for @incidentsReportChooseGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get incidentsReportChooseGallery;

  /// No description provided for @incidentsReportCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get incidentsReportCancel;

  /// No description provided for @incidentsReportAction.
  ///
  /// In es, this message translates to:
  /// **'Reportar incidencia'**
  String get incidentsReportAction;

  /// No description provided for @visitsStatusPendingRegistration.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de registro'**
  String get visitsStatusPendingRegistration;

  /// No description provided for @visitsStatusScheduled.
  ///
  /// In es, this message translates to:
  /// **'Programada'**
  String get visitsStatusScheduled;

  /// No description provided for @visitsStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get visitsStatusActive;

  /// No description provided for @visitsStatusInside.
  ///
  /// In es, this message translates to:
  /// **'Dentro'**
  String get visitsStatusInside;

  /// No description provided for @visitsStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get visitsStatusCompleted;

  /// No description provided for @visitsStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get visitsStatusCancelled;

  /// No description provided for @visitsStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get visitsStatusRejected;

  /// No description provided for @visitsStatusExpired.
  ///
  /// In es, this message translates to:
  /// **'Expirada'**
  String get visitsStatusExpired;

  /// No description provided for @visitsTypeFrequent.
  ///
  /// In es, this message translates to:
  /// **'Frecuente'**
  String get visitsTypeFrequent;

  /// No description provided for @visitsTypeDelivery.
  ///
  /// In es, this message translates to:
  /// **'Delivery/Proveedor'**
  String get visitsTypeDelivery;

  /// No description provided for @visitsTypeFastlane.
  ///
  /// In es, this message translates to:
  /// **'FastLane'**
  String get visitsTypeFastlane;

  /// No description provided for @visitsRoleFamiliar.
  ///
  /// In es, this message translates to:
  /// **'Familiar'**
  String get visitsRoleFamiliar;

  /// No description provided for @visitsRoleEntrenador.
  ///
  /// In es, this message translates to:
  /// **'Entrenador'**
  String get visitsRoleEntrenador;

  /// No description provided for @visitsRoleEmpleado.
  ///
  /// In es, this message translates to:
  /// **'Empleado'**
  String get visitsRoleEmpleado;

  /// No description provided for @visitsRoleProveedor.
  ///
  /// In es, this message translates to:
  /// **'Proveedor'**
  String get visitsRoleProveedor;

  /// No description provided for @visitsRoleVisitante.
  ///
  /// In es, this message translates to:
  /// **'Visitante'**
  String get visitsRoleVisitante;

  /// No description provided for @visitsRoleInvitado.
  ///
  /// In es, this message translates to:
  /// **'Invitado'**
  String get visitsRoleInvitado;

  /// No description provided for @visitsProviderKindProveedor.
  ///
  /// In es, this message translates to:
  /// **'Proveedor'**
  String get visitsProviderKindProveedor;

  /// No description provided for @visitsProviderKindDelivery.
  ///
  /// In es, this message translates to:
  /// **'Delivery'**
  String get visitsProviderKindDelivery;

  /// No description provided for @visitsProviderKindPaqueteria.
  ///
  /// In es, this message translates to:
  /// **'Paquetería'**
  String get visitsProviderKindPaqueteria;

  /// No description provided for @visitsRecurrenceMonFri.
  ///
  /// In es, this message translates to:
  /// **'Lunes a viernes'**
  String get visitsRecurrenceMonFri;

  /// No description provided for @visitsRecurrenceMonSat.
  ///
  /// In es, this message translates to:
  /// **'Lunes a sábado'**
  String get visitsRecurrenceMonSat;

  /// No description provided for @visitsRecurrenceDaily.
  ///
  /// In es, this message translates to:
  /// **'Todos los días'**
  String get visitsRecurrenceDaily;

  /// No description provided for @visitsRecurrenceCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get visitsRecurrenceCustom;

  /// No description provided for @visitsWeekdayMon.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get visitsWeekdayMon;

  /// No description provided for @visitsWeekdayTue.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get visitsWeekdayTue;

  /// No description provided for @visitsWeekdayWed.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get visitsWeekdayWed;

  /// No description provided for @visitsWeekdayThu.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get visitsWeekdayThu;

  /// No description provided for @visitsWeekdayFri.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get visitsWeekdayFri;

  /// No description provided for @visitsWeekdaySat.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get visitsWeekdaySat;

  /// No description provided for @visitsWeekdaySun.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get visitsWeekdaySun;

  /// No description provided for @visitsFrequentAccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso frecuente'**
  String get visitsFrequentAccess;

  /// No description provided for @visitsAllDay.
  ///
  /// In es, this message translates to:
  /// **'Todo el día'**
  String get visitsAllDay;

  /// No description provided for @visitsMovementDayToday.
  ///
  /// In es, this message translates to:
  /// **'hoy'**
  String get visitsMovementDayToday;

  /// No description provided for @visitsMovementDayYesterday.
  ///
  /// In es, this message translates to:
  /// **'ayer'**
  String get visitsMovementDayYesterday;

  /// No description provided for @visitsMovementDayDate.
  ///
  /// In es, this message translates to:
  /// **'el {date}'**
  String visitsMovementDayDate(String date);

  /// No description provided for @visitsLastEntry.
  ///
  /// In es, this message translates to:
  /// **'Ingreso {day}, {time}'**
  String visitsLastEntry(String day, String time);

  /// No description provided for @visitsLastExit.
  ///
  /// In es, this message translates to:
  /// **'Salida {day}, {time}'**
  String visitsLastExit(String day, String time);

  /// No description provided for @visitsToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get visitsToday;

  /// No description provided for @visitsTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get visitsTomorrow;

  /// No description provided for @visitsPendingInvitationName.
  ///
  /// In es, this message translates to:
  /// **'Invitación por completar'**
  String get visitsPendingInvitationName;

  /// No description provided for @visitsListEmptyPending.
  ///
  /// In es, this message translates to:
  /// **'No tienes visitas pendientes.'**
  String get visitsListEmptyPending;

  /// No description provided for @visitsListEmptyOngoing.
  ///
  /// In es, this message translates to:
  /// **'No tienes visitas en curso.'**
  String get visitsListEmptyOngoing;

  /// No description provided for @visitsListEmptyHistory.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes historial de visitas.'**
  String get visitsListEmptyHistory;

  /// No description provided for @visitsListGroupToday.
  ///
  /// In es, this message translates to:
  /// **'Accesos para hoy · {dayMonth}'**
  String visitsListGroupToday(String dayMonth);

  /// No description provided for @visitsListGroupTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana · {dayMonth}'**
  String visitsListGroupTomorrow(String dayMonth);

  /// No description provided for @visitsListFastlaneSchedule.
  ///
  /// In es, this message translates to:
  /// **'{day} · Llegada prevista {time}'**
  String visitsListFastlaneSchedule(String day, String time);

  /// No description provided for @visitsDeliveryOrProvider.
  ///
  /// In es, this message translates to:
  /// **'Delivery o proveedor'**
  String get visitsDeliveryOrProvider;

  /// No description provided for @visitsListSubtitleDeliveryKind.
  ///
  /// In es, this message translates to:
  /// **'Delivery o proveedor · {kind}'**
  String visitsListSubtitleDeliveryKind(String kind);

  /// No description provided for @visitsListSubtitleFastlane.
  ///
  /// In es, this message translates to:
  /// **'Invitado · FastLane'**
  String get visitsListSubtitleFastlane;

  /// No description provided for @visitsListTitle.
  ///
  /// In es, this message translates to:
  /// **'Visitas'**
  String get visitsListTitle;

  /// No description provided for @visitsListNewVisit.
  ///
  /// In es, this message translates to:
  /// **'Nueva visita'**
  String get visitsListNewVisit;

  /// No description provided for @visitsTabPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get visitsTabPending;

  /// No description provided for @visitsTabOngoing.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get visitsTabOngoing;

  /// No description provided for @visitsTabHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get visitsTabHistory;

  /// No description provided for @visitsListShowFrequent.
  ///
  /// In es, this message translates to:
  /// **'Mostrar visitas frecuentes'**
  String get visitsListShowFrequent;

  /// No description provided for @visitsListLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus visitas.'**
  String get visitsListLoadError;

  /// No description provided for @visitsListHiddenFrequent.
  ///
  /// In es, this message translates to:
  /// **'Tienes {count, plural, =1{1 acceso frecuente oculto} other{{count} accesos frecuentes ocultos}}.'**
  String visitsListHiddenFrequent(int count);

  /// No description provided for @visitsListFrequentHeading.
  ///
  /// In es, this message translates to:
  /// **'Accesos frecuentes'**
  String get visitsListFrequentHeading;

  /// No description provided for @visitsListDailyVisit.
  ///
  /// In es, this message translates to:
  /// **'Visita del día'**
  String get visitsListDailyVisit;

  /// No description provided for @visitsBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get visitsBack;

  /// No description provided for @visitsCatalogTitleService.
  ///
  /// In es, this message translates to:
  /// **'Elige un servicio'**
  String get visitsCatalogTitleService;

  /// No description provided for @visitsCatalogTitleCompany.
  ///
  /// In es, this message translates to:
  /// **'Elige una empresa'**
  String get visitsCatalogTitleCompany;

  /// No description provided for @visitsCatalogSearchLabel.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get visitsCatalogSearchLabel;

  /// No description provided for @visitsCatalogSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Servicio o proveedor'**
  String get visitsCatalogSearchHint;

  /// No description provided for @visitsCatalogOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get visitsCatalogOther;

  /// No description provided for @visitsCatalogLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el catálogo.'**
  String get visitsCatalogLoadError;

  /// No description provided for @visitsCatalogNoResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'No encontramos resultados'**
  String get visitsCatalogNoResultsTitle;

  /// No description provided for @visitsCatalogNoResultsBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes registrar la visita con un nombre personalizado.'**
  String get visitsCatalogNoResultsBody;

  /// No description provided for @visitsCatalogRegisterCustom.
  ///
  /// In es, this message translates to:
  /// **'Registrar con nombre personalizado'**
  String get visitsCatalogRegisterCustom;

  /// No description provided for @visitsTryAgain.
  ///
  /// In es, this message translates to:
  /// **'Intenta de nuevo.'**
  String get visitsTryAgain;

  /// No description provided for @visitsUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get visitsUnit;

  /// No description provided for @visitsPlate.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get visitsPlate;

  /// No description provided for @visitsGateNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas para portería'**
  String get visitsGateNotes;

  /// No description provided for @visitsCancelVisit.
  ///
  /// In es, this message translates to:
  /// **'Cancelar visita'**
  String get visitsCancelVisit;

  /// No description provided for @visitsCancelAccess.
  ///
  /// In es, this message translates to:
  /// **'Cancelar acceso'**
  String get visitsCancelAccess;

  /// No description provided for @visitsDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de visita'**
  String get visitsDetailTitle;

  /// No description provided for @visitsDetailCancelledToast.
  ///
  /// In es, this message translates to:
  /// **'Visita cancelada'**
  String get visitsDetailCancelledToast;

  /// No description provided for @visitsDetailCancelError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cancelar la visita'**
  String get visitsDetailCancelError;

  /// No description provided for @visitsDetailValidity.
  ///
  /// In es, this message translates to:
  /// **'Vigencia'**
  String get visitsDetailValidity;

  /// No description provided for @visitsDetailValiditySameDay.
  ///
  /// In es, this message translates to:
  /// **'{day}, {from} a {until}'**
  String visitsDetailValiditySameDay(String day, String from, String until);

  /// No description provided for @visitsDetailValidityRange.
  ///
  /// In es, this message translates to:
  /// **'{from} a {until}'**
  String visitsDetailValidityRange(String from, String until);

  /// No description provided for @visitsFrequentDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Tu visita'**
  String get visitsFrequentDefaultName;

  /// No description provided for @visitsFrequentCancelBody.
  ///
  /// In es, this message translates to:
  /// **'{name} ya no podrá ingresar con este acceso frecuente.'**
  String visitsFrequentCancelBody(String name);

  /// No description provided for @visitsFrequentCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar acceso'**
  String get visitsFrequentCancelConfirm;

  /// No description provided for @visitsFrequentCancelledToast.
  ///
  /// In es, this message translates to:
  /// **'Acceso cancelado'**
  String get visitsFrequentCancelledToast;

  /// No description provided for @visitsFrequentCancelError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cancelar el acceso'**
  String get visitsFrequentCancelError;

  /// No description provided for @visitsFrequentLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el acceso.'**
  String get visitsFrequentLoadError;

  /// No description provided for @visitsFrequentActiveIntro.
  ///
  /// In es, this message translates to:
  /// **'Tu visita puede ingresar en los días y horarios que definiste.'**
  String get visitsFrequentActiveIntro;

  /// No description provided for @visitsFrequentInactiveIntro.
  ///
  /// In es, this message translates to:
  /// **'Este acceso ya no está disponible.'**
  String get visitsFrequentInactiveIntro;

  /// No description provided for @visitsFrequentEditAccess.
  ///
  /// In es, this message translates to:
  /// **'Editar acceso'**
  String get visitsFrequentEditAccess;

  /// No description provided for @visitsFrequentVisitCaption.
  ///
  /// In es, this message translates to:
  /// **'Visita'**
  String get visitsFrequentVisitCaption;

  /// No description provided for @visitsFrequentVisitCaptionRole.
  ///
  /// In es, this message translates to:
  /// **'Visita · {role}'**
  String visitsFrequentVisitCaptionRole(String role);

  /// No description provided for @visitsFrequentNoName.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get visitsFrequentNoName;

  /// No description provided for @visitsFrequentActiveStatus.
  ///
  /// In es, this message translates to:
  /// **'Acceso activo'**
  String get visitsFrequentActiveStatus;

  /// No description provided for @visitsFrequentValidUntilCancelled.
  ///
  /// In es, this message translates to:
  /// **'Vigente hasta que lo canceles.'**
  String get visitsFrequentValidUntilCancelled;

  /// No description provided for @visitsFrequentDaysAndHours.
  ///
  /// In es, this message translates to:
  /// **'Días y horario'**
  String get visitsFrequentDaysAndHours;

  /// No description provided for @visitsFrequentVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get visitsFrequentVehicle;

  /// No description provided for @visitsFrequentLastMovement.
  ///
  /// In es, this message translates to:
  /// **'Último movimiento'**
  String get visitsFrequentLastMovement;

  /// No description provided for @visitsArrivalToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy, {rest}'**
  String visitsArrivalToday(String rest);

  /// No description provided for @visitsArrivalTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana, {rest}'**
  String visitsArrivalTomorrow(String rest);

  /// No description provided for @visitsDateToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy, {date}'**
  String visitsDateToday(String date);

  /// No description provided for @visitsPendingLinkCopied.
  ///
  /// In es, this message translates to:
  /// **'Enlace copiado'**
  String get visitsPendingLinkCopied;

  /// No description provided for @visitsPendingShareTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitación FastLane'**
  String get visitsPendingShareTitle;

  /// No description provided for @visitsPendingShareTitleResidential.
  ///
  /// In es, this message translates to:
  /// **'Invitación a {residential}'**
  String visitsPendingShareTitleResidential(String residential);

  /// No description provided for @visitsPendingCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar invitación'**
  String get visitsPendingCancel;

  /// No description provided for @visitsPendingCancelBody.
  ///
  /// In es, this message translates to:
  /// **'El enlace dejará de funcionar y tu visita ya no podrá registrarse con él.'**
  String get visitsPendingCancelBody;

  /// No description provided for @visitsPendingCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar invitación'**
  String get visitsPendingCancelConfirm;

  /// No description provided for @visitsPendingCancelledToast.
  ///
  /// In es, this message translates to:
  /// **'Invitación cancelada'**
  String get visitsPendingCancelledToast;

  /// No description provided for @visitsPendingCancelError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cancelar la invitación'**
  String get visitsPendingCancelError;

  /// No description provided for @visitsPendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitación creada'**
  String get visitsPendingTitle;

  /// No description provided for @visitsPendingIntro.
  ///
  /// In es, this message translates to:
  /// **'Comparte el enlace para que tu visitante complete sus datos.'**
  String get visitsPendingIntro;

  /// No description provided for @visitsPendingShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir invitación'**
  String get visitsPendingShare;

  /// No description provided for @visitsPendingCopyLink.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get visitsPendingCopyLink;

  /// No description provided for @visitsPendingEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar invitación'**
  String get visitsPendingEdit;

  /// No description provided for @visitsPendingGoToVisits.
  ///
  /// In es, this message translates to:
  /// **'Ir a mis visitas'**
  String get visitsPendingGoToVisits;

  /// No description provided for @visitsPendingExpectedArrival.
  ///
  /// In es, this message translates to:
  /// **'Llegada prevista'**
  String get visitsPendingExpectedArrival;

  /// No description provided for @visitsPendingDataStatus.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de datos'**
  String get visitsPendingDataStatus;

  /// No description provided for @visitsPendingVisitorWillComplete.
  ///
  /// In es, this message translates to:
  /// **'Tu visitante completará sus datos al abrir el enlace.'**
  String get visitsPendingVisitorWillComplete;

  /// No description provided for @visitsPendingLinkLabel.
  ///
  /// In es, this message translates to:
  /// **'Enlace de invitación'**
  String get visitsPendingLinkLabel;

  /// No description provided for @visitsFastlaneVisitDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de visita'**
  String get visitsFastlaneVisitDate;

  /// No description provided for @visitsFastlaneUpdatedToast.
  ///
  /// In es, this message translates to:
  /// **'Invitación actualizada'**
  String get visitsFastlaneUpdatedToast;

  /// No description provided for @visitsSaveError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los cambios'**
  String get visitsSaveError;

  /// No description provided for @visitsFastlaneCreateError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos crear la invitación'**
  String get visitsFastlaneCreateError;

  /// No description provided for @visitsFastlaneTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitar con FastLane'**
  String get visitsFastlaneTitle;

  /// No description provided for @visitsUnitUpper.
  ///
  /// In es, this message translates to:
  /// **'UNIDAD'**
  String get visitsUnitUpper;

  /// No description provided for @visitsFastlaneNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de referencia *'**
  String get visitsFastlaneNameLabel;

  /// No description provided for @visitsFastlaneNameHint.
  ///
  /// In es, this message translates to:
  /// **'Visita de...'**
  String get visitsFastlaneNameHint;

  /// No description provided for @visitsFastlaneNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para identificar la visita.'**
  String get visitsFastlaneNameRequired;

  /// No description provided for @visitsFastlaneDateHelper.
  ///
  /// In es, this message translates to:
  /// **'Fecha prevista para la visita.'**
  String get visitsFastlaneDateHelper;

  /// No description provided for @visitsFastlaneArrivalLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora de llegada prevista *'**
  String get visitsFastlaneArrivalLabel;

  /// No description provided for @visitsSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get visitsSaveChanges;

  /// No description provided for @visitsFastlaneCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear invitación'**
  String get visitsFastlaneCreate;

  /// No description provided for @visitsNewTypeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quién viene?'**
  String get visitsNewTypeTitle;

  /// No description provided for @visitsNewTypeAccessFor.
  ///
  /// In es, this message translates to:
  /// **'Acceso para'**
  String get visitsNewTypeAccessFor;

  /// No description provided for @visitsNewTypeGuest.
  ///
  /// In es, this message translates to:
  /// **'Invitado'**
  String get visitsNewTypeGuest;

  /// No description provided for @visitsNewTypeGuestSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea una invitación con registro del visitante'**
  String get visitsNewTypeGuestSubtitle;

  /// No description provided for @visitsNewTypeDeliverySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Autoriza una entrega o servicio'**
  String get visitsNewTypeDeliverySubtitle;

  /// No description provided for @visitsNewTypeFrequentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para personas que vienen regularmente'**
  String get visitsNewTypeFrequentSubtitle;

  /// No description provided for @visitsWeekdayInitialMon.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get visitsWeekdayInitialMon;

  /// No description provided for @visitsWeekdayInitialTue.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get visitsWeekdayInitialTue;

  /// No description provided for @visitsWeekdayInitialWed.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get visitsWeekdayInitialWed;

  /// No description provided for @visitsWeekdayInitialThu.
  ///
  /// In es, this message translates to:
  /// **'J'**
  String get visitsWeekdayInitialThu;

  /// No description provided for @visitsWeekdayInitialFri.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get visitsWeekdayInitialFri;

  /// No description provided for @visitsWeekdayInitialSat.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get visitsWeekdayInitialSat;

  /// No description provided for @visitsWeekdayInitialSun.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get visitsWeekdayInitialSun;

  /// No description provided for @visitsScheduleBlockTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloque de horario {number}'**
  String visitsScheduleBlockTitle(int number);

  /// No description provided for @visitsScheduleBlockRemove.
  ///
  /// In es, this message translates to:
  /// **'Eliminar bloque'**
  String get visitsScheduleBlockRemove;

  /// No description provided for @visitsScheduleFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get visitsScheduleFrom;

  /// No description provided for @visitsScheduleTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get visitsScheduleTo;

  /// No description provided for @visitsFrequentCurrentDocument.
  ///
  /// In es, this message translates to:
  /// **'Documento actual'**
  String get visitsFrequentCurrentDocument;

  /// No description provided for @visitsFrequentIdDocument.
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad'**
  String get visitsFrequentIdDocument;

  /// No description provided for @visitsFrequentTakePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get visitsFrequentTakePhoto;

  /// No description provided for @visitsFrequentPickGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get visitsFrequentPickGallery;

  /// No description provided for @visitsFrequentPhotoTooBig.
  ///
  /// In es, this message translates to:
  /// **'La foto supera los 10 MB. Elige una más ligera.'**
  String get visitsFrequentPhotoTooBig;

  /// No description provided for @visitsFrequentMissingData.
  ///
  /// In es, this message translates to:
  /// **'Falta un dato'**
  String get visitsFrequentMissingData;

  /// No description provided for @visitsFrequentSelectDayEachBlock.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un día en cada bloque de horario.'**
  String get visitsFrequentSelectDayEachBlock;

  /// No description provided for @visitsFrequentStartBeforeEnd.
  ///
  /// In es, this message translates to:
  /// **'La hora de inicio debe ser anterior a la hora final.'**
  String get visitsFrequentStartBeforeEnd;

  /// No description provided for @visitsFrequentUpdatedToast.
  ///
  /// In es, this message translates to:
  /// **'Acceso actualizado'**
  String get visitsFrequentUpdatedToast;

  /// No description provided for @visitsFrequentAuthorizedToast.
  ///
  /// In es, this message translates to:
  /// **'Acceso frecuente autorizado'**
  String get visitsFrequentAuthorizedToast;

  /// No description provided for @visitsFrequentAuthorizeError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos autorizar el acceso'**
  String get visitsFrequentAuthorizeError;

  /// No description provided for @visitsFrequentStep1.
  ///
  /// In es, this message translates to:
  /// **'1 de 2 · Datos de la visita'**
  String get visitsFrequentStep1;

  /// No description provided for @visitsFrequentStep2.
  ///
  /// In es, this message translates to:
  /// **'2 de 2 · Permisos de acceso'**
  String get visitsFrequentStep2;

  /// No description provided for @visitsContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get visitsContinue;

  /// No description provided for @visitsFrequentAuthorize.
  ///
  /// In es, this message translates to:
  /// **'Autorizar acceso'**
  String get visitsFrequentAuthorize;

  /// No description provided for @visitsFrequentNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la visita *'**
  String get visitsFrequentNameLabel;

  /// No description provided for @visitsFrequentNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre de la visita.'**
  String get visitsFrequentNameRequired;

  /// No description provided for @visitsFrequentTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get visitsFrequentTypeLabel;

  /// No description provided for @visitsFrequentPhoneInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un teléfono válido.'**
  String get visitsFrequentPhoneInvalid;

  /// No description provided for @visitsFrequentIdDocumentRequired.
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad *'**
  String get visitsFrequentIdDocumentRequired;

  /// No description provided for @visitsFrequentIdDocumentHint.
  ///
  /// In es, this message translates to:
  /// **'Adjunta una foto legible del documento.'**
  String get visitsFrequentIdDocumentHint;

  /// No description provided for @visitsFrequentIdDocumentMissing.
  ///
  /// In es, this message translates to:
  /// **'Adjunta una foto del documento para continuar.'**
  String get visitsFrequentIdDocumentMissing;

  /// No description provided for @visitsFrequentHasVehicle.
  ///
  /// In es, this message translates to:
  /// **'Ingresará en vehículo'**
  String get visitsFrequentHasVehicle;

  /// No description provided for @visitsFrequentHasVehicleHint.
  ///
  /// In es, this message translates to:
  /// **'Activa para ingresar la placa'**
  String get visitsFrequentHasVehicleHint;

  /// No description provided for @visitsFrequentPlateLabel.
  ///
  /// In es, this message translates to:
  /// **'Placa del vehículo'**
  String get visitsFrequentPlateLabel;

  /// No description provided for @visitsFrequentPlateHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la placa'**
  String get visitsFrequentPlateHint;

  /// No description provided for @visitsFrequentPlateRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe la placa del vehículo.'**
  String get visitsFrequentPlateRequired;

  /// No description provided for @visitsFrequentFrequencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get visitsFrequentFrequencyLabel;

  /// No description provided for @visitsFrequentGroupDaysHint.
  ///
  /// In es, this message translates to:
  /// **'Agrupa los días que comparten el mismo horario.'**
  String get visitsFrequentGroupDaysHint;

  /// No description provided for @visitsFrequentScheduleLabel.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get visitsFrequentScheduleLabel;

  /// No description provided for @visitsFrequentNotifyLabel.
  ///
  /// In es, this message translates to:
  /// **'Avisarme al llegar'**
  String get visitsFrequentNotifyLabel;

  /// No description provided for @visitsFrequentNotifyHint.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones de mis visitas'**
  String get visitsFrequentNotifyHint;

  /// No description provided for @visitsFrequentAddBlock.
  ///
  /// In es, this message translates to:
  /// **'+ Agregar bloque'**
  String get visitsFrequentAddBlock;

  /// No description provided for @visitsDateTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana, {date}'**
  String visitsDateTomorrow(String date);

  /// No description provided for @visitsDetailsAuthorizedToast.
  ///
  /// In es, this message translates to:
  /// **'Visita autorizada'**
  String get visitsDetailsAuthorizedToast;

  /// No description provided for @visitsDetailsAuthorizeError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos autorizar la visita'**
  String get visitsDetailsAuthorizeError;

  /// No description provided for @visitsDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles de la visita'**
  String get visitsDetailsTitle;

  /// No description provided for @visitsDetailsService.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get visitsDetailsService;

  /// No description provided for @visitsDetailsDateHelper.
  ///
  /// In es, this message translates to:
  /// **'Acceso válido durante el día seleccionado.'**
  String get visitsDetailsDateHelper;

  /// No description provided for @visitsDetailsPickTime.
  ///
  /// In es, this message translates to:
  /// **'Elige una hora'**
  String get visitsDetailsPickTime;

  /// No description provided for @visitsDetailsAuthorize.
  ///
  /// In es, this message translates to:
  /// **'Autorizar visita'**
  String get visitsDetailsAuthorize;

  /// No description provided for @visitsDetailsNotesLabel.
  ///
  /// In es, this message translates to:
  /// **'Notas para portería (opcional)'**
  String get visitsDetailsNotesLabel;

  /// No description provided for @visitsDetailsNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega una indicación'**
  String get visitsDetailsNotesHint;

  /// No description provided for @visitsDetailsChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar visita'**
  String get visitsDetailsChange;

  /// No description provided for @visitsDetailsNameHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre'**
  String get visitsDetailsNameHint;

  /// No description provided for @visitsDetailsUseName.
  ///
  /// In es, this message translates to:
  /// **'Usar este nombre'**
  String get visitsDetailsUseName;

  /// No description provided for @commonErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet e intenta de nuevo.'**
  String get commonErrorNetwork;

  /// No description provided for @commonErrorSession.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión expiró o no tienes permiso. Inicia sesión de nuevo.'**
  String get commonErrorSession;

  /// No description provided for @commonErrorServer.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal de nuestro lado. Intenta de nuevo en un momento.'**
  String get commonErrorServer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
