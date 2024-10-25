import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EcomScreen extends StatefulWidget {
  @override
  _EcomScreenState createState() => _EcomScreenState();
}

class _EcomScreenState extends State<EcomScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  bool isFocused = false;
  late AnimationController _controller;
  List<Product> cartItems = [];
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  String? userUid; // Variable to store user uid

  final List<Product> products = [
    Product(
      imageUrl:
      'https://i-cf65.ch-static.com/content/dam/cf-consumer-healthcare/health-professionals/en_US/fsa-hsa/Nicorette_Gum970x415.jpg?auto=format',
      productName: 'Nicorette Gum 4mg',
      description: 'Fruit chill flavor, 20 pieces',
      price: '\$20.00',
    ),
    Product(
      imageUrl:
      'https://i-cf65.ch-static.com/content/dam/cf-consumer-healthcare/health-professionals/en_US/fsa-hsa/Nicoderm_CQ_970x415.jpg?auto=format',
      productName: 'Nicoderm CQ Patches',
      description: '21 mg, 14 patches',
      price: '\$35.00',
    ),
    Product(
      imageUrl:
      'https://i-cf65.ch-static.com/content/dam/cf-consumer-healthcare/health-professionals/en_US/smokers-health/GSK_GEP_15_750x421.jpg?auto=format',
      productName: 'Nicorette Lozenges',
      description: '2mg, Mint flavor, 40 lozenges',
      price: '\$25.00',
    ),
    Product(
      imageUrl:
      'https://cdn11.bigcommerce.com/s-ski71ecyqq/images/stencil/960w/products/209/752/000307667750317_C1C1__80887.1679925043.jpg?c=1',
      productName: 'Nicabate Gum',
      description: '2mg, Fresh Mint, 100 pieces',
      price: '\$18.00',
    ),
    Product(
      imageUrl:
      'https://i-cf65.ch-static.com/content/dam/cf-consumer-healthcare/health-professionals/en_US/fsa-hsa/Nicorette_Coated_Lozenge_970X415%20MISSIZED.jpg?auto=format',
      productName: 'Nicorette Lozenge',
      description: '4 mg, 10 patches',
      price: '\$30.00',
    ),
    Product(
      imageUrl:
      'https://static.standard.co.uk/2023/12/27/13/57/Boots%20NicAssist%20Translucent%2025mg%20Patch%20Step%201.JPG.jpg?quality=75&auto=webp&width=640',
      productName: 'NicAssist Inhaler',
      description: '25 mg per dose, 30 refills',
      price: '\$40.00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _getUserUid(); // Fetch user uid when the screen initializes
  }

  Future<void> _getUserUid() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userUid = user.uid; // Store the user's uid
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    setState(() {
      cartItems.add(product);
    });
  }

  void _showOrderHistory() async {
    if (userUid == null) {
      _showSnackbar('User is not available. Please log in.');
      return;
    }

    try {
      // Fetch user's order history from Firestore without ordering
      final orderHistory = await FirebaseFirestore.instance
          .collection('orders')
          .where('userUid', isEqualTo: userUid)
          .get();

      if (orderHistory.docs.isEmpty) {
        _showSnackbar('No order history found.');
        return;
      }

      // Locally sort the order history by 'timestamp' in descending order
      final sortedOrderHistory = orderHistory.docs
          .where((doc) => doc.data().containsKey('timestamp')) // Ensure 'timestamp' field exists
          .toList()
        ..sort((a, b) {
          Timestamp timestampA = a['timestamp'];
          Timestamp timestampB = b['timestamp'];
          return timestampB.compareTo(timestampA); // Sort in descending order
        });

      // Show the order history in a dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Order History',
              style: TextStyle(
                color: Color(0xFF1c92d2), // Custom color for title
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedOrderHistory.map((doc) {
                  final orderData = doc.data();
                  final productsList = orderData['products'] as List<dynamic>;
                  final timestamp = (orderData['timestamp'] as Timestamp).toDate();

                  // Format the date using intl
                  final formattedDate = DateFormat('d/M/y').format(timestamp);

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 10), // Space between cards
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Color(0xFF1c92d2), // Color for the icon
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                // Use Expanded to prevent overflow in this Row
                                child: Text(
                                  'Time : $formattedDate',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1c92d2),
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Products:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 5),
                          ...productsList.map((product) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_bag, size: 18, color: Colors.black54),
                                  SizedBox(width: 8),
                                  Expanded( // Use Expanded here to prevent overflow of product names
                                    child: Text(
                                      '${product['productName']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis, // Prevent text overflow
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${product['price']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1c92d2),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF1c92d2)),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showSnackbar('Failed to load order history. Please try again later.');
      print('Error fetching order history: $e');
    }
  }



  void _proceedToCheckout() {
    if (cartItems.isEmpty) {
      _showSnackbar('Your cart is empty!');
      return;
    }

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Checkout'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // Form key for validation
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Products:'),
                  ...cartItems
                      .map(
                          (item) => Text('${item.productName} - ${item.price}'))
                      .toList(),
                  TextFormField(
                    controller: fullNameController,
                    decoration: InputDecoration(labelText: 'Full Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Full Name is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone Number is required';
                      }
                      if (value.length < 10) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Address'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: postalCodeController,
                    decoration: InputDecoration(labelText: 'Postal Code'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Postal Code is required';
                      }
                      if (value.length < 5) {
                        return 'Enter a valid postal code';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _placeOrder();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _placeOrder() async {
    if (userUid == null) {
      _showSnackbar('User is not available. Please log in.');
      return;
    }

    List<Map<String, dynamic>> orderDetails = cartItems.map((item) {
      return {
        'productName': item.productName,
        'description': item.description,
        'price': item.price,
      };
    }).toList();

    await FirebaseFirestore.instance.collection('orders').add({
      'userUid': userUid,
      'products': orderDetails,
      'address': addressController.text,
      'phoneNumber': phoneController.text,
      'fullName': fullNameController.text,
      'postalCode': postalCodeController.text,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(), // Store order placement time
    });

    // Clear fields and cart after placing order
    setState(() {
      cartItems.clear();
      fullNameController.clear();
      phoneController.clear();
      addressController.clear();
      postalCodeController.clear();
    });

    _showSnackbar('Order placed successfully!');
  }

  void _removeFromCart(Product product) {
    setState(() {
      cartItems.remove(product);
      _showSnackbar('${product.productName} removed from cart.',
          duration: Duration(seconds: 2));
    });
  }

  void _showSnackbar(String message, {Duration duration = const Duration(seconds: 4)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration, // Use the passed duration or default to 4 seconds
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((product) {
      return product.productName
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Quit Smoking Products', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: Color(0xFF1c92d2), // Primary color for futuristic feel
        automaticallyImplyLeading: false, // Remove the back button
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  _showOrderHistory(); // Show order history when pressed
                },
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 24, // Set a minimum width to accommodate two digits
                      minHeight: 24, // Set a minimum height
                    ),
                    child: Center(
                      child: Text(
                        '${cartItems.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14, // Increase font size for better readability
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.remove_circle, color: Colors.white),
            onPressed: () {
              if (cartItems.isNotEmpty) {
                _removeFromCart(cartItems.last);
              } else {
                _showSnackbar('Your cart is empty!');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isFocused ? 60 : 48,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isFocused = true;
                  });
                  _controller.forward();
                },
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: isFocused ? 1.1 : 1.0)
                      .animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    onEditingComplete: () {
                      setState(() {
                        isFocused = false;
                      });
                      _controller.reverse();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF1E3A8A)),
                      filled: true,
                      fillColor: Color(0xFFE0F2FE), // Light blue shade
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(top: 16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                  MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(
                    imageUrl: product.imageUrl,
                    productName: product.productName,
                    description: product.description,
                    price: product.price,
                    onAddToCart: () => _addToCart(product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${cartItems.length} items in cart',
              style: TextStyle(fontSize: 16.0, color: Colors.black54),
            ),
            ElevatedButton(
              onPressed: () {
                _proceedToCheckout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1c92d2),
                foregroundColor: Colors.white, // Set text color to white
              ),
              child: Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  final String imageUrl;
  final String productName;
  final String description;
  final String price;

  Product({
    required this.imageUrl,
    required this.productName,
    required this.description,
    required this.price,
  });
}

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final String description;
  final String price;
  final VoidCallback onAddToCart;

  ProductCard({
    required this.imageUrl,
    required this.productName,
    required this.description,
    required this.price,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Color(0xFF1c92d2).withOpacity(0.5),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1c92d2), Color(0xFFf2fcfe)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: 6.0),
                child: Column(
                  children: [
                    Text(
                      productName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Expanded( // Expanded here will ensure the text fits within available space
                      child: Text(
                        description,
                        style: TextStyle(fontSize: 12.0, color: Colors.white70),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0),
              child: ElevatedButton(
                onPressed: onAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1c92d2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
