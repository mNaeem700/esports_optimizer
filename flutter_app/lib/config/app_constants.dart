class AppConstants {
  // Point these at your deployed backend (see backend/README).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator -> host localhost
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://10.0.2.2:3000',
  );

  static const List<String> supportedGames = [
    'PUBG Mobile',
    'Call of Duty Mobile',
    'Valorant Mobile',
    'Fortnite Mobile',
  ];
}
