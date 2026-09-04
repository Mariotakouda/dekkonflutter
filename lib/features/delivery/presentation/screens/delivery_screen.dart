import 'package:flutter/material.dart';

class DeliveryScreen extends StatelessWidget {
  final String deliveryId;

  const DeliveryScreen({super.key, required this.deliveryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Livraison $deliveryId')),
    );
  }
}