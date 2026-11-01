import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'config.dart';

/// Único anuncio de Aure: un video corto con recompensa que el usuario
/// elige ver para desbloquear UNA descarga gratuita. No hay banners ni
/// anuncios que salten en ningún otro lugar de la app.
class AdsService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Muestra el anuncio y devuelve true si el usuario ganó la recompensa.
  Future<bool> showRewarded() async {
    await init();
    final loaded = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: AureConfig.admobRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    final ad = await loaded.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => null,
    );
    // Si no hay anuncio disponible (sin internet o sin inventario),
    // no castigamos al usuario: la descarga sigue.
    if (ad == null) return true;

    final done = Completer<bool>();
    var rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!done.isCompleted) done.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        if (!done.isCompleted) done.complete(true);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => rewarded = true);
    return done.future;
  }
}
