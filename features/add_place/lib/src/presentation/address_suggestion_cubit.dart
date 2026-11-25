import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:primitives/primitives.dart';

import '../domain/usecases/suggest_address_usecase.dart';

/// The address suggested for the pin.
sealed class AddressSuggestionState {
  const AddressSuggestionState();
}

final class AddressSuggestionIdle extends AddressSuggestionState {
  const AddressSuggestionIdle();
}

final class AddressSuggestionLoading extends AddressSuggestionState {
  const AddressSuggestionLoading();
}

final class AddressSuggested extends AddressSuggestionState {
  final String address;

  const AddressSuggested(this.address);
}

/// No address is known at the pin, or it could not be looked up; the field stays for the user to fill in.
final class AddressNotFound extends AddressSuggestionState {
  const AddressNotFound();
}

class AddressSuggestionCubit extends Cubit<AddressSuggestionState> {
  final SuggestAddressUsecase _suggest;
  int _request = 0;

  AddressSuggestionCubit(this._suggest) : super(const AddressSuggestionIdle());

  Future<void> suggestFor(
    GeoPoint location, {
    required String languageCode,
  }) async {
    final request = ++_request;
    emit(const AddressSuggestionLoading());
    final result = await _suggest.execute(location, languageCode: languageCode);
    // A newer pin has been chosen meanwhile.
    if (isClosed || request != _request) return;
    emit(switch (result) {
      Ok(value: final address?) => AddressSuggested(address),
      Ok() || Err() => const AddressNotFound(),
    });
  }
}
