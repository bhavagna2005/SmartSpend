import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://uokdqbqakpogbpyxkooa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVva2RxYnFha3BvZ2JweXhrb29hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyODM2MDQsImV4cCI6MjA4Nzg1OTYwNH0.FIXWTkv5_ixT35-75bzvOKfGwuQ7FU11KRlrb4hrbxA',
  );
  
  final supabase = Supabase.instance.client;
  final data = await supabase.from('goals').select('*').limit(1);
  print(data);
}
