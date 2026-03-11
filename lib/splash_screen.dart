import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'home_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AUCTION ARENA  —  Marvel-Inspired Cinematic Intro
//  5 Scenes: Dark Start → Metallic Panels → Energy Burst → Logo Assembly → Hero
// ═══════════════════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Scene controllers ───────────────────────────────────────────────────
  late AnimationController _scene1Ctrl; // 0-1  dark bg + ambient particles
  late AnimationController _scene2Ctrl; // 0-1  metallic panels
  late AnimationController _scene3Ctrl; // 0-1  energy burst
  late AnimationController _scene4Ctrl; // 0-1  logo assembly
  late AnimationController _scene5Ctrl; // 0-1  hero shot + tagline
  late AnimationController _ambientCtrl; // loops — floating specks

  // ─── Per-scene animations ────────────────────────────────────────────────
  late Animation<double> _bgGlow;       // scene 1
  late Animation<double> _panelOpacity;
  late Animation<double> _burstRadius;  // scene 3
  late Animation<double> _burstOpacity;
  late Animation<double> _logoScale;    // scene 4
  late Animation<double> _logoOpacity;
  late Animation<double> _fragmentProgress;
  late Animation<double> _sweepX;       // scene 5 — light sweep
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;

  // ─── Particle/fragment data ──────────────────────────────────────────────
  final List<_Fragment> _fragments   = [];
  final List<_Particle> _particles   = [];
  final List<_Panel>    _panels      = [];
  final List<_Speck>    _specks      = [];   // ambient

  int _currentScene = 1;

  @override
  void initState() {
    super.initState();

    // Setup controllers
    _scene1Ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scene2Ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _scene3Ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scene4Ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scene5Ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // Scene 1
    _bgGlow = CurvedAnimation(parent: _scene1Ctrl, curve: Curves.easeIn);

    // Scene 2 — panels
    _panelOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_scene2Ctrl);

    // Scene 3 — burst
    _burstRadius  = Tween<double>(begin: 0, end: 1.0).animate(
        CurvedAnimation(parent: _scene3Ctrl, curve: Curves.easeOutExpo));
    _burstOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(_scene3Ctrl);

    // Scene 4 — logo assembly
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _scene4Ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scene4Ctrl, curve: const Interval(0.2, 0.7, curve: Curves.easeIn)));
    _fragmentProgress = CurvedAnimation(parent: _scene4Ctrl, curve: Curves.easeInCubic);

    // Scene 5 — hero
    _sweepX = Tween<double>(begin: -1.6, end: 2.0).animate(
        CurvedAnimation(parent: _scene5Ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeInOut)));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scene5Ctrl, curve: const Interval(0.35, 0.65, curve: Curves.easeIn)));
    _taglineSlide = Tween<double>(begin: 22, end: 0).animate(
        CurvedAnimation(parent: _scene5Ctrl, curve: const Interval(0.35, 0.65, curve: Curves.easeOut)));

    _buildSpecks();
    _buildPanels();
    _buildFragments();
    _buildParticles();
    _playSequence();
  }

  // ─── Data builders ───────────────────────────────────────────────────────

  void _buildSpecks() {
    final rng = Random(7);
    for (int i = 0; i < 80; i++) {
      _specks.add(_Speck(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 3 + 1,
        speed: rng.nextDouble() * 0.006 + 0.002,
        phase: rng.nextDouble() * pi * 2,
        color: rng.nextBool()
            ? const Color(0xFFFFD700)
            : const Color(0xFF00BFFF),
      ));
    }
  }

  void _buildPanels() {
    final colors = [
      [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
      [const Color(0xFF0D0D0D), const Color(0xFF1A1005)],
      [const Color(0xFF120A03), const Color(0xFF1E1005)],
      [const Color(0xFF0A0A1A), const Color(0xFF1A0A00)],
      [const Color(0xFF050510), const Color(0xFF101010)],
    ];
    final rng = Random(3);
    for (int i = 0; i < 5; i++) {
      double w = 0.18 + rng.nextDouble() * 0.08;
      _panels.add(_Panel(
        xFraction: 0.05 + i * 0.19,
        widthFraction: w,
        angle: (rng.nextDouble() - 0.5) * 0.12,
        colors: colors[i],
        delay: i * 0.12,
        accentAlpha: rng.nextDouble() * 0.5 + 0.3,
      ));
    }
  }

  void _buildFragments() {
    final rng = Random(99);
    for (int i = 0; i < 55; i++) {
      double angle = rng.nextDouble() * 2 * pi;
      double dist   = rng.nextDouble() * 280 + 60;
      _fragments.add(_Fragment(
        startX: cos(angle) * dist,
        startY: sin(angle) * dist,
        size: rng.nextDouble() * 18 + 6,
        rotation: rng.nextDouble() * pi * 2,
        delay: rng.nextDouble() * 0.45,
        isGold: rng.nextBool(),
      ));
    }
  }

  void _buildParticles() {
    final rng = Random(11);
    for (int i = 0; i < 160; i++) {
      double angle = rng.nextDouble() * 2 * pi;
      double speed = rng.nextDouble() * 240 + 40;
      _particles.add(_Particle(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: rng.nextDouble() * 5 + 1.5,
        delay: rng.nextDouble() * 0.5,
        color: rng.nextBool()
            ? const Color(0xFFFFD700)
            : const Color(0xFFFF8C00),
      ));
    }
  }

  // ─── Sequence ────────────────────────────────────────────────────────────

  Future<void> _playSequence() async {
    // Scene 1 – dark ambient
    setState(() => _currentScene = 1);
    await _scene1Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Scene 2 – panels
    setState(() => _currentScene = 2);
    await _scene2Ctrl.forward();

    // Scene 3 – energy burst
    setState(() => _currentScene = 3);
    await _scene3Ctrl.forward();

    // Scene 4 – logo assembly
    setState(() => _currentScene = 4);
    await _scene4Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Scene 5 – hero shot
    setState(() => _currentScene = 5);
    await _scene5Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => const ModernHomeScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 1200),
    ));
  }

  @override
  void dispose() {
    _scene1Ctrl.dispose();
    _scene2Ctrl.dispose();
    _scene3Ctrl.dispose();
    _scene4Ctrl.dispose();
    _scene5Ctrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final cy = size.height / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _scene1Ctrl, _scene2Ctrl, _scene3Ctrl,
          _scene4Ctrl, _scene5Ctrl, _ambientCtrl,
        ]),
        builder: (context, _) {
          return Stack(children: [

            // ── Base black ────────────────────────────────────────────────
            Container(color: Colors.black),

            // ── S1: Radial dark glow build-up ─────────────────────────────
            if (_currentScene >= 1)
              Opacity(
                opacity: _bgGlow.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.15),
                      radius: 0.85,
                      colors: [
                        const Color(0xFF1A1005).withValues(alpha: 0.9),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),

            // ── S1: Ambient floating specks (always on) ───────────────────
            if (_currentScene >= 1)
              ..._specks.map((s) {
                double t = _ambientCtrl.value;
                double y = s.y - s.speed * t * 8;
                double wave = sin(t * pi * 2 + s.phase) * 0.025;
                double opacity = (_currentScene >= 4)
                    ? (0.3 + 0.3 * sin(t * pi * 2 + s.phase))
                    : 0.4 + 0.4 * sin(t * pi * 2 + s.phase);
                return Positioned(
                  left: (s.x + wave) * size.width,
                  top: ((y % 1.0 + 1.0) % 1.0) * size.height,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Container(
                      width: s.size, height: s.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.color,
                        boxShadow: [BoxShadow(
                          color: s.color.withValues(alpha: 0.7),
                          blurRadius: s.size * 2,
                        )],
                      ),
                    ),
                  ),
                );
              }),

            // ── S2: Metallic sliding panels ───────────────────────────────
            if (_currentScene == 2)
              Opacity(
                opacity: _panelOpacity.value,
                child: Stack(children: _panels.map((panel) {
                  double t = ((_scene2Ctrl.value - panel.delay) / (1.0 - panel.delay)).clamp(0.0, 1.0);
                  double p = Curves.easeOutCubic.transform(t);
                  double slideOffset = (1.0 - p) * size.height * 0.9;

                  return Positioned(
                    left: panel.xFraction * size.width,
                    top: -size.height * 0.1 + slideOffset,
                    bottom: -size.height * 0.1 + slideOffset,
                    width: panel.widthFraction * size.width,
                    child: Transform.rotate(
                      angle: panel.angle,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: panel.colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border(
                            right: BorderSide(
                              color: const Color(0xFFFFD700).withValues(alpha: panel.accentAlpha * p),
                              width: 1.5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.15 * p),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: (p * 1.5).clamp(0.0, 1.0),
                            child: const Icon(
                              Icons.gavel_rounded,
                              color: Color(0x33FFD700),
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList()),
              ),

            // Panel light streaks during scene 2
            if (_currentScene == 2)
              Opacity(
                opacity: _panelOpacity.value,
                child: CustomPaint(
                  size: size,
                  painter: _LightStreakPainter(progress: _scene2Ctrl.value),
                ),
              ),

            // ── S3: Energy burst wave ─────────────────────────────────────
            if (_currentScene == 3)
              Opacity(
                opacity: _burstOpacity.value,
                child: Stack(children: [
                  // Outer shockwave rings
                  for (int ring = 0; ring < 3; ring++)
                    Positioned(
                      left: cx - size.width * _burstRadius.value * (0.6 + ring * 0.2),
                      top: cy - size.width * _burstRadius.value * (0.6 + ring * 0.2),
                      child: Container(
                        width: size.width * _burstRadius.value * (1.2 + ring * 0.4),
                        height: size.width * _burstRadius.value * (1.2 + ring * 0.4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(
                              alpha: (0.5 - ring * 0.12) * (1.0 - _scene3Ctrl.value),
                            ),
                            width: 2.5 - ring * 0.6,
                          ),
                        ),
                      ),
                    ),
                  // Central flash
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: _burstRadius.value * 0.9,
                          colors: [
                            const Color(0xFFFFD700).withValues(alpha: 0.5 * (1 - _scene3Ctrl.value)),
                            const Color(0xFFFF8C00).withValues(alpha: 0.25 * (1 - _scene3Ctrl.value)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),

            // ── S4: Fragment implosion → logo ─────────────────────────────
            if (_currentScene >= 4)
              Positioned.fill(child: Stack(children: [

                // Exploding particles first (fade out as logo forms)
                if (_scene4Ctrl.value < 0.6)
                  ..._particles.map((p) {
                    double t2 = ((_scene4Ctrl.value - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
                    double curve = Curves.easeOutCirc.transform(t2);
                    double fade = (1.0 - curve * 1.8).clamp(0.0, 1.0);
                    return Positioned(
                      left: cx + p.vx * curve * 0.6 - p.size / 2,
                      top: cy + p.vy * curve * 0.6 - p.size / 2,
                      child: Opacity(
                        opacity: fade,
                        child: Container(
                          width: p.size, height: p.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: p.color,
                            boxShadow: [BoxShadow(
                              color: p.color.withValues(alpha: 0.8),
                              blurRadius: p.size * 2, spreadRadius: 1,
                            )],
                          ),
                        ),
                      ),
                    );
                  }),

                // Metallic fragments flying in
                ..._fragments.map((frag) {
                  double t2 = ((_fragmentProgress.value - frag.delay) / (1.0 - frag.delay)).clamp(0.0, 1.0);
                  double curve = Curves.easeInCubic.transform(t2);
                  double ox = frag.startX * (1.0 - curve);
                  double oy = frag.startY * (1.0 - curve);
                  double opacity = (t2 * 2.5).clamp(0.0, 1.0);
                  double rot = frag.rotation * (1.0 - curve);
                  Color c = frag.isGold ? const Color(0xFFDAA520) : const Color(0xFFB0C4DE);
                  return Positioned(
                    left: cx + ox - frag.size / 2,
                    top: cy + oy - frag.size / 2,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: rot,
                        child: Container(
                          width: frag.size, height: frag.size,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(
                              color: c.withValues(alpha: 0.8),
                              blurRadius: 8, spreadRadius: 1,
                            )],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Logo itself
                Positioned(
                  left: 0, right: 0, top: cy - 90,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _buildLogo(),
                    ),
                  ),
                ),
              ])),

            // ── S5: Light sweep + tagline ─────────────────────────────────
            if (_currentScene == 5) ...[
              // Show logo statically during scene 5
              Positioned(
                left: 0, right: 0, top: cy - 90,
                child: _buildLogo(),
              ),

              // Light sweep
              Positioned.fill(
                child: Opacity(
                  opacity: (1 - (_scene5Ctrl.value - 0.4).clamp(0.0, 1.0)) * 0.55,
                  child: Transform.translate(
                    offset: Offset(_sweepX.value * size.width, 0),
                    child: Container(
                      width: 90,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0x44FFFFFF),
                            Color(0x99FFFFFF),
                            Color(0x44FFFFFF),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Tagline
              Positioned(
                bottom: size.height * 0.22,
                left: 0, right: 0,
                child: Opacity(
                  opacity: _taglineOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _taglineSlide.value),
                    child: Column(children: [
                      // divider line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 50, height: 1, color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, color: Color(0xFFFFD700), size: 8),
                          const SizedBox(width: 12),
                          Container(width: 50, height: 1, color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Where Strategy Meets Victory',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFCFD8DC),
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],

            // ── Bottom golden progress bar ────────────────────────────────
            Positioned(
              bottom: 30, left: 32, right: 32,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                ),
              ),
            ),

          ]);
        },
      ),
    );
  }

  // ─── Logo Widget ─────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with glow orb
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.22),
                  const Color(0xFFFF8C00).withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
            // Icon ring
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0xAAFFD700), blurRadius: 30, spreadRadius: 4),
                  BoxShadow(color: Color(0x4400BFFF), blurRadius: 20),
                ],
              ),
              child: const Icon(Icons.gavel_rounded, color: Color(0xFFFFD700), size: 48),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Metallic text — AUCTION ARENA
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFB8860B),
              Color(0xFFFFFFAA),
              Color(0xFFFFD700),
              Color(0xFFFFFFFF),
              Color(0xFFDAA520),
              Color(0xFFB8860B),
            ],
            stops: [0.0, 0.2, 0.4, 0.5, 0.7, 1.0],
          ).createShader(bounds),
          child: const Text(
            'AUCTION ARENA',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 7,
              shadows: [
                Shadow(color: Color(0xFFFFD700), blurRadius: 25, offset: Offset(0, 0)),
                Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Sub-rule line
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 30, height: 1, color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            const Text(
              'OFFICIAL EDITION',
              style: TextStyle(
                color: Color(0xFF808080),
                fontSize: 10,
                letterSpacing: 4,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 30, height: 1, color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _Speck {
  final double x, y, size, speed, phase;
  final Color color;
  const _Speck({required this.x, required this.y, required this.size, required this.speed, required this.phase, required this.color});
}

class _Panel {
  final double xFraction, widthFraction, angle, accentAlpha, delay;
  final List<Color> colors;
  const _Panel({required this.xFraction, required this.widthFraction, required this.angle, required this.accentAlpha, required this.delay, required this.colors});
}

class _Particle {
  final double vx, vy, size, delay;
  final Color color;
  const _Particle({required this.vx, required this.vy, required this.size, required this.delay, required this.color});
}

class _Fragment {
  final double startX, startY, size, rotation, delay;
  final bool isGold;
  const _Fragment({required this.startX, required this.startY, required this.size, required this.rotation, required this.delay, required this.isGold});
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTER — Light Streaks for Scene 2
// ═══════════════════════════════════════════════════════════════════════════════

class _LightStreakPainter extends CustomPainter {
  final double progress;

  static final List<_StreakLine> _lines = _build();
  static List<_StreakLine> _build() {
    final rng = Random(17);
    return List.generate(22, (i) {
      double y   = rng.nextDouble();
      double sLen = rng.nextDouble() * 0.45 + 0.1;
      double delay = rng.nextDouble() * 0.4;
      bool gold = rng.nextBool();
      return _StreakLine(y, sLen, delay, gold);
    });
  }

  const _LightStreakPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _lines) {
      double t = ((progress - s.delay) / (1.0 - s.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      double sx = 0;
      double ex = size.width * s.lineLen * t;
      double y  = s.y * size.height;
      final color = s.gold
          ? const Color(0xFFFFD700).withValues(alpha: t * 0.7)
          : const Color(0xFF00BFFF).withValues(alpha: t * 0.5);
      final paint = Paint()
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [Colors.transparent, color, Colors.transparent])
            .createShader(Rect.fromLTWH(sx, y - 2, ex, 4));
      canvas.drawLine(Offset(sx, y), Offset(ex, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LightStreakPainter old) => old.progress != progress;
}

class _StreakLine {
  final double y, lineLen, delay;
  final bool gold;
  const _StreakLine(this.y, this.lineLen, this.delay, this.gold);
}

// Legacy compat
class Particle {
  double x, y, vx, vy, size;
  Color color;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.size});
}
