import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../settings/providers/settings_provider.dart';
import '../models/free_tier.dart';

/// Last purchase-flow message (success, error, restore result) for the paywall.
final purchaseMessageProvider =
    NotifierProvider<PurchaseMessageNotifier, String?>(
        PurchaseMessageNotifier.new);

class PurchaseMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}

/// Wraps the one-time "Pro" unlock.
///
/// Never throws: if the Play Store is unavailable (no Play services, tests,
/// unsupported device) the paywall simply explains that purchases cannot be
/// completed right now. The entitlement itself lives in the encrypted settings
/// box, written only after a verified `purchased`/`restored` status.
final proServiceProvider = Provider<ProService>((ref) => ProService(ref));

class ProService {
  ProService(this._ref);

  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _product;
  bool _initialized = false;
  bool _storeAvailable = false;

  bool get isPro => _ref.read(settingsProvider).isPro;

  bool get storeAvailable => _storeAvailable && _product != null;

  /// Localized price string, e.g. "₱249.00", or null before the query lands.
  String? get priceLabel => _product?.price;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _storeAvailable = await _iap.isAvailable();
      if (!_storeAvailable) return;

      _subscription ??=
          _iap.purchaseStream.listen(_onPurchases, onError: (_) {
        _ref.read(purchaseMessageProvider.notifier)
            .show('The Play Store returned an error. Please try again.');
      });

      final response = await _iap
          .queryProductDetails({FreeTier.proProductId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
      }
    } catch (_) {
      _storeAvailable = false;
    }
  }

  Future<void> buyPro() async {
    final product = _product;
    if (product == null) {
      _ref.read(purchaseMessageProvider.notifier)
          .show('Purchases are not available on this device.');
      return;
    }
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      _ref.read(purchaseMessageProvider.notifier)
          .show('Could not start the purchase. Please try again.');
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _ref.read(purchaseMessageProvider.notifier)
          .show('Purchases are not available on this device.');
      return;
    }
    _ref.read(purchaseMessageProvider.notifier)
        .show('Checking your purchases…');
    try {
      await _iap.restorePurchases();
    } catch (_) {
      _ref.read(purchaseMessageProvider.notifier)
          .show('Could not check your purchases.');
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != FreeTier.proProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _ref.read(settingsProvider.notifier)
              .update(_ref.read(settingsProvider).copyWith(isPro: true));
          _ref.read(purchaseMessageProvider.notifier)
              .show('Pro unlocked. Thank you!');
        case PurchaseStatus.error:
          _ref.read(purchaseMessageProvider.notifier)
              .show('Purchase failed: ${purchase.error?.message ?? 'unknown error'}');
        case PurchaseStatus.canceled:
          _ref.read(purchaseMessageProvider.notifier).clear();
        case PurchaseStatus.pending:
          _ref.read(purchaseMessageProvider.notifier)
              .show('Waiting for the Play Store to confirm…');
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (_) {
          // The Play Store will retry completion on the next launch.
        }
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
