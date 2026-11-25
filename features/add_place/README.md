# Add Place

Bitcoin Jungle only. `package:add_place/add_place.dart` lets a user suggest a place that accepts bitcoin without leaving the app. It copies the fields of BTC Map's own form and sends them to Bitcoin Jungle's proxy, which forwards them to BTC Map with Bitcoin Jungle's token. The token never ships in the app.

- `AddPlaceFeature.mount(submitUrl:, addressLookupUrl:)` builds the feature and returns its route for the router. `submitUrl` is the proxy's URL; until it is known it is null, and sending reports that adding places is not available yet. It must use `https`, because the request can carry the user's email.
- `AddPlaceFeature.addPlaceAction` is the map's "add a place" button, passed to `BtcMapFeature.setup(addPlace:)`. It opens a pin picker at the main map's area and zoom; the user moves the map under a fixed pin, zoomed in to street level, then fills in the form.

It depends on `btc_map` for the map view the picker reuses, its location types and the add-place action.

## Address suggestion

When the user confirms the pin, the address field is filled from the pin as an editable suggestion, the way BTC Map's own form does it. An address the user typed is never replaced.

The lookup uses OpenStreetMap's Nominatim reverse geocoding by default. Its [usage policy](https://operations.osmfoundation.org/policies/nominatim/) (checked 2026-11-24) asks for at most one request per second, a User-Agent that names the app, visible attribution, and a service that can be switched without an app update:

- one lookup per confirmed pin, and a spot already looked up is answered from memory;
- the User-Agent is `BitcoinJungleWallet/1.0 (+https://bitcoinjungle.app)`;
- the picker's map keeps OpenStreetMap's attribution button visible;
- `addressLookupUrl` can point at any service that answers like Nominatim, such as Bitcoin Jungle's proxy.

The pin's coordinates are sent to that service.

## Request sent to the proxy

`POST submitUrl` with a JSON body that mirrors BTC Map's `submit_place`; empty optional fields are left out:

```json
{
  "name": "Soda Tica",
  "lat": 9.32185,
  "lon": -83.66886,
  "category": "restaurants",
  "payment_methods": ["onchain", "lightning"],
  "contact": "owner@example.com",
  "address": "Uvita, Puntarenas",
  "website": "https://soda.example",
  "phone": "+506 8888 8888",
  "opening_hours": "Mo-Sa 08:00-20:00",
  "notes": "Casados and fresh juice"
}
```

`contact` is optional: the user's email, for BTC Map to follow up, sent only when given. `category` is one of BTC Map's categories (`restaurants`, `shopping`, `groceries`, `coffee`, `atms`, `hotels`, `beauty`) or the user's own text for "Other". `payment_methods` uses BTC Map's values (`onchain`, `lightning`, `nfc`). Any 2xx answer counts as sent.
