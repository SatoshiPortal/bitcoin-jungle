import 'package:meta/meta.dart';
import 'package:primitives/primitives.dart';

import '../add_place_failure.dart';
import '../entities/place_submission.dart';

abstract interface class PlaceSubmissionRepository {
  /// Sends [place] to the proxy, which forwards it to BTC Map.
  @useResult
  Future<Result<void, AddPlaceFailure>> submit(PlaceSubmission place);
}
