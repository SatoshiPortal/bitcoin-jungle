import '../domain/add_place_failure.dart';

/// Where sending the new place stands.
sealed class AddPlaceState {
  const AddPlaceState();
}

final class AddPlaceIdle extends AddPlaceState {
  const AddPlaceIdle();
}

final class AddPlaceSending extends AddPlaceState {
  const AddPlaceSending();
}

final class AddPlaceSent extends AddPlaceState {
  const AddPlaceSent();
}

final class AddPlaceFailed extends AddPlaceState {
  final AddPlaceFailure failure;

  const AddPlaceFailed(this.failure);
}
