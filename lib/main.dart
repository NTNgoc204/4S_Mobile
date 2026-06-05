import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'app.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const MyApp());
}
