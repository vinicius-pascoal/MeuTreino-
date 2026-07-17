import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';

class MuscleBodyProgressStat {
  final String name;
  final Color color;
  final String changeLabel;

  const MuscleBodyProgressStat({
    required this.name,
    required this.color,
    required this.changeLabel,
  });
}

class MuscleBodyProgressMapCard extends StatefulWidget {
  final List<MuscleBodyProgressStat> stats;

  const MuscleBodyProgressMapCard({super.key, required this.stats});

  @override
  State<MuscleBodyProgressMapCard> createState() =>
      _MuscleBodyProgressMapCardState();
}

class _MuscleBodyProgressMapCardState extends State<MuscleBodyProgressMapCard> {
  _RenderedBodyBundle? _renderedImages;
  bool _isLoading = true;
  Object? _error;
  int _renderRequestId = 0;
  String _statsSignature = '';

  @override
  void initState() {
    super.initState();
    _statsSignature = _buildStatsSignature(widget.stats);
    _renderMaps();
  }

  @override
  void didUpdateWidget(covariant MuscleBodyProgressMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextSignature = _buildStatsSignature(widget.stats);
    if (nextSignature == _statsSignature) {
      return;
    }

    _statsSignature = nextSignature;
    _renderMaps();
  }

  @override
  void dispose() {
    _renderedImages?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    _BodySvgSourceBundle.clearCache();
    _renderMaps();
  }

  Future<void> _renderMaps() async {
    final requestId = ++_renderRequestId;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assets = await _BodySvgSourceBundle.load();
      final rendered = await assets.render(widget.stats);

      if (!mounted || requestId != _renderRequestId) {
        rendered.dispose();
        return;
      }

      final previous = _renderedImages;
      setState(() {
        _renderedImages = rendered;
        _isLoading = false;
      });
      previous?.dispose();
    } catch (error) {
      if (!mounted || requestId != _renderRequestId) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookup = {
      for (final stat in widget.stats) _normalizeGroupName(stat.name): stat,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppThemeColors.surfaceHigh.withValues(alpha: 0.98),
              AppThemeColors.surface.withValues(alpha: 0.96),
              AppThemeColors.background.withValues(alpha: 0.82),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppThemeColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppThemeColors.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.accessibility_new_rounded,
                    color: AppThemeColors.primaryStrong,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mapa corporal', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 3),
                      Text(
                        'Comparativo recente por grupo muscular',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppThemeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _BodyMapHeaderPill(count: widget.stats.length),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const _BodyMapLoadingStage()
            else if (_error != null || _renderedImages == null)
              const _BodyMapMessageStage(
                icon: Icons.broken_image_outlined,
                message: 'Nao foi possivel carregar o mapa corporal.',
              )
            else
              _BodyMapStage(
                frontImage: _renderedImages!.front,
                backImage: _renderedImages!.back,
                frontAspectRatio: _renderedImages!.frontAspectRatio,
                backAspectRatio: _renderedImages!.backAspectRatio,
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _EvolutionLegendChip(label: 'queda', color: Color(0xFFE35D5D)),
                _EvolutionLegendChip(
                  label: 'estavel',
                  color: Color(0xFFF0C95C),
                ),
                _EvolutionLegendChip(
                  label: 'evolucao',
                  color: Color(0xFF2FBF71),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MuscleGroupSummaryWrap(lookup: lookup),
          ],
        ),
      ),
    );
  }
}

class _BodyMapHeaderPill extends StatelessWidget {
  final int count;

