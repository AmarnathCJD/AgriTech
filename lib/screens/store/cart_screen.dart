import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/product_model.dart';
import '../../services/store_service.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final StoreService _storeService = StoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  Future<void> _removeItem(String productId) async {
    final success = await _storeService.removeFromCart(productId);
    if (success && mounted) {
      context.read<CartProvider>().fetchCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart')),
      );
    }
  }

  Future<void> _checkout() async {
    final success = await _storeService.checkout();
    if (success && mounted) {
      context.read<CartProvider>().fetchCart();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Order placed successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isCartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cart.cartList.isEmpty) {
            return const Center(
                child:
                    Text('Your cart is empty', style: TextStyle(fontSize: 18)));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.cartList.length,
                  itemBuilder: (context, index) {
                    final item = cart.cartList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: item.product.image.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(
                                      item.product.image.split(',').last),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) =>
                                      const Icon(Icons.broken_image),
                                )
                              : Image.network(
                                  item.product.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) =>
                                      const Icon(Icons.broken_image),
                                ),
                        ),
                        title: Text(item.product.name),
                        subtitle: Text(
                            'Qty: ${item.quantity}  |  ₹${item.itemTotal}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(item.product.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('₹${cart.cartTotal}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _checkout,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green[700],
                        ),
                        child: const Text('Proceed to Buy',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
