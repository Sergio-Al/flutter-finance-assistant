import 'package:flutter/material.dart';

/// Centralized icon mapping for categories.
///
/// This map provides a consistent icon lookup across the app
/// for both system and custom user-created categories.
class IconConstants {
  IconConstants._();

  /// Default fallback icon when icon name is not found
  static const IconData defaultCategoryIcon = Icons.account_balance_wallet;

  /// Get IconData from icon name string
  static IconData getIcon(String? iconName) {
    if (iconName == null) return defaultCategoryIcon;
    return iconMap[iconName] ?? defaultCategoryIcon;
  }

  /// Check if an icon name is valid
  static bool isValidIcon(String iconName) => iconMap.containsKey(iconName);

  /// Get all available icon names
  static List<String> get availableIconNames => iconMap.keys.toList();

  /// Get icons grouped by category for picker UI
  static Map<String, List<MapEntry<String, IconData>>> get groupedIcons => {
    'Finance': iconMap.entries
        .where((e) => _financeIcons.contains(e.key))
        .toList(),
    'Food & Drink': iconMap.entries
        .where((e) => _foodIcons.contains(e.key))
        .toList(),
    'Shopping': iconMap.entries
        .where((e) => _shoppingIcons.contains(e.key))
        .toList(),
    'Transport': iconMap.entries
        .where((e) => _transportIcons.contains(e.key))
        .toList(),
    'Entertainment': iconMap.entries
        .where((e) => _entertainmentIcons.contains(e.key))
        .toList(),
    'Health & Wellness': iconMap.entries
        .where((e) => _healthIcons.contains(e.key))
        .toList(),
    'Home & Living': iconMap.entries
        .where((e) => _homeIcons.contains(e.key))
        .toList(),
    'Work & Education': iconMap.entries
        .where((e) => _workIcons.contains(e.key))
        .toList(),
    'Sports & Outdoors': iconMap.entries
        .where((e) => _sportsIcons.contains(e.key))
        .toList(),
    'Other': iconMap.entries.where((e) => _otherIcons.contains(e.key)).toList(),
  };

  // Icon categories for grouping
  static const _financeIcons = {
    'account_balance',
    'attach_money',
    'credit_card',
    'local_atm',
    'monetization_on',
    'payment',
    'payments',
    'percent',
    'receipt_long',
    'savings',
    'trending_up',
    'wallet',
  };

  static const _foodIcons = {
    'cake',
    'coffee',
    'fastfood',
    'icecream',
    'liquor',
    'local_bar',
    'local_cafe',
    'local_pizza',
    'lunch_dining',
    'menu_book',
    'outdoor_grill',
    'restaurant',
    'restaurant_menu',
    'wine_bar',
  };

  static const _shoppingIcons = {
    'checkroom',
    'diamond',
    'dry_cleaning',
    'inventory',
    'local_mall',
    'redeem',
    'shopping_bag',
    'shopping_cart',
    'storefront',
    'style',
  };

  static const _transportIcons = {
    'directions_bike',
    'directions_bus',
    'directions_car',
    'flight',
    'local_gas_station',
    'local_parking',
    'local_shipping',
    'local_taxi',
    'luggage',
    'train',
    'two_wheeler',
  };

  static const _entertainmentIcons = {
    'celebration',
    'emoji_events',
    'festival',
    'headphones',
    'local_movies',
    'mic',
    'movie',
    'music_note',
    'nightlife',
    'piano',
    'sports_esports',
    'subscriptions',
    'theater_comedy',
    'toys',
    'videogame_asset',
  };

  static const _healthIcons = {
    'fitness_center',
    'healing',
    'local_hospital',
    'local_pharmacy',
    'medical_services',
    'psychology',
    'self_improvement',
    'smoke_free',
    'spa',
  };

  static const _homeIcons = {
    'chair',
    'cleaning_services',
    'cottage',
    'electric_bolt',
    'handyman',
    'home',
    'house',
    'key',
    'kitchen',
    'lightbulb',
    'local_laundry_service',
    'water_drop',
    'weekend',
    'wifi',
    'yard',
  };

  static const _workIcons = {
    'book',
    'brush',
    'build',
    'business',
    'computer',
    'construction',
    'engineering',
    'gavel',
    'laptop',
    'local_library',
    'print',
    'school',
    'science',
    'work',
  };

  static const _sportsIcons = {
    'beach_access',
    'golf_course',
    'hiking',
    'park',
    'pool',
    'sailing',
    'snowboarding',
    'sports',
    'sports_bar',
    'sports_basketball',
    'sports_football',
    'sports_soccer',
    'sports_tennis',
    'surfing',
  };

  static const _otherIcons = {
    'camera_alt',
    'card_giftcard',
    'category',
    'child_care',
    'cloud',
    'extension',
    'face',
    'family_restroom',
    'favorite',
    'forest',
    'hotel',
    'local_florist',
    'map',
    'more_horiz',
    'palette',
    'pets',
    'phone',
    'phone_android',
    'photo_camera',
    'real_estate_agent',
    'replay',
    'rocket_launch',
    'volunteer_activism',
    'watch',
  };

