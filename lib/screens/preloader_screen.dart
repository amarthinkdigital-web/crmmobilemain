import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PreloaderScreen extends StatefulWidget {
  const PreloaderScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<PreloaderScreen> createState() => _PreloaderScreenState();
}

class _PreloaderScreenState extends State<PreloaderScreen>
    with TickerProviderStateMixin {
  static const String _logoAsset = 'lib/theme/logo.png';
  static const double _logoAspect = 2055 / 1178;

  static const int _rows = 4;
  static const int _cols = 6;

  // 0.0s - 2.4s : 24 small logo fragments wander around the screen
  // 2.4s - 3.3s : fragments visibly converge and join into the logo
  // 3.3s - 4.2s : complete logo pause (0.9s)
  // 4.2s - 4.7s : golden glow reveal (0.5s)
  // 4.7s - 5.0s : glow hold (0.3s)
  // then 0.5s fade to the login screen
  static const Duration _introDuration = Duration(milliseconds: 5000);
  static const double _wanderEnd = 2400 / 5000;
  static const double _assembleEnd = 3300 / 5000;
  static const double _glowStart = 4200 / 5000;
  static const double _glowEnd = 4700 / 5000;

  late final AnimationController _intro;
  late final AnimationController _pulse;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: _introDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    precacheImage(
      const AssetImage(_logoAsset),
      context,
      onError: (_, _) {},
    ).whenComplete(() {
      if (mounted) _intro.forward();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050C1C),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050C1C),
              Color(0xFF0A1628),
              Color(0xFF0F2140),
              Color(0xFF162D50),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxLogoW = math.min(constraints.maxWidth * 0.62, 340.0);
            final maxLogoH = constraints.maxHeight * 0.30;
            double logoW = maxLogoW;
            double logoH = logoW / _logoAspect;
            if (logoH > maxLogoH) {
              logoH = maxLogoH;
              logoW = logoH * _logoAspect;
            }

            return AnimatedBuilder(
              animation: Listenable.merge([_intro, _pulse]),
              builder: (context, _) {
                final t = _intro.value;

                final double glowProgress =
                    ((t - _glowStart) / (_glowEnd - _glowStart))
                        .clamp(0.0, 1.0)
                        .toDouble();
                final glow = Curves.easeOutCubic.transform(glowProgress);
                final breath =
                    0.9 + 0.1 * math.sin(_pulse.value * 2 * math.pi);
                final glowOpacity =
                    (glow * breath).clamp(0.0, 1.0).toDouble();

                return Center(
                  child: SizedBox(
                    width: logoW * 2.2,
                    height: logoH * 2.6,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (glowOpacity > 0)
                          Positioned.fill(
                            child: Opacity(
                              opacity: glowOpacity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    radius: 0.75,
                                    colors: [
                                      AppColors.gold.withValues(alpha: 0.30),
                                      AppColors.gold.withValues(alpha: 0.10),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.42, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (glowOpacity > 0)
                          Opacity(
                            opacity: glowOpacity * 0.55,
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 16,
                                sigmaY: 16,
                              ),
                              child: _logoImage(logoW, logoH),
                            ),
                          ),
                        SizedBox(
                          width: logoW,
                          height: logoH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: List.generate(_rows * _cols, (index) {
                              final row = index ~/ _cols;
                              final col = index % _cols;
                              return _buildPiece(
                                index: index,
                                row: row,
                                col: col,
                                logoW: logoW,
                                logoH: logoH,
                                t: t,
                                constraints: constraints,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPiece({
    required int index,
    required int row,
    required int col,
    required double logoW,
    required double logoH,
    required double t,
    required BoxConstraints constraints,
  }) {
    final double assemble =
        ((t - _wanderEnd) / (_assembleEnd - _wanderEnd))
            .clamp(0.0, 1.0)
            .toDouble();
    final a = Curves.easeInOutCubic.transform(assemble);
    final double wanderT = math.min(t, _wanderEnd);
    final double seconds = wanderT * _introDuration.inMilliseconds / 1000;

    final double r1 = _hash(index * 3 + 1);
    final double r2 = _hash(index * 7 + 2);
    final double r3 = _hash(index * 11 + 3);
    final double r4 = _hash(index * 13 + 4);
    final double r5 = _hash(index * 17 + 5);

    final double spreadX =
        math.max(0.0, constraints.maxWidth * 0.5 - logoW * 0.5 - 8);
    final double spreadY =
        math.max(0.0, constraints.maxHeight * 0.5 - logoH * 0.5 - 8);
    final double baseX = (r1 * 2 - 1) * spreadX;
    final double baseY = (r2 * 2 - 1) * spreadY;

    final double orbit = 14 + r3 * 24;
    final double speed = 0.22 + r4 * 0.22;
    final double phase = r5 * math.pi * 2;

    final double dxWander =
        baseX + math.sin(seconds * math.pi * 2 * speed + phase) * orbit;
    final double dyWander =
        baseY +
        math.cos(seconds * math.pi * 2 * speed * 0.85 + phase * 1.4) * orbit;

    final double spin = (r2 * 2 - 1) * 0.7;
    final double angleWander = (r4 * 2 - 1) * 0.9 + seconds * spin;
    double settleAngle = angleWander % (2 * math.pi);
    if (settleAngle > math.pi) settleAngle -= 2 * math.pi;
    if (settleAngle < -math.pi) settleAngle += 2 * math.pi;
    final double scaleWander =
        0.9 + 0.1 * math.sin(seconds * math.pi * 2 * speed + phase);

    final double dx = dxWander * (1 - a);
    final double dy = dyWander * (1 - a);
    final double angle = settleAngle * (1 - a);
    final double scale = scaleWander + (1 - scaleWander) * a;

    final Alignment tileAlignment = Alignment(
      (col + 0.5) / _cols * 2 - 1,
      (row + 0.5) / _rows * 2 - 1,
    );

    final double fadeIn =
        (t * _introDuration.inMilliseconds / 1000 / 0.35)
            .clamp(0.0, 1.0)
            .toDouble();

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        alignment: tileAlignment,
        child: Transform.scale(
          scale: scale,
          alignment: tileAlignment,
          child: Opacity(
            opacity: fadeIn,
            child: ClipRect(
              clipper: _LogoTileClipper(
                row: row,
                col: col,
                rows: _rows,
                cols: _cols,
              ),
              child: _logoImage(logoW, logoH),
            ),
          ),
        ),
      ),
    );
  }

  double _hash(int value) {
    final x = math.sin(value * 127.1 + 311.7) * 43758.5453123;
    return x - x.floorToDouble();
  }

  Widget _logoImage(double width, double height) {
    return Image.asset(
      _logoAsset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      color: AppColors.gold,
      filterQuality: FilterQuality.high,
    );
  }
}

class _LogoTileClipper extends CustomClipper<Rect> {
  const _LogoTileClipper({
    required this.row,
    required this.col,
    required this.rows,
    required this.cols,
  });

  final int row;
  final int col;
  final int rows;
  final int cols;

  @override
  Rect getClip(Size size) {
    final w = size.width / cols;
    final h = size.height / rows;
    const overlap = 1.0;
    return Rect.fromLTRB(
      math.max(0.0, col * w - overlap),
      math.max(0.0, row * h - overlap),
      math.min(size.width, (col + 1) * w + overlap),
      math.min(size.height, (row + 1) * h + overlap),
    );
  }

  @override
  bool shouldReclip(covariant _LogoTileClipper oldClipper) {
    return oldClipper.row != row ||
        oldClipper.col != col ||
        oldClipper.rows != rows ||
        oldClipper.cols != cols;
  }
}
