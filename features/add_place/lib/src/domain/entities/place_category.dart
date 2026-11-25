/// BTC Map's categories, with the value its submission expects. "Other" is not here: the user then types the category.
enum PlaceCategory {
  restaurants('restaurants'),
  shopping('shopping'),
  groceries('groceries'),
  coffee('coffee'),
  atms('atms'),
  hotels('hotels'),
  beauty('beauty');

  final String apiValue;

  const PlaceCategory(this.apiValue);
}