  /// Main icon map from string names to IconData
  static const Map<String, IconData> iconMap = {
    // Finance
    'account_balance': Icons.account_balance,
    'attach_money': Icons.attach_money,
    'credit_card': Icons.credit_card,
    'local_atm': Icons.local_atm,
    'monetization_on': Icons.monetization_on,
    'payment': Icons.payment,
    'payments': Icons.payments,
    'percent': Icons.percent,
    'receipt_long': Icons.receipt_long,
    'savings': Icons.savings,
    'trending_up': Icons.trending_up,
    'wallet': Icons.wallet,

    // Food & Drink
    'cake': Icons.cake,
    'coffee': Icons.coffee,
    'fastfood': Icons.fastfood,
    'icecream': Icons.icecream,
    'liquor': Icons.liquor,
    'local_bar': Icons.local_bar,
    'local_cafe': Icons.local_cafe,
    'local_pizza': Icons.local_pizza,
    'lunch_dining': Icons.lunch_dining,
    'menu_book': Icons.menu_book,
    'outdoor_grill': Icons.outdoor_grill,
    'restaurant': Icons.restaurant,
    'restaurant_menu': Icons.restaurant_menu,
    'wine_bar': Icons.wine_bar,

    // Shopping
    'checkroom': Icons.checkroom,
    'diamond': Icons.diamond,
    'dry_cleaning': Icons.dry_cleaning,
    'inventory': Icons.inventory,
    'local_mall': Icons.local_mall,
    'redeem': Icons.redeem,
    'shopping_bag': Icons.shopping_bag,
    'shopping_cart': Icons.shopping_cart,
    'storefront': Icons.storefront,
    'style': Icons.style,

    // Transport
    'directions_bike': Icons.directions_bike,
    'directions_bus': Icons.directions_bus,
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'local_gas_station': Icons.local_gas_station,
    'local_parking': Icons.local_parking,
    'local_shipping': Icons.local_shipping,
    'local_taxi': Icons.local_taxi,
    'luggage': Icons.luggage,
    'train': Icons.train,
    'two_wheeler': Icons.two_wheeler,

    // Entertainment
    'celebration': Icons.celebration,
    'emoji_events': Icons.emoji_events,
    'festival': Icons.festival,
    'headphones': Icons.headphones,
    'local_movies': Icons.local_movies,
    'mic': Icons.mic,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'nightlife': Icons.nightlife,
    'piano': Icons.piano,
    'sports_esports': Icons.sports_esports,
    'subscriptions': Icons.subscriptions,
    'theater_comedy': Icons.theater_comedy,
    'toys': Icons.toys,
    'videogame_asset': Icons.videogame_asset,

    // Health & Wellness
    'fitness_center': Icons.fitness_center,
    'healing': Icons.healing,
    'local_hospital': Icons.local_hospital,
    'local_pharmacy': Icons.local_pharmacy,
    'medical_services': Icons.medical_services,
    'psychology': Icons.psychology,
    'self_improvement': Icons.self_improvement,
    'smoke_free': Icons.smoke_free,
    'spa': Icons.spa,

    // Home & Living
    'chair': Icons.chair,
    'cleaning_services': Icons.cleaning_services,
    'cottage': Icons.cottage,
    'electric_bolt': Icons.electric_bolt,
    'handyman': Icons.handyman,
    'home': Icons.home,
    'house': Icons.house,
    'key': Icons.key,
    'kitchen': Icons.kitchen,
    'lightbulb': Icons.lightbulb,
    'local_laundry_service': Icons.local_laundry_service,
    'water_drop': Icons.water_drop,
    'weekend': Icons.weekend,
    'wifi': Icons.wifi,
    'yard': Icons.yard,

    // Work & Education
    'book': Icons.book,
    'brush': Icons.brush,
    'build': Icons.build,
    'business': Icons.business,
    'computer': Icons.computer,
    'construction': Icons.construction,
    'engineering': Icons.engineering,
    'gavel': Icons.gavel,
    'laptop': Icons.laptop,
    'local_library': Icons.local_library,
    'print': Icons.print,
    'school': Icons.school,
    'science': Icons.science,
    'work': Icons.work,

    // Sports & Outdoors
    'beach_access': Icons.beach_access,
    'golf_course': Icons.golf_course,
    'hiking': Icons.hiking,
    'park': Icons.park,
    'pool': Icons.pool,
    'sailing': Icons.sailing,
    'snowboarding': Icons.snowboarding,
    'sports': Icons.sports,
    'sports_bar': Icons.sports_bar,
    'sports_basketball': Icons.sports_basketball,
    'sports_football': Icons.sports_football,
    'sports_soccer': Icons.sports_soccer,
    'sports_tennis': Icons.sports_tennis,
    'surfing': Icons.surfing,

    // Other
    'camera_alt': Icons.camera_alt,
    'card_giftcard': Icons.card_giftcard,
    'category': Icons.category,
    'child_care': Icons.child_care,
    'cloud': Icons.cloud,
    'extension': Icons.extension,
    'face': Icons.face,
    'family_restroom': Icons.family_restroom,
    'favorite': Icons.favorite,
    'forest': Icons.forest,
    'hotel': Icons.hotel,
    'local_florist': Icons.local_florist,
    'local_grocery_store': Icons.local_grocery_store,
    'map': Icons.map,
    'more_horiz': Icons.more_horiz,
    'palette': Icons.palette,
    'pets': Icons.pets,
    'phone': Icons.phone,
    'phone_android': Icons.phone_android,
    'photo_camera': Icons.photo_camera,
    'real_estate_agent': Icons.real_estate_agent,
    'replay': Icons.replay,
    'rocket_launch': Icons.rocket_launch,
    'volunteer_activism': Icons.volunteer_activism,
    'watch': Icons.watch,
  };
}