  const _BodyMapHeaderPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Text(
        '$count grupos',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppThemeColors.primaryStrong,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BodyMapStage extends StatelessWidget {
  final ui.Image frontImage;
  final ui.Image backImage;
  final double frontAspectRatio;
  final double backAspectRatio;

  const _BodyMapStage({
    required this.frontImage,
    required this.backImage,
    required this.frontAspectRatio,
    required this.backAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final height = isWide ? 440.0 : 330.0;
        final horizontalPadding = isWide ? 28.0 : 12.0;
        final gap = isWide ? 24.0 : 8.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 18,
          ),
          decoration: _bodyMapStageDecoration(),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _BodyMapBackdropPainter()),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _BodyFigurePanel(
                        title: 'Frente',
                        image: frontImage,
                        aspectRatio: frontAspectRatio,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _BodyFigurePanel(
                        title: 'Costas',
                        image: backImage,
                        aspectRatio: backAspectRatio,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BodyMapLoadingStage extends StatelessWidget {
  const _BodyMapLoadingStage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      width: double.infinity,
      decoration: _bodyMapStageDecoration(),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _BodyMapMessageStage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _BodyMapMessageStage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _bodyMapStageDecoration(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppThemeColors.textSoft, size: 30),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyFigurePanel extends StatelessWidget {
  final String title;
  final ui.Image image;
  final double aspectRatio;

  const _BodyFigurePanel({
    required this.title,
    required this.image,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: AppThemeColors.background.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: RawImage(
                image: image,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BodyMapBackdropPainter extends CustomPainter {
  const _BodyMapBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = AppThemeColors.primary.withValues(alpha: 0.10)
      ..strokeWidth = 1.2;
    final floorPaint = Paint()
      ..color = AppThemeColors.primaryStrong.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var index = 1; index < 5; index += 1) {
      final y = size.height * index / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      axisPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.88),
        width: size.width * 0.62,
        height: size.height * 0.14,
      ),
      floorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyMapBackdropPainter oldDelegate) => false;
}

class _MuscleGroupSummaryWrap extends StatelessWidget {
  final Map<String, MuscleBodyProgressStat> lookup;

  const _MuscleGroupSummaryWrap({required this.lookup});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _summaryGroups.map((group) {
        return _MuscleChangeChip(
          group: group,
          stat: lookup[_normalizeGroupName(group)],
        );
      }).toList(),
    );
  }
}

class _MuscleChangeChip extends StatelessWidget {
  final String group;
  final MuscleBodyProgressStat? stat;

  const _MuscleChangeChip({required this.group, required this.stat});

  @override
  Widget build(BuildContext context) {
    final tone = stat?.color ?? AppThemeColors.textSoft;
    final label = stat?.changeLabel ?? 'sem dados';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: stat == null ? 0.07 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tone.withValues(alpha: stat == null ? 0.12 : 0.26),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvolutionLegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _EvolutionLegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _bodyMapStageDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.075),
        AppThemeColors.surfaceHigh.withValues(alpha: 0.26),
        AppThemeColors.background.withValues(alpha: 0.30),
      ],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: AppThemeColors.outlineStrong.withValues(alpha: 0.72),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.16),
        blurRadius: 24,
        offset: const Offset(0, 18),
      ),
    ],
  );
}

class _RenderedBodyBundle {
  final ui.Image front;
  final ui.Image back;
  final double frontAspectRatio;
  final double backAspectRatio;

  const _RenderedBodyBundle({
    required this.front,
    required this.back,
    required this.frontAspectRatio,
    required this.backAspectRatio,
  });

  void dispose() {
    front.dispose();
    back.dispose();
  }
}

class _BodySvgSourceBundle {
  final String frontSvg;
  final String backSvg;

  const _BodySvgSourceBundle({required this.frontSvg, required this.backSvg});

  static Future<_BodySvgSourceBundle>? _cachedBundle;

  static Future<_BodySvgSourceBundle> load() {
    return _cachedBundle ??= _loadBundle();
  }

  static void clearCache() {
    _cachedBundle = null;
  }

  static Future<_BodySvgSourceBundle> _loadBundle() async {
    final assets = await Future.wait([
      rootBundle.loadString(_frontAssetPath),
      rootBundle.loadString(_backAssetPath),
    ]);

    return _BodySvgSourceBundle(frontSvg: assets[0], backSvg: assets[1]);
  }

