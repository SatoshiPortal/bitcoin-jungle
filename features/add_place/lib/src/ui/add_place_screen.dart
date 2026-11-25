import 'package:btc_map/btc_map.dart'
    show BullMapController, BullMapView, GeoBounds, GeoPoint;
import 'package:bull_ui/bull_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/entities/payment_method.dart';
import '../domain/entities/pin_area.dart';
import '../domain/entities/place_category.dart';
import '../presentation/add_place_cubit.dart';
import '../presentation/add_place_failure_l10n.dart';
import '../presentation/add_place_localizations_x.dart';
import '../presentation/add_place_state.dart';
import '../presentation/address_suggestion_cubit.dart';
import '../presentation/place_labels_l10n.dart';

/// Suggests a new place: first a pin picker, then BTC Map's form fields.
class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key, this.initialArea});

  /// The area the main map showed, so the picker opens on it at the same zoom.
  final GeoBounds? initialArea;

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  /// Size of the pin icon. Its tip is at 22/24 of the glyph's height, so the
  /// icon is lifted until the tip, not the icon's middle, marks the centre.
  static const _pinSize = 48.0;
  static const _pinLift = -_pinSize * (22 - 12) / 24;

  final _mapController = BullMapController();
  PinArea? _viewArea;
  GeoBounds? _pickedArea;
  GeoPoint? _location;
  bool _picking = true;

  /// The picker was opened from the form with "Change", so going back returns to the form instead of leaving.
  bool _returnToForm = false;

  String _name = '';
  PlaceCategory? _category;
  bool _otherCategory = false;
  String _otherCategoryName = '';
  final Set<PaymentMethod> _paymentMethods = {};
  String _contact = '';
  String _address = '';

  /// The address field holds the suggestion from the pin, untouched by the user, so a newer suggestion may replace it.
  bool _addressFromPin = false;
  String _website = '';
  String _phone = '';
  String _openingHours = '';
  String _notes = '';

  bool get _leavesOnBack => _picking && !_returnToForm;

  void _onSubmission(BuildContext context, AddPlaceState state) {
    switch (state) {
      case AddPlaceSent():
        BullSnackBar.show(context, message: context.addPlaceLoc.placeSent);
        context.pop();
      case AddPlaceFailed(:final failure):
        BullSnackBar.show(context, message: failure.toTranslated(context));
      case AddPlaceIdle() || AddPlaceSending():
        break;
    }
  }

  void _usePin(PinArea area) {
    setState(() {
      _pickedArea = area.bounds;
      _location = area.pin;
      _picking = false;
      _returnToForm = false;
    });
    context.read<AddressSuggestionCubit>().suggestFor(
      area.pin,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  void _back() {
    if (_leavesOnBack) {
      context.pop();
    } else if (_picking) {
      setState(() => _picking = false);
    } else {
      setState(() {
        _picking = true;
        _returnToForm = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _leavesOnBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<AddressSuggestionCubit, AddressSuggestionState>(
            listener: (context, state) => switch (state) {
              AddressSuggested(:final address)
                  when _address.trim().isEmpty || _addressFromPin =>
                setState(() {
                  _address = address;
                  _addressFromPin = true;
                }),
              // The pin moved somewhere without a known address: the old suggestion would be wrong.
              AddressNotFound() when _addressFromPin => setState(() {
                _address = '';
                _addressFromPin = false;
              }),
              _ => null,
            },
          ),
          BlocListener<AddPlaceCubit, AddPlaceState>(listener: _onSubmission),
        ],
        child: BullScaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            automaticallyImplyLeading: false,
            flexibleSpace: BullTopBar(
              title: context.addPlaceLoc.addPlaceTitle,
              onBack: _back,
            ),
          ),
          body: _picking ? _picker(context) : _form(context),
        ),
      ),
    );
  }

  Widget _picker(BuildContext context) {
    final area = _viewArea;
    final closeEnough = area != null && area.isCloseEnough;
    return Stack(
      children: [
        BullMapView(
          merchants: const [],
          controller: _mapController,
          initialBounds: _pickedArea ?? widget.initialArea,
          onMerchantTap: (_) {},
          onViewportChanged: (bounds) =>
              setState(() => _viewArea = PinArea(bounds)),
        ),
        IgnorePointer(
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, _pinLift),
              child: Icon(
                Icons.location_on,
                size: _pinSize,
                color: context.bull.primary,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.bull.surface,
                      borderRadius: BorderRadius.circular(
                        context.bullShapes.card,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: BullText(
                        closeEnough || area == null
                            ? context.addPlaceLoc.pickLocationHint
                            : context.addPlaceLoc.zoomInToPick,
                        style: context.bullType.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Gap(12),
                  BullButton.primary(
                    label: context.addPlaceLoc.useThisLocation,
                    onPressed: closeEnough ? () => _usePin(area) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final loc = context.addPlaceLoc;
    final location = _location;
    return BlocBuilder<AddPlaceCubit, AddPlaceState>(
      builder: (context, state) {
        final sending = state is AddPlaceSending;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Label(loc.placeLocation),
            Row(
              children: [
                Expanded(
                  child: BullText(
                    location == null
                        ? ''
                        : '${location.latitude.toStringAsFixed(5)}, '
                              '${location.longitude.toStringAsFixed(5)}',
                    style: context.bullType.body,
                  ),
                ),
                TextButton(
                  onPressed: sending
                      ? null
                      : () => setState(() {
                          _picking = true;
                          _returnToForm = true;
                        }),
                  child: BullText(
                    loc.changeLocation,
                    style: context.bullType.label,
                    color: context.bull.primary,
                  ),
                ),
              ],
            ),
            const Gap(16),
            _field(
              const ValueKey('name'),
              loc.placeName,
              _name,
              (value) => _name = value,
              sending,
            ),
            _Label(loc.placeCategory),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in PlaceCategory.values)
                  BullFilterChip.selectable(
                    label: category.label(context),
                    selected: !_otherCategory && _category == category,
                    onSelected: (_) => sending
                        ? null
                        : setState(() {
                            _category = category;
                            _otherCategory = false;
                          }),
                  ),
                BullFilterChip.selectable(
                  label: loc.categoryOther,
                  selected: _otherCategory,
                  onSelected: (_) => sending
                      ? null
                      : setState(() {
                          _category = null;
                          _otherCategory = true;
                        }),
                ),
              ],
            ),
            const Gap(16),
            if (_otherCategory)
              _field(
                const ValueKey('otherCategory'),
                loc.placeOtherCategory,
                _otherCategoryName,
                (value) => _otherCategoryName = value,
                sending,
              ),
            _Label(loc.paymentMethods),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in PaymentMethod.values)
                  BullFilterChip.selectable(
                    label: method.label(context),
                    selected: _paymentMethods.contains(method),
                    onSelected: (selected) => sending
                        ? null
                        : setState(
                            () => selected
                                ? _paymentMethods.add(method)
                                : _paymentMethods.remove(method),
                          ),
                  ),
              ],
            ),
            const Gap(16),
            _field(
              const ValueKey('contact'),
              loc.contactEmail,
              _contact,
              (value) => _contact = value,
              sending,
              plain: true,
            ),
            _field(
              const ValueKey('address'),
              loc.placeAddress,
              _address,
              (value) {
                _address = value;
                _addressFromPin = false;
              },
              sending,
              footer: _addressHint(context),
            ),
            _field(
              const ValueKey('website'),
              loc.placeWebsite,
              _website,
              (value) => _website = value,
              sending,
              plain: true,
            ),
            _field(
              const ValueKey('phone'),
              loc.placePhone,
              _phone,
              (value) => _phone = value,
              sending,
            ),
            _field(
              const ValueKey('openingHours'),
              loc.placeOpeningHours,
              _openingHours,
              (value) => _openingHours = value,
              sending,
            ),
            _field(
              const ValueKey('notes'),
              loc.placeNotes,
              _notes,
              (value) => _notes = value,
              sending,
              lines: 3,
            ),
            const Gap(8),
            if (sending)
              const Center(child: BullLoader.small())
            else
              BullButton.primary(
                label: loc.submitPlace,
                onPressed: location == null
                    ? null
                    : () => context.read<AddPlaceCubit>().submit(
                        name: _name,
                        location: location,
                        category: _otherCategory ? null : _category,
                        otherCategory: _otherCategory
                            ? _otherCategoryName
                            : null,
                        paymentMethods: {..._paymentMethods},
                        contact: _contact,
                        address: _address,
                        website: _website,
                        phone: _phone,
                        openingHours: _openingHours,
                        notes: _notes,
                      ),
              ),
            const Gap(16),
          ],
        );
      },
    );
  }

  /// A labelled text field; the value lives in this widget's state. [plain] turns off autocorrect and suggestions, for an email or a web address.
  Widget _field(
    Key key,
    String label,
    String value,
    void Function(String) update,
    bool disabled, {
    int lines = 1,
    bool plain = false,
    Widget? footer,
  }) => Padding(
    key: key,
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: _Label(label)),
        BullInputText(
          value: value,
          semanticLabel: label,
          onChanged: (text) => setState(() => update(text)),
          disabled: disabled,
          autocorrect: !plain,
          enableSuggestions: !plain,
          minLines: lines,
          maxLines: lines,
        ),
        // Its own node, so it is not read as part of the field's name.
        if (footer != null) Semantics(container: true, child: footer),
      ],
    ),
  );

  /// Under the address: the lookup in progress, or that the address came from the pin.
  Widget? _addressHint(BuildContext context) {
    final state = context.watch<AddressSuggestionCubit>().state;
    final hint = switch (state) {
      AddressSuggestionLoading() => context.addPlaceLoc.addressLookingUp,
      AddressSuggested() when _addressFromPin =>
        context.addPlaceLoc.addressSuggestedHint,
      _ => null,
    };
    if (hint == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: BullText(
        hint,
        style: context.bullType.caption,
        color: context.bull.textMuted,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: BullText(
      text,
      style: context.bullType.label,
      color: context.bull.textMuted,
    ),
  );
}
