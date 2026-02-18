import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/product_model.dart';
import '../../services/store_service.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'cart_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final StoreService _storeService = StoreService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final List<String> _categories = [
    'All',
    'Fertilizers',
    'Seeds',
    'Tools',
    'Machines'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _storeService.getProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      setState(() => _products = products);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Store'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartScreen()),
                    );
                  },
                ),
                if (cart.totalItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.totalItems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category ||
                    (_selectedCategory == null && category == 'All');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _onCategorySelected(category);
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green,
                  ),
                );
              },
            ),
          ),

          // Product Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(product.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: SizedBox(
                                              height: 150,
                                              width: 150,
                                              child: product.image
                                                      .startsWith('http')
                                                  ? Image.network(product.image,
                                                      fit: BoxFit.cover)
                                                  : (product.image.startsWith(
                                                          'data:image')
                                                      ? Image.memory(
                                                          base64Decode(product
                                                              .image
                                                              .split(',')
                                                              .last),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : const Icon(Icons.image,
                                                          size: 80,
                                                          color: Colors.grey)),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(product.description,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  'Category: ${product.category}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star,
                                                      color: Colors.amber,
                                                      size: 16),
                                                  Text(' ${product.rating}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('Seller: ${product.seller}',
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic)),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Text(
                                                '₹${product.ourPrice}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                    fontSize: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '₹${product.originalPrice}',
                                                style: const TextStyle(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close')),
                                      ElevatedButton(
                                        onPressed: () {
                                          context
                                              .read<CartProvider>()
                                              .addItem(product.id);
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green),
                                        child: const Text('Add to Cart',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  Expanded(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: product.image
                                              .startsWith('data:image')
                                          ? Image.memory(
                                              base64Decode(product.image
                                                  .split(',')
                                                  .last),
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, o, s) =>
                                                  Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons
                                                          .image_not_supported)),
                                            )
                                          : Image.network(
                                              product.image,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, o, s) =>
                                                  Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons
                                                          .image_not_supported)),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '₹${product.ourPrice}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '₹${product.originalPrice}',
                                              style: const TextStyle(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 36,
                                          child: Consumer<CartProvider>(
                                            builder: (context, cart, child) {
                                              final qty = cart
                                                  .getItemQuantity(product.id);
                                              final isLoading = cart
                                                  .isItemLoading(product.id);

                                              if (isLoading) {
                                                return const Center(
                                                  child: SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.green),
                                                  ),
                                                );
                                              }

                                              if (qty > 0) {
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    InkWell(
                                                      onTap: () =>
                                                          cart.removeItem(
                                                              product.id),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: const Icon(
                                                            Icons.remove,
                                                            size: 16,
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                                    Text('$qty',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    InkWell(
                                                      onTap: () => cart
                                                          .addItem(product.id),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.green[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: const Icon(
                                                            Icons.add,
                                                            size: 16,
                                                            color:
                                                                Colors.green),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }

                                              return ElevatedButton(
                                                onPressed: () =>
                                                    cart.addItem(product.id),
                                                style: ElevatedButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  backgroundColor: Colors.green,
                                                ),
                                                child: const Text('Add to Cart',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white)),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
