import 'dart:convert';
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
    final lookup = {
      for (final stat in widget.stats) _normalizeGroupName(stat.name): stat,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapa corporal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            if (_isLoading)
              const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null || _renderedImages == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppThemeColors.outline),
                ),
                child: const Text('Nao foi possivel carregar o mapa corporal.'),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 620;
                  final front = _BodyFigurePanel(
                    title: 'Frente',
                    image: _renderedImages!.front,
                    aspectRatio: _renderedImages!.frontAspectRatio,
                  );
                  final back = _BodyFigurePanel(
                    title: 'Costas',
                    image: _renderedImages!.back,
                    aspectRatio: _renderedImages!.backAspectRatio,
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: front),
                        const SizedBox(width: 12),
                        Expanded(child: back),
                      ],
                    );
                  }

                  return Column(
                    children: [front, const SizedBox(height: 12), back],
                  );
                },
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
            const SizedBox(height: 12),
            Text(
              _buildSummaryText(lookup),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppThemeColors.textSoft),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppThemeColors.outline),
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: aspectRatio,
            child: RawImage(
              image: image,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
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
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
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
    final maskImage = await _decodePng(
      _extractMaskImageData(svg, entry.value.maskId),
    );
    final maskUsesAlpha = await _maskUsesAlpha(maskImage);

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
      Paint()
        ..blendMode = BlendMode.dstIn
        ..colorFilter = maskUsesAlpha ? null : _luminanceToAlphaMaskFilter,
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

Future<bool> _maskUsesAlpha(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return true;
  }

  final bytes = byteData.buffer.asUint8List();
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

final ColorFilter _luminanceToAlphaMaskFilter = ColorFilter.matrix(<double>[
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
]);

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

String _buildSummaryText(Map<String, MuscleBodyProgressStat> lookup) {
  const groups = [
    'Peito',
    'Costas',
    'Ombro',
    'Biceps',
    'Triceps',
    'Pernas',
    'Abdomen',
  ];

  return groups
      .map((group) {
        final stat = lookup[_normalizeGroupName(group)];
        if (stat == null) {
          return '$group: sem dados';
        }
        return '$group ${stat.changeLabel}';
      })
      .join(' | ');
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
