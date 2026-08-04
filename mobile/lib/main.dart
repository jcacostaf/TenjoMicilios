import 'package:flutter/material.dart';

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
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining, size: 96, color: Colors.deepOrange),
              SizedBox(height: 16),
              Text(
                'Bienvenido a TenjoMicilios',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'App de domicilios para Tenjo',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
