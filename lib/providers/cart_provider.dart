import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/store_service.dart';

class CartProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();

  // Map of productId -> quantity
  Map<String, int> _items = {};
  List<CartItem> _cartItemsList = [];
  double _cartTotal = 0.0;

  // Set of productIds currently being updated (loading state)
  final Set<String> _loadingItems = {};

  bool _isCartLoading = false;

  Map<String, int> get items => _items;
  List<CartItem> get cartList => _cartItemsList;
  double get cartTotal => _cartTotal;
  bool get isCartLoading => _isCartLoading;

  int get totalItems => _items.values.fold(0, (sum, qty) => sum + qty);

  bool isItemLoading(String productId) => _loadingItems.contains(productId);

  int getItemQuantity(String productId) => _items[productId] ?? 0;

  Future<void> fetchCart() async {
    _isCartLoading = true;
    // notifyListeners(); // Avoid rebuilding immediately if not needed, or do it to show global loading
    // Better to just set flag and notify at end, or use separate loading widget
    // But since we want counter update on load...
    notifyListeners();

    try {
      final cart = await _storeService.getCart();
      _cartItemsList = cart.items;
      _cartTotal = cart.totalPrice;
      _items.clear();
      for (var item in cart.items) {
        _items[item.product.id] = item.quantity;
      }
    } catch (e) {
      print("Error fetching cart: $e");
    } finally {
      _isCartLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(String productId) async {
    if (_loadingItems.contains(productId)) return;

    _loadingItems.add(productId);
    notifyListeners();

    try {
      // Optimistic update? Or wait for response?
      // "stops when the response is received from backend that item is added successfully"
      // So wait for response.
      final success = await _storeService.addToCart(productId, 1);
      if (success) {
        _items[productId] = (_items[productId] ?? 0) + 1;
        // Optionally fetchCart to sync perfectly
        // await fetchCart();
      }
    } catch (e) {
      print("Error adding item: $e");
    } finally {
      _loadingItems.remove(productId);
      notifyListeners();
    }
  }

  Future<void> removeItem(String productId) async {
    if (_loadingItems.contains(productId)) return;

    final currentQty = _items[productId] ?? 0;
    if (currentQty <= 0) return;

    _loadingItems.add(productId);
    notifyListeners();

    try {
      // If quantity is 1, remove entirely?
      // Use removeFromCart if we want to remove line item, or if quantity becomes 0.
      bool success;
      if (currentQty == 1) {
        success = await _storeService.removeFromCart(productId);
        if (success) _items.remove(productId);
      } else {
        // Try adding -1 to decrement
        success = await _storeService.addToCart(productId, -1);
        if (success) _items[productId] = currentQty - 1;
      }

      // Sync to be sure
      // await fetchCart();
    } catch (e) {
      print("Error removing item: $e");
    } finally {
      _loadingItems.remove(productId);
      notifyListeners();
    }
  }
}
