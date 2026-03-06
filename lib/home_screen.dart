import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'room_setup_screens.dart'; // Luxury Join & Create setup classes
import 'admin_screen.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _floatController;
  final List<Offset> _particlePositions = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Initial random positions for particles
    for (int i = 0; i < 8; i++) {
       _particlePositions.add(Offset(_random.nextDouble(), _random.nextDouble()));
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06), // Very dark brown/black
      body: Stack(
        children: [
          // Background Animations
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                   // Top left glow
                   Positioned(
                    top: -150 + (_bgController.value * 50),
                    left: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B6508).withOpacity(0.3), // Dark Goldenrod
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom right glow
                  Positioned(
                    bottom: -150 - (_bgController.value * 30),
                    right: -100,
                    child: Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD700).withOpacity(0.15), // Pure Gold
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Center glow
                  Positioned(
                    top: size.height * 0.4,
                    left: size.width * 0.2,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFDAA520).withOpacity(0.12), // Goldenrod
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Floating Particles
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Stack(
                children: List.generate(_particlePositions.length, (index) {
                  final pos = _particlePositions[index];
                  final x = pos.dx * size.width;
                  final y = pos.dy * size.height;
                  final offset = sin((_floatController.value * 2 * pi) + index) * 20;

                  return Positioned(
                    left: x,
                    top: y + offset,
                    child: Opacity(
                      opacity: 0.6,
                      child: Container(
                        width: index % 2 == 0 ? 8 : 6,
                        height: index % 2 == 0 ? 8 : 6,
                        decoration: BoxDecoration(
                          color: index % 3 == 0 ? const Color(0xFFFFD700) : const Color(0xFFDAA520),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (index % 3 == 0 ? const Color(0xFFFFD700) : const Color(0xFFDAA520))
                                  .withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // Main Content
          SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.white54, size: 32),
                      onPressed: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder: (context, anim1, anim2) {
                            return const SizedBox.shrink();
                          },
                          transitionBuilder: (context, anim1, anim2, child) {
                            final uCtrl = TextEditingController();
                            final pCtrl = TextEditingController();
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
                              child: FadeTransition(
                                opacity: anim1,
                                child: AlertDialog(
                                  backgroundColor: const Color(0xFF1E1005),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(color: Color(0xFFDAA520), width: 1.5),
                                  ),
                                  title: const Column(
                                    children: [
                                      Icon(Icons.admin_panel_settings, color: Color(0xFFFFD700), size: 40),
                                      SizedBox(height: 10),
                                      Text("Admin Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: uCtrl,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: "Username", hintStyle: const TextStyle(color: Colors.white54),
                                          filled: true, fillColor: Colors.black45,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: pCtrl,
                                        obscureText: true,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: "Password", hintStyle: const TextStyle(color: Colors.white54),
                                          filled: true, fillColor: Colors.black45,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFD700),
                                        foregroundColor: const Color(0xFF1E1005),
                                      ),
                                      onPressed: () {
                                        if (uCtrl.text == "admin" && pCtrl.text == "admin123") {
                                          Navigator.pop(context);
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Credentials'), backgroundColor: Colors.red));
                                        }
                                      },
                                      child: const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold)),
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  const SizedBox(height: 60),

                  // Top Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded, // Changed to Gavel
                      size: 64,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFDAA520), Color(0xFFC59B27)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        "AUCTION ARENA",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Build Your Dream Team",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.2,
                    ),
                  ),

                  const Spacer(),

                  // Center Section
                  GlassButton(
                    title: "Join Auction Room",
                    description: "Enter an existing auction room",
                    icon: Icons.groups_rounded,
                    gradientColors: const [Color(0xFFFFD700), Color(0xFFDAA520)], // Gold
                    glowColor: const Color(0xFFFFD700),
                    onTap: () {
                      Navigator.push(
                        context,
                        CinematicRoute(page: const JoinRoomScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  GlassButton(
                    title: "Create Auction Room",
                    description: "Start your own auction room",
                    icon: Icons.add_circle_outline_rounded,
                    gradientColors: const [Color(0xFFB8860B), Color(0xFF704A1B)], // Darker Bronze/Gold
                    glowColor: const Color(0xFFDAA520),
                    onTap: () {
                      Navigator.push(
                        context,
                        CinematicRoute(page: const CreateRoomScreen()),
                      );
                    },
                  ),

                  const Spacer(),

                  // Bottom Section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      "Real-time Cricket Auction Experience",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }
}

class GlassButton extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final Color glowColor;
  final VoidCallback onTap;

  const GlassButton({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animController.forward();
        setState(() => _isHovered = true);
      },
      onTapUp: (_) {
        _animController.reverse();
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () {
        _animController.reverse();
        setState(() => _isHovered = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.glowColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: widget.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.glowColor.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.4),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
