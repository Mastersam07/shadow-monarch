import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/shadow_monarch_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShadowMonarchApp());
}

class ShadowMonarchApp extends StatelessWidget {
  const ShadowMonarchApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shadow Monarch',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
        ),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: GameWidget(
            game: ShadowMonarchGame(),
            loadingBuilder: (_) => const Center(
              child: Text(
                'Entering the Gate...',
                style: TextStyle(color: Color(0xFF9B6DD7), fontSize: 18, letterSpacing: 4),
              ),
            ),
          ),
        ),
      );
}
