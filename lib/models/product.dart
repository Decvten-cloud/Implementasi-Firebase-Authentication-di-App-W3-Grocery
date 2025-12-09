import 'package:flutter/material.dart';

class Product {
  final String id, name, img, tag;
  final double price, oldPrice;
  const Product(
    this.id,
    this.name,
    this.img,
    this.price,
    this.oldPrice,
    this.tag,
  );
}

const kPromoImages = [
  'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1600&q=80', // Fresh vegetables
  'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?auto=format&fit=crop&w=1600&q=80', // Food ingredients
  'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1600&q=80', // Vegetables
];

const kProducts = <Product>[
  Product(
    'p1',
    'Fresh Grapes',
    'https://images.unsplash.com/photo-1537640538966-79f369143f8f?auto=format&fit=crop&w=1200&q=80',
    10.9,
    12.9,
    'Fruits',
  ),
  Product(
    'p2',
    'Fresh Fish',
    'https://images.unsplash.com/photo-1615141982883-c7ad0e69fd62?auto=format&fit=crop&w=1200&q=80',
    10.9,
    12.0,
    'Fish',
  ),
  Product(
    'p3',
    'Tomatoes',
    'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=1200&q=80',
    10.9,
    12.0,
    'Vegetables',
  ),
  Product(
    'p4',
    'Fresh Chicken',
    'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=1200&q=80',
    10.9,
    11.9,
    'Chicken',
  ),
  Product(
    'p5',
    'Sweet Young Coconut',
    'https://plus.unsplash.com/premium_photo-1726718479272-10d3a9670cd3?auto=format&fit=crop&w=1200&q=80',
    4.0,
    8.9,
    'Fruits',
  ),
  Product(
    'p6',
    'Fresh Spinach',
    'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=1200&q=80',
    7.2,
    8.9,
    'Vegetables',
  ),
  Product(
    'p7',
    'Chocolate Chips',
    'https://images.unsplash.com/photo-1585503100597-d70e5dc45d81?auto=format&fit=crop&w=1200&q=80',
    12.0,
    12.0,
    'Bakery',
  ),
  // Additional products per category
  Product(
    'p8',
    'Black Grapes',
    'https://images.unsplash.com/photo-1596363505729-4190a9506133?auto=format&fit=crop&w=1200&q=80',
    6.5,
    8.0,
    'Fruits',
  ),
  Product(
    'p9',
    'Watermelon',
    'https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=1200&q=80',
    5.0,
    7.5,
    'Fruits',
  ),
  Product(
    'p10',
    'Orange',
    'https://images.unsplash.com/photo-1582979512210-99b6a53386f9?auto=format&fit=crop&w=1200&q=80',
    3.5,
    5.0,
    'Fruits',
  ),
  Product(
    'p11',
    'Pineapple',
    'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?auto=format&fit=crop&w=1200&q=80',
    4.5,
    6.0,
    'Fruits',
  ),
  Product(
    'p12',
    'Carrots',
    'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&w=1200&q=80',
    2.9,
    3.5,
    'Vegetables',
  ),
  Product(
    'p13',
    'Broccoli',
    'https://images.unsplash.com/photo-1584270354949-c26b0d5b4a0c?auto=format&fit=crop&w=1200&q=80',
    4.2,
    5.0,
    'Vegetables',
  ),
  Product(
    'p14',
    'Lettuce',
    'https://images.unsplash.com/photo-1622205313162-be1d5712a43f?auto=format&fit=crop&w=1200&q=80',
    2.0,
    3.0,
    'Vegetables',
  ),
  Product(
    'p15',
    'Sourdough Bread',
    'https://images.unsplash.com/photo-1597604391235-a7429b4b350c?auto=format&fit=crop&w=1200&q=80',
    3.0,
    4.5,
    'Bakery',
  ),
  Product(
    'p16',
    'Croissant',
    'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=1200&q=80',
    2.5,
    3.5,
    'Bakery',
  ),
  Product(
    'p17',
    'Cheddar Cheese',
    'https://images.unsplash.com/photo-1618164436241-4473940d1f5c?auto=format&fit=crop&w=1200&q=80',
    8.0,
    9.5,
    'Dairy',
  ),
  Product(
    'p18',
    'Whole Milk (1L)',
    'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=1200&q=80',
    1.8,
    2.5,
    'Dairy',
  ),
  Product(
    'p19',
    'Mushrooms (Box)',
    'https://images.unsplash.com/photo-1709111573644-867fb9b0d185?auto=format&fit=crop&w=1200&q=80',
    3.9,
    5.0,
    'Mushroom',
  ),
  Product(
    'p20',
    'Salmon Fillet',
    'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=1200&q=80',
    15.0,
    18.0,
    'Fish',
  ),
  Product(
    'p21',
    'Tuna Steak',
    'https://images.unsplash.com/photo-1645120091968-5f24af8eaff5?auto=format&fit=crop&w=1200&q=80',
    13.0,
    15.0,
    'Fish',
  ),
  Product(
    'p22',
    'Margherita Pizza',
    'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=1200&q=80',
    9.0,
    11.0,
    'Pizzas',
  ),
  Product(
    'p23',
    'Pepperoni Pizza',
    'https://plus.unsplash.com/premium_photo-1733259709671-9dbf22bf02cc?auto=format&fit=crop&w=1200&q=80',
    10.0,
    12.0,
    'Pizzas',
  ),
  Product(
    'p24',
    'Chicken Breast',
    'https://images.unsplash.com/photo-1682991136736-a2b44623eeba?auto=format&fit=crop&w=1200&q=80',
    6.5,
    8.0,
    'Chicken',
  ),
  Product(
    'p25',
    'Drumstick Pack',
    'https://images.unsplash.com/photo-1624364543842-b0472614eb68?auto=format&fit=crop&w=1200&q=80',
    5.5,
    7.0,
    'Chicken',
  ),
];

// Get products by category
List<Product> getProductsByCategory(String category) {
  return kProducts.where((product) => product.tag == category).toList();
}

// Get products by ids (useful for "popular" list)
List<Product> getProductsByIds(List<String> ids) {
  final map = {for (var p in kProducts) p.id: p};
  return ids.where((id) => map.containsKey(id)).map((id) => map[id]!).toList();
}

// Popular product ids to show on homepage (order matters)
const kPopularProductIds = ['p1', 'p9', 'p8', 'p7', 'p5'];

const kCategories = <(String, IconData, Color, String)>[
  ('Fruits', Icons.apple_rounded, Color(0xFF2DBBD8), '45 items'),
  ('Vegetables', Icons.local_florist_rounded, Color(0xFF4051B5), '45 items'),
  ('Bakery', Icons.bakery_dining_rounded, Color(0xFF4CAF50), '45 items'),
  ('Dairy', Icons.breakfast_dining_rounded, Color(0xFFE91E63), '45 items'),
  ('Mushroom', Icons.grass_rounded, Color(0xFFF4A261), '45 items'),
  ('Fish', Icons.set_meal_rounded, Color(0xFF2A9D8F), '45 items'),
  ('Pizzas', Icons.local_pizza_rounded, Color(0xFF8B4513), '45 items'),
  ('Chicken', Icons.lunch_dining_rounded, Color(0xFF9C27B0), '45 items'),
];
