class AppConfig {
  /// Production VPS REST API behind HTTPS Nginx reverse proxy.
  /// Override locally with: flutter run --dart-define=MORFIN_API_URL=http://10.0.2.2:4200
  static const String apiBaseUrl = String.fromEnvironment(
    'MORFIN_API_URL',
    defaultValue: 'https://nayakacode.web.id/morfin-api',
  );

  /// Google OAuth Client ID (Web / iOS) — set via --dart-define=GOOGLE_CLIENT_ID=...
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  /// Google OAuth Web/Server Client ID used by Android to mint ID tokens for VPS backend.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
