/// Application Configuration
/// This file contains environment-specific configuration values
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vendor.trippechalo.in', // Production default
  );

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yxulmlparmwdbxhbvkcp.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4dWxtbHBhcm13ZGJ4aGJ2a2NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2OTI1NzcsImV4cCI6MjA2OTI2ODU3N30.R3VGfQCD-ysEE-yTUZ7KOeqABSw-EHGXWEXxEgTXVOA',
  );

  // Environment
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  // Debug mode
  static bool get isDebugMode => !isProduction;
}
