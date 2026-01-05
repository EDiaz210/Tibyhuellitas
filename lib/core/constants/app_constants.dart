import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration (loaded from .env)
  static String get supabaseUrl => 
    (dotenv.isEveryDefined(['SUPABASE_URL']) ? dotenv.env['SUPABASE_URL'] : null) ?? 
    'https://lpdvoumenxcfqkvdhyjz.supabase.co';
  
  static String get supabaseAnonKey => 
    (dotenv.isEveryDefined(['SUPABASE_ANON_KEY']) ? dotenv.env['SUPABASE_ANON_KEY'] : null) ?? 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxwZHZvdW1lbnhjZnFrdmRoeWp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5MjAzMTEsImV4cCI6MjA4MTQ5NjMxMX0.BZepkdIlFVY8qly9MiRuYNTzUBddsJHdCjX5yWOJsYI';

  // Deep Link Configuration
  static const String appScheme = 'loginpro';

  // Vercel URLs (loaded from .env)
  static String get vercelBaseUrl => 
    (dotenv.isEveryDefined(['VERCEL_BASE_URL']) ? dotenv.env['VERCEL_BASE_URL'] : null) ?? 
    'https://rapi-login.vercel.app';
  static const String emailVerificationPath = '/verify-email';
  static const String resetPasswordPath = '/reset-password';

  // Error Messages
  static const String networkError = 'Sin conexión a internet';
  static const String serverError = 'Error del servidor';
  static const String authError = 'Error de autenticación';
  static const String unknownError = 'Error desconocido';
}
