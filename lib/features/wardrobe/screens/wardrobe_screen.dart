import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/services/subscription_capability_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/features/wardrobe/models/wardrobe_item.dart';
import 'package:styleiq/models/subscription_plan.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

// ── Dark design tokens (consistent with AppTheme) ──────────────────────────
const Color _card     = AppTheme.darkCard;
const Color _cardLow  = AppTheme.darkSurface;
const Color _border   = AppTheme.darkBorder;
const Color _textPri  = Colors.white;
const Color _textSec  = Color(0xFF9B97B8);   // AppTheme dark-mode muted
const Color _accent   = AppTheme.primaryMain;
const Color _gold     = AppTheme.amber;
// ───────────────────────────────────────────────────────────────────────────

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final _storage = LocalStorageService();
  final _picker = ImagePicker();

  static const _categories = ['All', 'Top', 'Bottom', 'Dress', 'Shoes', 'Accessory'];
  static const _catLabels  = ['ALL', 'TOPS', 'BOTTOMS', 'DRESSES', 'SHOES', 'ACCESSORIES'];

  List<WardrobeItem> _items = [];
  String _selectedCat = 'All';
  bool _isLoading = true;
  SubscriptionPlan _subscription = SubscriptionCapabilityService.freePlan();

  String get _userId => AppUserService.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items        = await _storage.getWardrobeItems(_userId);
      final subscription = await _storage.getSubscription(_userId);
      if (mounted) {
        setState(() {
          _items        = items;
          _subscription = subscription;
          _isLoading    = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<WardrobeItem> get _filtered => _selectedCat == 'All'
      ? _items
      : _items.where((i) => i.category == _selectedCat).toList();

  // ── Add flow ───────────────────────────────────────────────────────────────

  Future<void> _addItem() async {
    if (!SubscriptionCapabilityService.canAddWardrobeItem(_subscription, _items.length)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your free wardrobe is full. Paid plans are preview-only until billing launches.'),
          ),
        );
      }
      return;
    }

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
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      final category = await _showCategorySheet();
      if (category == null || !mounted) return;

      final name  = await _showNameDialog(category);
      if (!mounted) return;

      final bytes  = await picked.readAsBytes();
      final dataUrl = ImageUtils.toDataUrl(bytes, picked.name);

      final item = WardrobeItem(
        category: category, subcategory: name ?? '', color: '',
        imageUrl: dataUrl, userId: _userId,
      );
      await _storage.saveWardrobeItem(item, _userId);
      await _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add item: $e')));
      }
    }
  }

  Future<String?> _showCategorySheet() => showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (_) => _CategorySheet(
          categories: _categories.where((c) => c != 'All').toList(),
        ),
      );

  Future<String?> _showNameDialog(String category) => showDialog<String>(
        context: context,
        useRootNavigator: true,
        builder: (_) => const _NameDialog(),
      );

  Future<void> _deleteItem(WardrobeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Remove piece',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: _textPri, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              const Text('Remove this item from your wardrobe?',
                  style: TextStyle(fontSize: 14, color: _textSec, height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: const SizedBox(
                        height: 46,
                        child: Center(
                          child: Text('Keep',
                              style: TextStyle(color: _textSec, fontWeight: FontWeight.w600)),
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
                        child: const Text('Remove',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
        await _storage.deleteWardrobeItem(item.id, _userId);
        await _loadItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Could not remove item: $e')));
        }
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      floatingActionButton: _buildFab(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildCategoryFilter()),
          if (_items.isNotEmpty) SliverToBoxAdapter(child: _buildAiChip()),
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
          count > 0
              ? _Overline('$count PIECES', color: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.15))
              : const _Overline('CURATED COLLECTION', color: Colors.white70),
          const SizedBox(height: 10),
          const Text(
            'Your Wardrobe',
            style: TextStyle(
              fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white,
              letterSpacing: -0.72, height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subscription.maxWardrobeItems == null
                ? 'Local-only wardrobe with unlimited saved pieces in this preview.'
                : 'Local-only wardrobe: ${_items.length}/${_subscription.maxWardrobeItems} pieces saved on this device.',
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Category filter ────────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return Container(
      color: AppTheme.darkBg,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final active = _categories[i] == _selectedCat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = _categories[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: active ? _accent : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? _accent : _border,
                ),
              ),
              child: Text(
                _catLabels[i],
                style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _textSec,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
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
                style: const TextStyle(
                  fontStyle: FontStyle.italic, fontSize: 13.5,
                  color: _textPri, height: 1.55,
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
        left: items[i],
        right: i + 1 < items.length ? items[i + 1] : null,
        rowIdx: i ~/ 2,
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(children: rows),
    );
  }

  Widget _buildRow({
    required WardrobeItem left,
    required WardrobeItem? right,
    required int rowIdx,
  }) {
    const gap    = 12.0;
    const stagger = 38.0;
    const hPad   = 20.0;
    final delay  = Duration(milliseconds: 45 * rowIdx);

    return Padding(
      padding: const EdgeInsets.fromLTRB(hPad, 0, hPad, gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildCard(left, imageHeight: 204)
                .animate(delay: delay)
                .fadeIn(duration: 360.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
          ),
          const SizedBox(width: gap),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: stagger),
              child: right != null
                  ? _buildCard(right, imageHeight: 168)
                      .animate(delay: delay + const Duration(milliseconds: 55))
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
    final hasImage = item.imageUrl.isNotEmpty && item.imageUrl.startsWith('data:');
    final name     = item.subcategory.isNotEmpty ? item.subcategory : _fallbackName(item.category);

    return GestureDetector(
      onLongPress: () => _deleteItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image zone
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: hasImage
                  ? Image.memory(
                      ImageUtils.dataUrlToBytes(item.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _cardLow,
                      child: Center(
                        child: Icon(
                          _catIcon(item.category),
                          size: 42,
                          color: _textSec.withValues(alpha: 0.40),
                        ),
                      ),
                    ),
            ),
            // Text zone
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w700,
                      color: _textSec, letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: _textPri, letterSpacing: -0.2, height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.isFavorite) ...[
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.favorite_rounded, size: 10, color: _gold),
                        SizedBox(width: 3),
                        Text(
                          'FAVOURITE',
                          style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: _gold, letterSpacing: 0.8,
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
      backgroundColor: _accent,
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
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.checkroom_rounded, size: 36, color: _textSec),
          ),
          const SizedBox(height: 24),
          Text(
            isEmpty
                ? 'Your wardrobe is empty'
                : 'No ${_selectedCat.toLowerCase()}s added yet',
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: _textPri, letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isEmpty
                  ? 'Add your most-worn staples first so future analysis feels grounded in your real closet.'
                  : 'Add pieces using the + button to make recommendations more personal.',
              style: const TextStyle(fontSize: 14, color: _textSec),
              textAlign: TextAlign.center,
            ),
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

  const _Overline(this.text, {this.color = _textSec, this.bg});

  @override
  Widget build(BuildContext context) {
    Widget label = Text(
      text,
      style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: color, letterSpacing: 1.4,
      ),
    );
    if (bg != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(99),
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
      decoration: BoxDecoration(
        color: _card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _textSec.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 24, 6),
            child: Text(
              'What kind of piece is this?',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: _textPri, letterSpacing: -0.4,
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
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryMain.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppTheme.primaryMain.withValues(alpha: 0.2)),
              ),
              child: Icon(_icon(category), size: 20, color: AppTheme.primaryMain),
            ),
            const SizedBox(width: 14),
            Text(
              category,
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: _textPri,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _textSec),
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

// ── Name dialog ────────────────────────────────────────────────────────────

class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Name your piece',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: _textPri, letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Give it a name — e.g. "Heritage Trench"',
                style: TextStyle(fontSize: 13, color: _textSec),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
                style: const TextStyle(color: _textPri, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Piece name…',
                  hintStyle: TextStyle(color: _textSec.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: AppTheme.darkCardLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        height: 46,
                        child: Center(
                          child: Text('Skip',
                              style: TextStyle(color: _textSec, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(_ctrl.text.trim()),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Save',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
  }
}
