import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => throw UnimplementedError(
    'SupabaseClient wurde nicht bereitgestellt. Bitte in main.dart überschreiben.',
  ),
);
