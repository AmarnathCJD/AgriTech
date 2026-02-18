import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/product_model.dart';
import '../../services/store_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final StoreService _storeService = StoreService();
  Cart? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() => _isLoading = true);
    try {
      final cart = await _storeService.getCart();
      setState(() => _cart = cart);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItem(String productId) async {
    final success = await _storeService.removeFromCart(productId);
    if (success) {
      _fetchCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart')),
      );
    }
  }

  Future<void> _checkout() async {
    final success = await _storeService.checkout();
    if (success) {
      _fetchCart(); // Will be empty
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.items.isEmpty
              ? const Center(
                  child: Text('Your cart is empty',
                      style: TextStyle(fontSize: 18)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cart!.items.length,
                        itemBuilder: (context, index) {
                          final item = _cart!.items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: item.product.image
                                      .startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(
                                          item.product.image.split(',').last),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, o, s) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : Image.network(
                                      item.product.image,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, o, s) =>
                                          const Icon(Icons.broken_image),
                                    ),
                              title: Text(item.product.name),
                              subtitle: Text(
                                  'Qty: ${item.quantity}  |  ₹${item.itemTotal}'),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text('₹${_cart!.totalPrice}',
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.green[700],
                              ),
                              child: const Text('Proceed to Buy',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
