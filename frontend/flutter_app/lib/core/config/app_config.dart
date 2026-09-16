/// Runtime configuration for the Flutter client.
///
/// Pass a backend URL at build/run time with:
/// `flutter run -d chrome --dart-define=AGENTRAG_API_URL=http://localhost:5027`
class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    "AGENTRAG_API_URL",
    defaultValue: "http://localhost:5027",
  );
}
