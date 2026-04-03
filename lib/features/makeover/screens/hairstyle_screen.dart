import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/widgets/empty_photo_placeholder.dart';
import 'package:styleiq/core/widgets/loading_shimmer.dart';
import 'package:styleiq/core/widgets/photo_preview.dart';
import 'package:styleiq/core/widgets/screen_app_bar.dart';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
import 'package:styleiq/features/makeover/models/hairstyle_recommendation.dart';
import 'package:styleiq/services/api/claude_api_service.dart';

class HairstyleScreen extends StatefulWidget {
  const HairstyleScreen({super.key});

  @override
  State<HairstyleScreen> createState() => _HairstyleScreenState();
}

class _HairstyleScreenState extends State<HairstyleScreen> {
  final _analysisService = AnalysisService();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;
  HairstyleRecommendation? _recommendation;
  bool _isLoading = false;
  String? _errorMessage;
  List<HairstyleResult> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _analysisService.getHairstyleHistory();
      if (mounted) setState(() { _history = history; _loadingHistory = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (!kIsWeb) {
      final permission =
          source == ImageSource.camera ? Permission.camera : Permission.photos;
      final status = await permission.request();
      if (!status.isGranted && !status.isLimited) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(source == ImageSource.camera
                  ? 'Camera permission is required'
                  : 'Photo library permission is required'),
              action: const SnackBarAction(
                  label: 'Settings', onPressed: openAppSettings),
            ),
          );
        }
        return;
      }
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _imageName = picked.name;
          _recommendation = null;
          _errorMessage = null;
        });
        await _analyzePhoto();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load photo: $e')),
        );
      }
    }
  }

  Future<void> _analyzePhoto() async {
    if (_imageBytes == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _analysisService.getHairstyleRecommendations(
          _imageBytes!, _imageName ?? 'photo.jpg');
      if (mounted) {
        setState(() {
          _recommendation = result;
          _isLoading = false;
        });
        _loadHistory(); // refresh history after saving
      }
    } on ClaudeApiException catch (e) {
      if (mounted) setState(() { _errorMessage = e.message; _isLoading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a selfie'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenAppBar(title: 'Hairstyle Recommendations'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area
            _imageBytes != null
                ? PhotoPreview(bytes: _imageBytes!)
                : const Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyPhotoPlaceholder(
                      icon: Icons.face_retouching_natural,
                      message: 'Upload a selfie for hairstyle recommendations',
                    ),
                  ),

            // Action button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _showSourceSheet,
                icon: const Icon(Icons.add_a_photo),
                label: Text(
                    _imageBytes == null ? 'Upload Selfie' : 'Change Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMain,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Current analysis content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildContent(),
            ),

            // History section
            if (!_loadingHistory && _history.isNotEmpty) ...[
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHistory(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();
    if (_recommendation != null) return _buildResults();
    return const SizedBox.shrink();
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(
          'Analyzing your face shape and hair texture…',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        const ScoreCardShimmer(),
      ],
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.coral.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.coral),
          const SizedBox(height: 8),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.coral)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _analyzePhoto,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final rec = _recommendation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetectionBadges(rec: rec)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 20),
        Text(
          'Recommended Styles',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(rec.recommendations.length, (i) {
          return _StyleCard(item: rec.recommendations[i])
              .animate(delay: Duration(milliseconds: 100 * i))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.1, end: 0);
        }),
        if (rec.styleNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _StyleNotes(notes: rec.styleNotes),
        ],
      ],
    );
  }

  // ── History ────────────────────────────────────────────────────────────────

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Analyses',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final item = _history[i];
              final rec = item.recommendation;
              return GestureDetector(
                onTap: () {
                  if (item.imageUrl != null) {
                    final bytes = ImageUtils.dataUrlToBytes(item.imageUrl!);
                    setState(() {
                      _imageBytes = bytes;
                      _imageName = 'photo.jpg';
                      _recommendation = rec;
                      _errorMessage = null;
                    });
                  }
                },
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.imageUrl != null)
                        Image.memory(
                          ImageUtils.dataUrlToBytes(item.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      else
                        const ColoredBox(
                          color: Color(0xFFF0EEFF),
                          child: Icon(Icons.face_retouching_natural,
                              size: 36, color: AppTheme.primaryMain),
                        ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            rec.faceShape,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: 50 * i))
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.95, 0.95));
            },
          ),
        ),
      ],
    );
  }
}

// ── Detection badges ──────────────────────────────────────────────────────────

class _DetectionBadges extends StatelessWidget {
  final HairstyleRecommendation rec;
  const _DetectionBadges({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(icon: Icons.face, label: 'Face: ${rec.faceShape}', color: AppTheme.primaryMain),
        _Chip(icon: Icons.waves, label: 'Hair: ${rec.hairTexture}', color: AppTheme.accentMain),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Style card ────────────────────────────────────────────────────────────────

class _StyleCard extends StatelessWidget {
  final HairstyleItem item;
  const _StyleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final maintenanceColor = switch (item.maintenanceLevel) {
      'low' => AppTheme.accentMain,
      'high' => AppTheme.coral,
      _ => AppTheme.amber,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _MaintenanceBadge(
                  level: item.maintenanceLevel, color: maintenanceColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.description,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryMain.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 16, color: AppTheme.primaryMain),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.whyItWorks,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          if (item.stylingTips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '💡 ${item.stylingTips}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGrey,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MaintenanceBadge extends StatelessWidget {
  final String level;
  final Color color;
  const _MaintenanceBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${level[0].toUpperCase()}${level.substring(1)} care',
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Style notes ───────────────────────────────────────────────────────────────

class _StyleNotes extends StatelessWidget {
  final String notes;
  const _StyleNotes({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentMain.withValues(alpha: 0.1),
            AppTheme.primaryMain.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentMain.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Style Notes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.accentMain,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
