import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auction_screen.dart'; // To access AuctionScreen

/// Custom slide transition for cinematic routing
class CinematicRoute extends PageRouteBuilder {
  final Widget page;
  CinematicRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutQuart;
            var slideAnimation = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        );
}

// ---------------------------------------------------------
// COMMON WIDGETS
// ---------------------------------------------------------

class GlowingBackground extends StatelessWidget {
  final AnimationController animation;
  final Color glowColor;

  const GlowingBackground({super.key, required this.animation, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -200 + (animation.value * 100),
              left: -150 + (animation.value * 50),
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------
// CREATE ROOM SCREEN
// ---------------------------------------------------------

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});
  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> with TickerProviderStateMixin {
  final TextEditingController _roomNameController = TextEditingController();

  bool _isPrivate = false;
  String? _generatedCode;

  late AnimationController _bgController;
  late AnimationController _buttonGlowController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);
    _buttonGlowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _buttonGlowController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  void _generateRoomCode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    _generatedCode = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _createRoom() async {
    if (_roomNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Room Name', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }

    // Heavy impact to simulate the gavel hitting "CLACK"
    HapticFeedback.heavyImpact();

    // If private, ensure we have a code. If public, just generate a hidden unique ID for the doc.
    if (_isPrivate && _generatedCode == null) {
      _generateRoomCode();
    }
    
    String docId = _isPrivate ? _generatedCode! : FirebaseFirestore.instance.collection("rooms").doc().id;
    // We store explicit roomCode only if it's private. If public, it's just the docId.
    String storedCode = _isPrivate ? _generatedCode! : docId;

    await FirebaseFirestore.instance.collection("rooms").doc(docId).set({
      "roomName": _roomNameController.text,
      "isPrivate": _isPrivate,
      "roomCode": storedCode,
      "currentBid": 1000000, // 10L Base
      "highestBidder": "",
      "player": "Virat Kohli", // Placeholder
      "sold": false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    // Simulate transition delay for cinematic effect
    await Future.delayed(const Duration(milliseconds: 300));
    Navigator.pushReplacement(
      context,
      CinematicRoute(page: AuctionScreen(teamName: "Host", roomId: docId, isHost: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06), // Dark brownish-black cinematic background
      body: Stack(
        children: [
          GlowingBackground(animation: _bgController, glowColor: const Color(0xFF8B6508)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFFD700)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.gavel_rounded, size: 28, color: Color(0xFFFFD700)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "CREATE AUCTION ROOM",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start a new auction",
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 30),

                  // Main Card (Glassmorphism & Wooden feel)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                         BoxShadow(color: Color(0x33FFD700), blurRadius: 20, spreadRadius: -5),
                         BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 10)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E1C0C), Color(0xFF1E1005)], // Wooden tone
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _roomNameController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: "Room Name",
                                  labelStyle: const TextStyle(color: Color(0xFFDAA520)),
                                  prefixIcon: const Icon(Icons.meeting_room_outlined, color: Color(0xFFDAA520), size: 20),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Private Toggle
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPrivate = !_isPrivate;
                                    if (_isPrivate && _generatedCode == null) {
                                      _generateRoomCode();
                                    }
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _isPrivate ? const Color(0xFFFFD700) : Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(_isPrivate ? Icons.lock : Icons.lock_open, color: _isPrivate ? const Color(0xFFFFD700) : Colors.white54, size: 24),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          "Private Room",
                                          style: TextStyle(
                                            color: _isPrivate ? const Color(0xFFFFD700) : Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: _isPrivate,
                                        onChanged: (val) {
                                          setState(() {
                                            _isPrivate = val;
                                            if (_isPrivate && _generatedCode == null) {
                                              _generateRoomCode();
                                            }
                                          });
                                          HapticFeedback.selectionClick();
                                        },
                                        activeColor: const Color(0xFFFFD700),
                                        inactiveThumbColor: Colors.grey,
                                        inactiveTrackColor: Colors.black26,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Generation Area when Private
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _isPrivate
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 24.0),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Text("ROOM CODE", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 2)),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.black45,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                                                  boxShadow: const [BoxShadow(color: Color(0x33FFD700), blurRadius: 10)]
                                                ),
                                                child: Text(_generatedCode ?? "", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Primary Button
                  AnimatedBuilder(
                    animation: _buttonGlowController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3 + (0.3 * _buttonGlowController.value)),
                              blurRadius: 20 + (10 * _buttonGlowController.value),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _createRoom,
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.gavel_rounded, color: Color(0xFF1E1005), size: 28),
                                    SizedBox(width: 12),
                                    Text(
                                      "CREATE ROOM",
                                      style: TextStyle(
                                        color: Color(0xFF1E1005),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// JOIN ROOM SCREEN
// ---------------------------------------------------------

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});
  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  late AnimationController _bgController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _joinPublicRoom(String roomId) async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.push(
      context,
      CinematicRoute(page: AuctionScreen(teamName: "Guest", roomId: roomId, isHost: false)),
    );
  }

  void _showPrivateRoomPopup(String roomId, String actualCode, String roomName) {
    HapticFeedback.selectionClick();
    
    final TextEditingController codeController = TextEditingController();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
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
              title: Column(
                children: [
                  const Icon(Icons.lock, color: Color(0xFFFFD700), size: 40),
                  const SizedBox(height: 10),
                  Text(
                    "Enter Room Code",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roomName,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
              content: TextField(
                controller: codeController,
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "XXXXXX",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 8),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                  ),
                ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (codeController.text == actualCode) {
                      Navigator.pop(context); // Close dialog
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        CinematicRoute(page: AuctionScreen(teamName: "Guest", roomId: roomId, isHost: false)),
                      );
                    } else {
                      HapticFeedback.vibrate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid Room Code', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text("JOIN AUCTION", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06), 
      body: Stack(
        children: [
          GlowingBackground(animation: _bgController, glowColor: const Color(0xFFDAA520)),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.gavel_rounded, size: 28, color: Colors.white),
                      const SizedBox(width: 10),
                      const Text(
                        "JOIN AUCTION",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Text(
                    "Enter the bidding arena",
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), letterSpacing: 1.0),
                  ),
                ),
                const SizedBox(height: 30),

                // SECTION 1: SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1.5),
                      boxShadow: const [BoxShadow(color: Color(0x1AFFD700), blurRadius: 10, spreadRadius: -2)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search auction rooms...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // SECTION 2: RECENT LIVE AUCTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: const Text(
                    "Live Auction Rooms",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("rooms").orderBy("createdAt", descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No live auctions available.",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                          ),
                        );
                      }
                      
                      var docs = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String roomName = (data["roomName"] ?? "").toString().toLowerCase();
                        String roomCode = (data["roomCode"] ?? "").toString().toLowerCase();
                        return roomName.contains(_searchQuery) || roomCode.contains(_searchQuery);
                      }).toList();

                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No rooms match your search.",
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          String roomName = data["roomName"] ?? "Auction Arena";
                          bool isPrivate = data["isPrivate"] ?? false;
                          String roomCode = data["roomCode"] ?? docs[index].id;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildRoomCard(
                              roomName: roomName,
                              isPrivate: isPrivate,
                              onTap: () {
                                if (isPrivate) {
                                  _showPrivateRoomPopup(docs[index].id, roomCode, roomName);
                                } else {
                                  _joinPublicRoom(docs[index].id);
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard({required String roomName, required bool isPrivate, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1E1E1E).withOpacity(0.8), const Color(0xFF121212).withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDAA520).withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4)),
            const BoxShadow(color: Color(0x1ADAA520), blurRadius: 10, spreadRadius: -2),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1C0C),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDAA520).withOpacity(0.5)),
              ),
              child: Icon(isPrivate ? Icons.lock : Icons.public, color: const Color(0xFFFFD700), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isPrivate ? "PRIVATE" : "PUBLIC",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.6 * _pulseController.value),
                                      blurRadius: 8 * _pulseController.value,
                                      spreadRadius: 2 * _pulseController.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Live",
                            style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFDAA520), size: 28),
          ],
        ),
      ),
    );
  }
}
