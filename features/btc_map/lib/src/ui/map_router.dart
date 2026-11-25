import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:btc_map/src/presentation/map_cubit.dart';
import 'package:btc_map/src/ui/map_add_place_action.dart';
import 'package:btc_map/src/ui/map_screen.dart';

final class MapRouter {
  static const name = 'map';

  static final route = GoRoute(
    name: name,
    path: '/map',
    builder: (context, state) => BlocProvider(
      create: (_) => GetIt.I<MapCubit>()..start(),
      child: MapScreen(
        addPlace: GetIt.I.isRegistered<MapAddPlaceAction>()
            ? GetIt.I<MapAddPlaceAction>()
            : null,
      ),
    ),
  );
}
