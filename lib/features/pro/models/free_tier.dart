/// Free-tier limits from the product spec. Safety features (reminders,
/// encryption, app lock) are never gated — only volume and ads are.
class FreeTier {
  const FreeTier._();

  static const int maxDocuments = 10;
  static const int maxProfiles = 2;

  /// In-app purchase product id; must match the Play Console entry exactly.
  static const String proProductId = 'pro_unlock';

  static String documentLimitMessage(int count) =>
      'The free vault holds $maxDocuments documents — you have $count. '
      'Unlock Pro for unlimited documents.';

  static String profileLimitMessage(int count) =>
      'The free tier holds $maxProfiles people — you have $count. '
      'Unlock Pro for unlimited people.';
}
