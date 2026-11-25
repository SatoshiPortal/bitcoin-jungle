import 'package:add_place/add_place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the proxy must use https, since the request can carry an email', () {
    expect(
      () => AddPlaceFeature.mount(
        submitUrl: Uri.parse('http://proxy.example/submit'),
      ),
      throwsArgumentError,
    );
    expect(
      AddPlaceFeature.mount(
        submitUrl: Uri.parse('https://proxy.example/submit'),
      ).routes,
      hasLength(1),
    );
  });

  test('no proxy yet still mounts the route', () {
    expect(AddPlaceFeature.mount().routes.single.path, '/add-place');
  });
}
