/// Claves de servicios externos. Se pasan al compilar, nunca se escriben en el código:
///
///   flutter run \
///     --dart-define=ACR_HOST=identify-us-west-2.acrcloud.com \
///     --dart-define=ACR_KEY=xxxx --dart-define=ACR_SECRET=yyyy \
///     --dart-define=JAMENDO_CLIENT_ID=zzzz \
///     --dart-define=ADMOB_REWARDED_ID=ca-app-pub-.../...
///
/// Sin claves, la app funciona igual en modo offline; las funciones en línea
/// muestran un aviso amable.
class AureConfig {
  static const acrHost = String.fromEnvironment('ACR_HOST');
  static const acrKey = String.fromEnvironment('ACR_KEY');
  static const acrSecret = String.fromEnvironment('ACR_SECRET');
  static const jamendoClientId = String.fromEnvironment('JAMENDO_CLIENT_ID');

  /// ID de prueba oficial de Google si no se configura uno propio.
  static const admobRewardedId = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  static bool get hasAcr =>
      acrHost.isNotEmpty && acrKey.isNotEmpty && acrSecret.isNotEmpty;
  static bool get hasJamendo => jamendoClientId.isNotEmpty;
}
