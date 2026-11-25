import 'package:btc_map/btc_map.dart' show GeoBounds;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/usecases/submit_place_usecase.dart';
import '../domain/usecases/suggest_address_usecase.dart';
import '../presentation/add_place_cubit.dart';
import '../presentation/address_suggestion_cubit.dart';
import 'add_place_screen.dart';

abstract final class AddPlaceRouter {
  static const name = 'addPlace';

  /// The route's extra is the area the map showed, or null.
  static GoRoute route({
    required SubmitPlaceUsecase submit,
    required SuggestAddressUsecase suggest,
  }) => GoRoute(
    name: name,
    path: '/add-place',
    builder: (context, state) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AddPlaceCubit(submit)),
        BlocProvider(create: (_) => AddressSuggestionCubit(suggest)),
      ],
      child: AddPlaceScreen(
        initialArea: switch (state.extra) {
          final GeoBounds area => area,
          _ => null,
        },
      ),
    ),
  );
}
