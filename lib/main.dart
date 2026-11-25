import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
await Supabase.initialize(
url: 'https://opurxdxtyhvftgrvtoez.supabase.co',
publishableKey: 'sb_publishable_pVYYvZf9OpPQd8l-1FyRjQ_oqyLccjT',
);
runApp(const MyApp());
}
class MyApp extends StatelessWidget {
const MyApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'SensorTrack',
home: const HomePage(),
);
}
}