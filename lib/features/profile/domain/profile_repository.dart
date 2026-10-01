import 'profile.dart';

/// What the profile feature needs from the backend. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions.
abstract interface class ProfileRepository {
  Future<Profile> fetchMine();

  Future<void> updateMine({String? firstName, String? lastName, String? phone});
}