  Future<_RenderedBodyBundle> render(List<MuscleBodyProgressStat> stats) async {
    final lookup = {
      for (final stat in stats) _normalizeGroupName(stat.name): stat,
    };
    final fallbackColor = AppThemeColors.textSoft.withValues(alpha: 0.14);

    final front = await _renderFigure(
      svg: frontSvg,
      size: const Size(1006, 1564),
      baseImageId: 'base-anatomica',
      lineArtImageId: 'lineart',
      regions: _frontRegions,
      lookup: lookup,
      fallbackColor: fallbackColor,
      overlayBlendMode: BlendMode.srcOver,
      overlayOpacity: 0.80,
      masksUseLuminance: false,
    );
    final back = await _renderFigure(
      svg: backSvg,
      size: const Size(1024, 1536),
      baseImageId: 'base-anatomica',
      lineArtImageId: 'lineart',
      regions: _backRegions,
      lookup: lookup,
      fallbackColor: fallbackColor,
      overlayBlendMode: BlendMode.srcOver,
      overlayOpacity: 0.80,
      masksUseLuminance: true,
    );

    return _RenderedBodyBundle(
      front: front,
      back: back,
      frontAspectRatio: 1006 / 1564,
      backAspectRatio: 1024 / 1536,
    );
  }
}

class _BodyRegionAsset {
  final String maskId;
  final String? groupName;

  const _BodyRegionAsset({required this.maskId, this.groupName});
}

const String _frontAssetPath = 'assets/body/corpo_humano_frente_editavel.svg';
const String _backAssetPath = 'assets/body/corpo_humano_posterior_editavel.svg';

const List<String> _summaryGroups = [
  'Peito',
  'Costas',
  'Ombro',
  'Biceps',
  'Triceps',
  'Pernas',
  'Abdomen',
];

const Map<String, _BodyRegionAsset> _frontRegions = {
  'pescoco': _BodyRegionAsset(maskId: 'mascara-pescoco'),
  'biceps': _BodyRegionAsset(maskId: 'mascara-biceps', groupName: 'Biceps'),
  'deltoides': _BodyRegionAsset(
    maskId: 'mascara-deltoides',
    groupName: 'Ombro',
  ),
  'peitorais': _BodyRegionAsset(
    maskId: 'mascara-peitorais',
    groupName: 'Peito',
  ),
  'triceps': _BodyRegionAsset(maskId: 'mascara-triceps', groupName: 'Triceps'),
  'serratus': _BodyRegionAsset(
    maskId: 'mascara-serratus',
    groupName: 'Abdomen',
  ),
  'obliquos': _BodyRegionAsset(
    maskId: 'mascara-obliquos',
    groupName: 'Abdomen',
  ),
  'abdomen': _BodyRegionAsset(maskId: 'mascara-abdomen', groupName: 'Abdomen'),
  'antebracos': _BodyRegionAsset(maskId: 'mascara-antebracos'),
  'adutores': _BodyRegionAsset(maskId: 'mascara-adutores', groupName: 'Pernas'),
  'quadriceps': _BodyRegionAsset(
    maskId: 'mascara-quadriceps',
    groupName: 'Pernas',
  ),
  'tibiais': _BodyRegionAsset(maskId: 'mascara-tibiais', groupName: 'Pernas'),
  'panturrilhas': _BodyRegionAsset(
    maskId: 'mascara-panturrilhas',
    groupName: 'Pernas',
  ),
};

