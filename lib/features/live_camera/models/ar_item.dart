import 'package:flutter/material.dart';

enum ArCategory {
  glasses('Glasses', Icons.visibility_rounded),
  lips('Lips', Icons.face_retouching_natural),
  earrings('Earrings', Icons.circle_outlined),
  head('Head', Icons.headphones_rounded),
  beard('Beard', Icons.face_rounded),
  eyes('Eyes', Icons.remove_red_eye_rounded),
  hair('Hair', Icons.brush_rounded);

  const ArCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum ArRegion { eyes, lips, ears, head, beard, hairTop }

class ArItem {
  final String name;
  final ArCategory category;
  final ArRegion region;
  final Color primaryColor;
  final Color accentColor;

  const ArItem({
    required this.name,
    required this.category,
    required this.region,
    required this.primaryColor,
    required this.accentColor,
  });
}

class ArCatalog {
  static const Map<String, List<ArItem>> items = {
    'Glasses': [
      ArItem(name: 'Aviator', category: ArCategory.glasses, region: ArRegion.eyes, primaryColor: Color(0xFFb8860b), accentColor: Color(0xFF8b6914)),
      ArItem(name: 'Wayfarer', category: ArCategory.glasses, region: ArRegion.eyes, primaryColor: Color(0xFF1a1a1a), accentColor: Color(0xFF4a4a4a)),
      ArItem(name: 'Round', category: ArCategory.glasses, region: ArRegion.eyes, primaryColor: Color(0xFF8b4513), accentColor: Color(0xFF6b3410)),
      ArItem(name: 'Cat-Eye', category: ArCategory.glasses, region: ArRegion.eyes, primaryColor: Color(0xFFc71585), accentColor: Color(0xFF8b0057)),
      ArItem(name: 'Rimless', category: ArCategory.glasses, region: ArRegion.eyes, primaryColor: Color(0xFFc0c0c0), accentColor: Color(0xFF808080)),
      ArItem(name: 'Sport', category: ArCategory.glasses, region: ArRegion.eyes, primaryColor: Color(0xFF0055cc), accentColor: Color(0xFF00008b)),
    ],
    'Lips': [
      ArItem(name: 'Rose', category: ArCategory.lips, region: ArRegion.lips, primaryColor: Color(0xFFf48fb1), accentColor: Color(0xFFec407a)),
      ArItem(name: 'Coral', category: ArCategory.lips, region: ArRegion.lips, primaryColor: Color(0xFFff7043), accentColor: Color(0xFFe64a19)),
      ArItem(name: 'Nude', category: ArCategory.lips, region: ArRegion.lips, primaryColor: Color(0xFFd2a679), accentColor: Color(0xFFbc8c5a)),
      ArItem(name: 'Cherry', category: ArCategory.lips, region: ArRegion.lips, primaryColor: Color(0xFFc62828), accentColor: Color(0xFF7f0000)),
      ArItem(name: 'Berry', category: ArCategory.lips, region: ArRegion.lips, primaryColor: Color(0xFF8e24aa), accentColor: Color(0xFF4a148c)),
      ArItem(name: 'Gloss', category: ArCategory.lips, region: ArRegion.lips, primaryColor: Color(0xFFf06292), accentColor: Color(0xFFe91e63)),
    ],
    'Earrings': [
      ArItem(name: 'Stud', category: ArCategory.earrings, region: ArRegion.ears, primaryColor: Color(0xFFffd700), accentColor: Color(0xFFb8860b)),
      ArItem(name: 'Hoop', category: ArCategory.earrings, region: ArRegion.ears, primaryColor: Color(0xFFe0e0e0), accentColor: Color(0xFF9e9e9e)),
      ArItem(name: 'Drop', category: ArCategory.earrings, region: ArRegion.ears, primaryColor: Color(0xFF1565c0), accentColor: Color(0xFF0d47a1)),
      ArItem(name: 'Pearl', category: ArCategory.earrings, region: ArRegion.ears, primaryColor: Color(0xFFF5F5DC), accentColor: Color(0xFFe0e0e0)),
      ArItem(name: 'Crystal', category: ArCategory.earrings, region: ArRegion.ears, primaryColor: Color(0xFF80deea), accentColor: Color(0xFF00bcd4)),
      ArItem(name: 'Jhumka', category: ArCategory.earrings, region: ArRegion.ears, primaryColor: Color(0xFFffc107), accentColor: Color(0xFFff8f00)),
    ],
    'Head': [
      ArItem(name: 'Silk', category: ArCategory.head, region: ArRegion.head, primaryColor: Color(0xFFe91e63), accentColor: Color(0xFF880e4f)),
      ArItem(name: 'Wrap', category: ArCategory.head, region: ArRegion.head, primaryColor: Color(0xFF6a1b9a), accentColor: Color(0xFF38006b)),
      ArItem(name: 'Cap', category: ArCategory.head, region: ArRegion.head, primaryColor: Color(0xFF37474f), accentColor: Color(0xFF1c313a)),
      ArItem(name: 'Turban', category: ArCategory.head, region: ArRegion.head, primaryColor: Color(0xFFd4a853), accentColor: Color(0xFFbe8e39)),
      ArItem(name: 'Beanie', category: ArCategory.head, region: ArRegion.head, primaryColor: Color(0xFF78909c), accentColor: Color(0xFF455a64)),
      ArItem(name: 'Bandana', category: ArCategory.head, region: ArRegion.head, primaryColor: Color(0xFFb71c1c), accentColor: Color(0xFF7f0000)),
    ],
    'Beard': [
      ArItem(name: 'Stubble', category: ArCategory.beard, region: ArRegion.beard, primaryColor: Color(0xFF5d4037), accentColor: Color(0xFF3e2723)),
      ArItem(name: 'Short', category: ArCategory.beard, region: ArRegion.beard, primaryColor: Color(0xFF4e342e), accentColor: Color(0xFF3e2723)),
      ArItem(name: 'Full', category: ArCategory.beard, region: ArRegion.beard, primaryColor: Color(0xFF212121), accentColor: Color(0xFF000000)),
      ArItem(name: 'Goatee', category: ArCategory.beard, region: ArRegion.beard, primaryColor: Color(0xFF3e2723), accentColor: Color(0xFF1b0000)),
      ArItem(name: 'Anchor', category: ArCategory.beard, region: ArRegion.beard, primaryColor: Color(0xFF6d4c41), accentColor: Color(0xFF4e342e)),
      ArItem(name: 'Balbo', category: ArCategory.beard, region: ArRegion.beard, primaryColor: Color(0xFF757575), accentColor: Color(0xFF424242)),
    ],
    'Eyes': [
      ArItem(name: 'Soft', category: ArCategory.eyes, region: ArRegion.eyes, primaryColor: Color(0xFFbcaaa4), accentColor: Color(0xFF8d6e63)),
      ArItem(name: 'Classic', category: ArCategory.eyes, region: ArRegion.eyes, primaryColor: Color(0xFF1a237e), accentColor: Color(0xFF000051)),
      ArItem(name: 'Winged', category: ArCategory.eyes, region: ArRegion.eyes, primaryColor: Color(0xFF212121), accentColor: Color(0xFF000000)),
      ArItem(name: 'Smokey', category: ArCategory.eyes, region: ArRegion.eyes, primaryColor: Color(0xFF424242), accentColor: Color(0xFF212121)),
      ArItem(name: 'Earth', category: ArCategory.eyes, region: ArRegion.eyes, primaryColor: Color(0xFF795548), accentColor: Color(0xFF4e342e)),
      ArItem(name: 'Bold', category: ArCategory.eyes, region: ArRegion.eyes, primaryColor: Color(0xFF4a148c), accentColor: Color(0xFF12005e)),
    ],
    'Hair': [
      ArItem(name: 'Chestnut', category: ArCategory.hair, region: ArRegion.hairTop, primaryColor: Color(0xFF8d4004), accentColor: Color(0xFF6a2f02)),
      ArItem(name: 'Caramel', category: ArCategory.hair, region: ArRegion.hairTop, primaryColor: Color(0xFFc07c35), accentColor: Color(0xFF8d5e1e)),
      ArItem(name: 'Jet', category: ArCategory.hair, region: ArRegion.hairTop, primaryColor: Color(0xFF0a0a0a), accentColor: Color(0xFF212121)),
      ArItem(name: 'Ash', category: ArCategory.hair, region: ArRegion.hairTop, primaryColor: Color(0xFFbdbdbd), accentColor: Color(0xFF9e9e9e)),
      ArItem(name: 'Copper', category: ArCategory.hair, region: ArRegion.hairTop, primaryColor: Color(0xFFbf6a0e), accentColor: Color(0xFF8d4e0a)),
      ArItem(name: 'Plum', category: ArCategory.hair, region: ArRegion.hairTop, primaryColor: Color(0xFF7b1fa2), accentColor: Color(0xFF4a0072)),
    ],
  };

  static ArItem? find(String category, String name) {
    final list = items[category];
    if (list == null) return null;
    for (final item in list) {
      if (item.name == name) return item;
    }
    return null;
  }
}
