import 'dart:convert';
import 'dart:typed_data';

class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final double originalPrice;
  final double ourPrice;
  final String seller;
  final String image;
  final int stock;
  final double rating;
  final Uint8List? decodedImage;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.originalPrice,
    required this.ourPrice,
    required this.seller,
    required this.image,
    required this.stock,
    required this.rating,
    this.decodedImage,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String img = json['image'] ?? '';
    Uint8List? decoded;
    if (img.startsWith('data:image')) {
      try {
        decoded = base64Decode(img.split(',').last);
      } catch (e) {
        print('Error decoding image for product ${json['name']}: $e');
      }
    }

    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      ourPrice: (json['our_price'] as num?)?.toDouble() ?? 0.0,
      seller: json['seller'] ?? '',
      image: img,
      stock: json['stock'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      decodedImage: decoded,
    );
  }
}

class CartItem {
  final Product product;
  final int quantity;
  final double itemTotal;

  CartItem({
    required this.product,
    required this.quantity,
    required this.itemTotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 0,
      itemTotal: (json['item_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Cart {
  final List<CartItem> items;
  final double totalPrice;
  final int totalItems;

  Cart({
    required this.items,
    required this.totalPrice,
    required this.totalItems,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<CartItem> itemsList = list.map((i) => CartItem.fromJson(i)).toList();

    return Cart(
      items: itemsList,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      totalItems: json['total_items'] ?? 0,
    );
  }
}