const Map<String, _BodyRegionAsset> _backRegions = {
  'deltoides': _BodyRegionAsset(
    maskId: 'mascara-deltoides',
    groupName: 'Ombro',
  ),
  'infraespinal-redondos': _BodyRegionAsset(
    maskId: 'mascara-infraespinal-redondos',
    groupName: 'Costas',
  ),
  'triceps': _BodyRegionAsset(
    maskId: 'mascara-triceps',
    groupName: 'Triceps',
  ),
  'bracos-laterais': _BodyRegionAsset(
    maskId: 'mascara-bracos-laterais',
    groupName: 'Triceps',
  ),
  'antebracos': _BodyRegionAsset(maskId: 'mascara-antebracos'),
  'latissimos': _BodyRegionAsset(
    maskId: 'mascara-latissimos',
    groupName: 'Costas',
  ),
  'eretores-espinha': _BodyRegionAsset(
    maskId: 'mascara-eretores-espinha',
    groupName: 'Costas',
  ),
  'lombares-laterais': _BodyRegionAsset(
    maskId: 'mascara-lombares-laterais',
    groupName: 'Costas',
  ),
  'trapezio': _BodyRegionAsset(
    maskId: 'mascara-trapezio',
    groupName: 'Costas',
  ),
  'gluteos': _BodyRegionAsset(
    maskId: 'mascara-gluteos',
    groupName: 'Pernas',
  ),
  'adutores-posteriores': _BodyRegionAsset(
    maskId: 'mascara-adutores-posteriores',
    groupName: 'Pernas',
  ),
  'isquiotibiais': _BodyRegionAsset(
    maskId: 'mascara-isquiotibiais',
    groupName: 'Pernas',
  ),
  'posteriores-coxa': _BodyRegionAsset(
    maskId: 'mascara-posteriores-coxa',
    groupName: 'Pernas',
  ),
  'panturrilhas': _BodyRegionAsset(
    maskId: 'mascara-panturrilhas',
    groupName: 'Pernas',
  ),
};

