import 'package:flutter/material.dart';
import 'features/restaurant/store_selector_screen.dart';

void main() {
  runApp(const TenjoMiciliosApp());
}

class TenjoMiciliosApp extends StatelessWidget {
  const TenjoMiciliosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TenjoMicilios',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TenjoMicilios'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delivery_dining, size: 96, color: Colors.deepOrange),
              const SizedBox(height: 16),
              const Text(
                'Bienvenido a TenjoMicilios',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'App de domicilios para Tenjo',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.storefront),
                label: const Text('Soy un restaurante'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StoreSelectorScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
