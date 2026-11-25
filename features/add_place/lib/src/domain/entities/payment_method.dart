/// How a place accepts bitcoin, with the value BTC Map's submission expects.
enum PaymentMethod {
  onchain('onchain'),
  lightning('lightning'),
  nfc('nfc');

  final String apiValue;

  const PaymentMethod(this.apiValue);
}
