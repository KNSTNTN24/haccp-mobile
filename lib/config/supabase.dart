import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = 'https://rszrggreuarvodcqeqrj.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzenJnZ3JldWFydm9kY3FlcXJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1NzY2NzYsImV4cCI6MjA4OTE1MjY3Nn0.dwD1MJcMOc9w1IP4T15ep1mYHVARW6eJPNArn4oGmH0';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
