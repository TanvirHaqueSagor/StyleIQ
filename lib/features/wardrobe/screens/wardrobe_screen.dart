import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/features/wardrobe/models/wardrobe_item.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

// ── Design tokens (editorial palette matched to StyleIQ purple) ─────────────
const Color _surface       = Color(0xFFFAF9FF); // base background
const Color _surfaceLow    = Color(0xFFF0EFF9); // secondary zone
const Color _surfaceCard   = Color(0xFFFFFFFF); // lifted card
const Color _onSurface     = Color(0xFF1A1528); // near-black, purple-tinted
const Color _midTone       = Color(0xFF6B6882); // labels & secondary text
const Color _chipActive    = Color(0xFF1A1528); // active filter pill
const Color _gold          = Color(0xFFEF9F27); // AI / favourite accent
// ───────────────────────────────────────────────────────────────────────────

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final _storage = LocalStorageService();
  final _picker  = ImagePicker();

  static const _guestUserId = 'guest';
  static const _categories = [
    'All', 'Top', 'Bottom', 'Dress', 'Shoes', 'Accessory',
  ];
  static const _catLabels = [
    'ALL', 'TOPS', 'BOTTOMS', 'DRESSES', 'SHOES', 'ACCESSORIES',
  ];

  List<WardrobeItem> _items = [];
  String _selectedCat = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _storage.getWardrobeItems(_guestUserId);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<WardrobeItem> get _filtered => _selectedCat == 'All'
      ? _items
      : _items.where((i) => i.category == _selectedCat).toList();

  // ── Add flow ───────────────────────────────────────────────────────────────

  Future<void> _addItem() async {
    if (!kIsWeb) {
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Photo library permission is required'),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ));
        }
        return;
      }
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      final category = await _showCategorySheet();
      if (category == null || !mounted) return;

      final name = await _showNameDialog(category);
      if (!mounted) return;

      final bytes   = await picked.readAsBytes();
      final dataUrl = ImageUtils.toDataUrl(bytes, picked.name);

      final item = WardrobeItem(
        category:    category,
        subcategory: name ?? '',
        color:       '',
        imageUrl:    dataUrl,
        userId:      _guestUserId,
      );
      await _storage.saveWardrobeItem(item, _guestUserId);
      await _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add item: $e')),
        );
      }
    }
  }

  Future<String?> _showCategorySheet() => showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _CategorySheet(
          categories: _categories.where((c) => c != 'All').toList(),
        ),
      );

  Future<String?> _showNameDialog(String category) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name your piece',
                style: GoogleFonts.notoSerif(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: _onSurface, letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Give it a name — e.g. "Heritage Trench"',
                style: GoogleFonts.inter(fontSize: 13, color: _midTone),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: GoogleFonts.inter(color: _onSurface, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Piece name…',
                  hintStyle: GoogleFonts.inter(
                      color: _midTone.withValues(alpha: 0.55)),
                  filled: true,
                  fillColor: _surfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SizedBox(
                        height: 46,
                        child: Center(
                          child: Text('Skip',
                              style: GoogleFonts.inter(
                                  color: _midTone,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context, ctrl.text.trim()),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: _chipActive,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text('Save',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _deleteItem(WardrobeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove piece',
                  style: GoogleFonts.notoSerif(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: _onSurface, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Text('Remove this item from your wardrobe?',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: _midTone, height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: SizedBox(
                        height: 46,
                        child: Center(
                          child: Text('Keep',
                              style: GoogleFonts.inter(
                                  color: _midTone,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.coral,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text('Remove',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await _storage.deleteWardrobeItem(item.id, _guestUserId);
        await _loadItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not remove item: $e')));
        }
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _surface,
      floatingActionButton: _buildFab(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildCategoryFilter()),
          if (_items.isNotEmpty)
            SliverToBoxAdapter(child: _buildAiChip()),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 96 + bottomPad),
                child: _buildGrid(),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    final count  = _items.length;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B6B), AppTheme.primaryMain],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 22, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overline label
          count > 0
              ? _Overline('$count PIECES',
                  color: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.15))
              : const _Overline('CURATED COLLECTION',
                  color: Colors.white70),
          const SizedBox(height: 10),
          // Display headline
          Text(
            'Your Wardrobe',
            style: GoogleFonts.notoSerif(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.72,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }

  // ── Category filter ────────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final active = _categories[i] == _selectedCat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = _categories[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: active ? _chipActive : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _catLabels[i],
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _midTone,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── AI Pulse chip ──────────────────────────────────────────────────────────

  Widget _buildAiChip() {
    final unworn = _items.where((i) => i.wearCount == 0).length;
    final msg = unworn > 0
        ? 'You have $unworn unworn pieces this season. Ready for a refresh?'
        : 'Your collection is looking sharp. Keep building your style story.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surfaceLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.auto_awesome_rounded, size: 15, color: _gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.notoSerif(
                  fontStyle: FontStyle.italic,
                  fontSize: 13.5,
                  color: _onSurface,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Editorial staggered grid ───────────────────────────────────────────────

  Widget _buildGrid() {
    final items = _filtered;
    final rows  = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(_buildRow(
        left:  items[i],
        right: i + 1 < items.length ? items[i + 1] : null,
        rowIdx: i ~/ 2,
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(children: rows),
    );
  }

  Widget _buildRow(
      {required WardrobeItem left,
      required WardrobeItem? right,
      required int rowIdx}) {
    const gap     = 12.0;
    const stagger = 38.0;
    const hPad    = 20.0;
    final delay   = Duration(milliseconds: 45 * rowIdx);

    return Padding(
      padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left card — taller image, no top offset
          Expanded(
            child: _buildCard(left, imageHeight: 204)
                .animate(delay: delay)
                .fadeIn(duration: 360.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
          ),
          const SizedBox(width: gap),
          // Right card — shorter image, pushed down by stagger
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: stagger),
              child: right != null
                  ? _buildCard(right, imageHeight: 168)
                      .animate(
                          delay: delay + const Duration(milliseconds: 55))
                      .fadeIn(duration: 360.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOut)
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(WardrobeItem item, {required double imageHeight}) {
    final hasImage = item.imageUrl.isNotEmpty &&
        item.imageUrl.startsWith('data:');
    final name = item.subcategory.isNotEmpty
        ? item.subcategory
        : _fallbackName(item.category);

    return GestureDetector(
      onLongPress: () => _deleteItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceCard,
          borderRadius: BorderRadius.circular(24),
          // Whisper shadow — 5% opacity, purple-tinted
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D1A1528),
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image zone ────────────────────────────────────────────────
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: hasImage
                  ? Image.memory(
                      ImageUtils.dataUrlToBytes(item.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _surfaceLow,
                      child: Center(
                        child: Icon(
                          _catIcon(item.category),
                          size: 42,
                          color: _midTone.withValues(alpha: 0.40),
                        ),
                      ),
                    ),
            ),
            // ── Text zone ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label — uppercase Inter tracking
                  Text(
                    item.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _midTone,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Item name — Noto Serif editorial
                  Text(
                    name,
                    style: GoogleFonts.notoSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _onSurface,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Favourite badge
                  if (item.isFavorite) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded,
                            size: 10, color: _gold),
                        const SizedBox(width: 3),
                        Text(
                          'FAVOURITE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _gold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _addItem,
      backgroundColor: _chipActive,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 26),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isEmpty = _selectedCat == 'All';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _surfaceLow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.checkroom_rounded,
                size: 36, color: _midTone),
          ),
          const SizedBox(height: 24),
          Text(
            isEmpty
                ? 'Your wardrobe is empty'
                : 'No ${_selectedCat.toLowerCase()}s added yet',
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEmpty
                ? 'Tap + to add your first piece'
                : 'Add pieces using the + button',
            style: GoogleFonts.inter(fontSize: 14, color: _midTone),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fallbackName(String cat) => switch (cat) {
        'Top'       => 'My Top',
        'Bottom'    => 'My Bottom',
        'Dress'     => 'My Dress',
        'Shoes'     => 'My Shoes',
        'Accessory' => 'My Accessory',
        _           => 'Wardrobe Piece',
      };

  IconData _catIcon(String cat) => switch (cat) {
        'Top'       => Icons.dry_cleaning_rounded,
        'Bottom'    => Icons.straighten_rounded,
        'Dress'     => Icons.accessibility_new_rounded,
        'Shoes'     => Icons.directions_walk_rounded,
        'Accessory' => Icons.watch_rounded,
        _           => Icons.checkroom_rounded,
      };
}

// ── Overline label widget ──────────────────────────────────────────────────

class _Overline extends StatelessWidget {
  final String text;
  final Color color;
  final Color? bg;

  const _Overline(this.text,
      {this.color = _midTone, this.bg});

  @override
  Widget build(BuildContext context) {
    Widget label = Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.4,
      ),
    );
    if (bg != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: label,
      );
    }
    return label;
  }
}

// ── Category bottom sheet ──────────────────────────────────────────────────

class _CategorySheet extends StatelessWidget {
  final List<String> categories;
  const _CategorySheet({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _midTone.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
            child: Text(
              'What kind of piece is this?',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _onSurface,
                letterSpacing: -0.4,
              ),
            ),
          ),
          ...categories.map((cat) => _CategoryTile(category: cat)),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 14),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context, category),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _surfaceLow,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_icon(category),
                  size: 20, color: AppTheme.primaryMain),
            ),
            const SizedBox(width: 14),
            Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _onSurface,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: _midTone),
          ],
        ),
      ),
    );
  }

  IconData _icon(String cat) => switch (cat) {
        'Top'       => Icons.dry_cleaning_rounded,
        'Bottom'    => Icons.straighten_rounded,
        'Dress'     => Icons.accessibility_new_rounded,
        'Shoes'     => Icons.directions_walk_rounded,
        'Accessory' => Icons.watch_rounded,
        _           => Icons.checkroom_rounded,
      };
}
