import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:primitives/primitives.dart';

import '../domain/entities/payment_method.dart';
import '../domain/entities/place_category.dart';
import '../domain/usecases/submit_place_usecase.dart';
import 'add_place_state.dart';

class AddPlaceCubit extends Cubit<AddPlaceState> {
  final SubmitPlaceUsecase _submit;

  AddPlaceCubit(this._submit) : super(const AddPlaceIdle());

  Future<void> submit({
    required String name,
    required GeoPoint location,
    required PlaceCategory? category,
    String? otherCategory,
    required Set<PaymentMethod> paymentMethods,
    String? contact,
    String? address,
    String? website,
    String? phone,
    String? openingHours,
    String? notes,
  }) async {
    if (state is AddPlaceSending) return;
    emit(const AddPlaceSending());
    final result = await _submit.execute(
      name: name,
      location: location,
      category: category,
      otherCategory: otherCategory,
      paymentMethods: paymentMethods,
      contact: contact,
      address: address,
      website: website,
      phone: phone,
      openingHours: openingHours,
      notes: notes,
    );
    if (isClosed) return;
    emit(switch (result) {
      Ok() => const AddPlaceSent(),
      Err(:final failure) => AddPlaceFailed(failure),
    });
  }
}
