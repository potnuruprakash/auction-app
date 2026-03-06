import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _spotlightController;
  late AnimationController _blockController;
  late AnimationController _hammerController;
  late AnimationController _particleController;
  late AnimationController _textController;

  late Animation<double> _spotlightOpacity;
  late Animation<Offset> _blockSlide;
  late Animation<double> _hammerRotation;
  late Animation<double> _textOpacity;
  late Animation<double> _textScale;

  final List<Particle> particles = [];

  @override
  void initState() {
    super.initState();

    _spotlightController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _blockController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _hammerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _particleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _textController = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _spotlightOpacity = Tween<double>(begin: 0, end: 1.0).animate(CurvedAnimation(parent: _spotlightController, curve: Curves.easeIn));
    _blockSlide = Tween<Offset>(begin: const Offset(0, 100), end: Offset.zero).animate(CurvedAnimation(parent: _blockController, curve: Curves.easeOutBack));
    
    _hammerRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.3, end: -1.4).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 45),
      TweenSequenceItem(tween: Tween(begin: -1.4, end: 0.1).chain(CurveTween(curve: Curves.easeInExpo)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 15),
    ]).animate(_hammerController);

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _textScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutBack));

    final random = Random();
    for (int i = 0; i < 60; i++) {
        double angle = random.nextDouble() * pi + pi; // Upward directions
        double speed = random.nextDouble() * 300 + 100;
        particles.add(Particle(
          x: 0, 
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: random.nextBool() ? const Color(0xFFFFD700) : const Color(0xFFFFA500),
          size: random.nextDouble() * 7 + 2,
        ));
    }

    _sequenceAnimations();
  }

  void _sequenceAnimations() async {
    await _spotlightController.forward();
    await _blockController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _hammerController.forward();
    
    // Trigger particle/text exactly when the hammer hits the block
    await Future.delayed(const Duration(milliseconds: 1050));
    _particleController.forward();
    _textController.forward();
    
    // Hold the splash screen for cinematic effect
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ModernHomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1200),
      ));
    }
  }

  @override
  void dispose() {
    _spotlightController.dispose();
    _blockController.dispose();
    _hammerController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final blockCenter = size.height * 0.55;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06), // Dark brownish-black cinematic background
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Spotlight Effect
          AnimatedBuilder(
            animation: _spotlightOpacity,
            builder: (context, child) {
              return Opacity(
                opacity: _spotlightOpacity.value,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.2),
                      radius: 0.7,
                      colors: [
                        Color(0xFF3B280F), // Soft gold/brown glow
                        Color(0xFF0F0A06), // Dark edges
                        Color(0xFF0F0A06),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Wooden Auction Block
          AnimatedBuilder(
            animation: _blockSlide,
            builder: (context, child) {
              return Positioned(
                top: blockCenter,
                child: Transform.translate(
                  offset: _blockSlide.value,
                  child: Container(
                    width: 140,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5C3A21), Color(0xFF331E10)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.9), blurRadius: 20, offset: const Offset(0, 10)),
                         const BoxShadow(color: Color(0x33FFD700), blurRadius: 2, spreadRadius: 1), // slight rim light
                      ]
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Gavel / Hammer Animation
          AnimatedBuilder(
            animation: _hammerRotation,
            builder: (context, child) {
              return Positioned(
                top: blockCenter - 145,
                right: size.width / 2 - 30, // Positioning for offset pivot
                child: Transform(
                  transform: Matrix4.rotationZ(_hammerRotation.value),
                  alignment: Alignment.bottomRight, // Swing hinges from the handle base
                  child: SizedBox(
                    width: 120,
                    height: 155,
                    child: Stack(
                      children: [
                        // Gavel Handle
                        Positioned(
                          bottom: 0,
                          right: 15,
                          child: Container(
                            width: 16,
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFB8860B), Color(0xFF704A1B)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(-2, 2)),
                              ]
                            ),
                          ),
                        ),
                        // Gavel Head
                        Positioned(
                          top: 15,
                          right: -10,
                          child: Container(
                            width: 75,
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFDF00), Color(0xFFDAA520), Color(0xFFC59B27)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(color: Color(0x66FFD700), blurRadius: 20, spreadRadius: 2), // Glow
                                BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(-3, 5)),
                              ]
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Particle Spark Explosion
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return Positioned(
                top: blockCenter - 5,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: particles.map((p) {
                    double progress = _particleController.value;
                    return Positioned(
                      left: p.vx * progress,
                      top: p.vy * progress + (300 * progress * progress), // Simulated curve/gravity
                      child: Opacity(
                        opacity: (1.0 - progress).clamp(0.0, 1.0),
                        child: Container(
                          width: p.size * (1.0 - progress),
                          height: p.size * (1.0 - progress),
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                               BoxShadow(color: p.color.withOpacity(0.9), blurRadius: 8, spreadRadius: 2)
                            ]
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // Glowing Name Plate Transition
          AnimatedBuilder(
            animation: _textOpacity,
            builder: (context, child) {
              return Positioned(
                bottom: size.height * 0.18,
                child: Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.scale(
                    scale: _textScale.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFD4AF37), Color(0xFFAA8222)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0xCCFFD700), blurRadius: 40, spreadRadius: 6), // Huge golden aura
                          BoxShadow(color: Colors.black, blurRadius: 15, offset: Offset(0, 10)),
                        ],
                        border: Border.all(color: const Color(0xFFFFF8DC).withOpacity(0.5), width: 1.5),
                      ),
                      child: const Text(
                        "AUCTION ARENA",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1005), // Ultra dark brown text
                          letterSpacing: 6.0,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Particle {
  double x, y, vx, vy, size;
  Color color;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.size});
}