Future<ui.Image> _renderFigure({
  required String svg,
  required Size size,
  required String baseImageId,
  String? lineArtImageId,
  required Map<String, _BodyRegionAsset> regions,
  required Map<String, MuscleBodyProgressStat> lookup,
  required Color fallbackColor,
  required BlendMode overlayBlendMode,
  required double overlayOpacity,
  required bool masksUseLuminance,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final bounds = Offset.zero & size;

  final baseImage = await _decodePng(_extractImageDataById(svg, baseImageId));
  canvas.drawImageRect(
    baseImage,
    Rect.fromLTWH(
      0,
      0,
      baseImage.width.toDouble(),
      baseImage.height.toDouble(),
    ),
    bounds,
    Paint(),
  );

  for (final entry in regions.entries) {
    final stat = entry.value.groupName == null
        ? null
        : lookup[_normalizeGroupName(entry.value.groupName!)];
    final overlayColor = _resolveOverlayColor(
      stat: stat,
      fallbackColor: fallbackColor,
      overlayOpacity: overlayOpacity,
    );
    final maskImage = await _decodeMaskPng(
      _extractMaskImageData(svg, entry.value.maskId),
      useLuminanceAlpha: masksUseLuminance,
    );

    canvas.saveLayer(bounds, Paint()..blendMode = overlayBlendMode);
    canvas.drawRect(bounds, Paint()..color = overlayColor);
    canvas.drawImageRect(
      maskImage,
      Rect.fromLTWH(
        0,
        0,
        maskImage.width.toDouble(),
        maskImage.height.toDouble(),
      ),
      bounds,
      Paint()..blendMode = BlendMode.dstIn,
    );
    canvas.restore();

    maskImage.dispose();
  }

  if (lineArtImageId != null) {
    final lineArtImage = await _decodePng(
      _extractImageDataById(svg, lineArtImageId),
    );
    canvas.drawImageRect(
      lineArtImage,
      Rect.fromLTWH(
        0,
        0,
        lineArtImage.width.toDouble(),
        lineArtImage.height.toDouble(),
      ),
      bounds,
      Paint(),
    );
    lineArtImage.dispose();
  }

  baseImage.dispose();

  final picture = recorder.endRecording();
  final renderedImage = await picture.toImage(
    size.width.round(),
    size.height.round(),
  );
  picture.dispose();
  return renderedImage;
}

Future<ui.Image> _decodePng(String base64Png) async {
  final codec = await ui.instantiateImageCodec(base64Decode(base64Png.trim()));
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<ui.Image> _decodeMaskPng(
  String base64Png, {
  required bool useLuminanceAlpha,
}) async {
  final image = await _decodePng(base64Png);
  if (!useLuminanceAlpha) {
    return image;
  }

  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  if (byteData == null) {
    return image;
  }

  final bytes = byteData.buffer.asUint8List();
  if (_maskHasUsefulAlpha(bytes)) {
    return image;
  }

  final convertedBytes = Uint8List(bytes.length);
  for (var index = 0; index < bytes.length; index += 4) {
    final red = bytes[index];
    final green = bytes[index + 1];
    final blue = bytes[index + 2];
    final sourceAlpha = bytes[index + 3];
    final luminance = (red * 54 + green * 183 + blue * 19) ~/ 256;
    final alpha = (luminance * sourceAlpha) ~/ 255;

    convertedBytes[index] = 255;
    convertedBytes[index + 1] = 255;
    convertedBytes[index + 2] = 255;
    convertedBytes[index + 3] = alpha;
  }

  final convertedImage = await _decodeRgbaImage(
    convertedBytes,
    width: image.width,
    height: image.height,
  );
  image.dispose();
  return convertedImage;
}

bool _maskHasUsefulAlpha(Uint8List bytes) {
  var minAlpha = 255;
  var maxAlpha = 0;

  for (var index = 3; index < bytes.length; index += 4) {
    final alpha = bytes[index];
    if (alpha < minAlpha) minAlpha = alpha;
    if (alpha > maxAlpha) maxAlpha = alpha;

    if (minAlpha < 250 && maxAlpha > 5) {
      return true;
    }
  }

  return minAlpha != maxAlpha;
}

Future<ui.Image> _decodeRgbaImage(
  Uint8List pixels, {
  required int width,
  required int height,
}) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

Color _resolveOverlayColor({
  required MuscleBodyProgressStat? stat,
  required Color fallbackColor,
  required double overlayOpacity,
}) {
  if (stat == null) {
    return fallbackColor;
  }

  final originalAlpha = _colorAlpha(stat.color);
  final alpha = originalAlpha >= 0.99
      ? overlayOpacity
      : originalAlpha * overlayOpacity;
  return stat.color.withValues(alpha: alpha);
}

double _colorAlpha(Color color) {
  return ((color.value >> 24) & 0xff) / 255;
}

String _extractImageDataById(String svg, String imageId) {
  final imagePattern = RegExp(
    '<image[^>]*id="${RegExp.escape(imageId)}"[^>]*(?:xlink:href|href)="data:image/png;base64,([^"]+)"',
    dotAll: true,
  );
  final match = imagePattern.firstMatch(svg);
  if (match == null) {
    throw StateError('Imagem "$imageId" nao encontrada no SVG.');
  }

  return match.group(1)!;
}

String _extractMaskImageData(String svg, String maskId) {
  final maskPattern = RegExp(
    '<mask[^>]*id="${RegExp.escape(maskId)}"[^>]*>\\s*<image[^>]*(?:xlink:href|href)="data:image/png;base64,([^"]+)"',
    dotAll: true,
  );
  final match = maskPattern.firstMatch(svg);
  if (match == null) {
    throw StateError('Mascara "$maskId" nao encontrada no SVG.');
  }

  return match.group(1)!;
}

String _buildStatsSignature(List<MuscleBodyProgressStat> stats) {
  final sorted = [...stats]..sort((a, b) => a.name.compareTo(b.name));
  return sorted
      .map(
        (stat) =>
            '${_normalizeGroupName(stat.name)}:${stat.color.value}:${stat.changeLabel}',
      )
      .join('|');
}

String _normalizeGroupName(String name) {
  return name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[\u00e1\u00e0\u00e2\u00e3\u00e4]'), 'a')
      .replaceAll(RegExp('[\u00e9\u00e8\u00ea\u00eb]'), 'e')
      .replaceAll(RegExp('[\u00ed\u00ec\u00ee\u00ef]'), 'i')
      .replaceAll(RegExp('[\u00f3\u00f2\u00f4\u00f5\u00f6]'), 'o')
      .replaceAll(RegExp('[\u00fa\u00f9\u00fb\u00fc]'), 'u')
      .replaceAll('\u00e7', 'c');
}
