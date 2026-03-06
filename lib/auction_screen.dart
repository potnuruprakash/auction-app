import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuctionScreen extends StatefulWidget {
  final String teamName;
  final String roomId;
  final bool isHost;

  const AuctionScreen({super.key, required this.teamName, required this.roomId, required this.isHost});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> with TickerProviderStateMixin {
  bool _hasJoined = false;
  String _selectedTeam = "";
  String _playerName = "";
  final TextEditingController _playerNameController = TextEditingController();

  final List<String> iplTeams = [
    "MI", "CSK", "RCB", "KKR", "GT", "SRH", "RR", "DC", "PBKS", "LSG"
  ];
  
  final Map<String, List<Color>> teamColors = {
    "MI": [const Color(0xFF004BA0), const Color(0xFF00A1FF)],
    "CSK": [const Color(0xFFF9CD05), const Color(0xFFFFE066)],
    "RCB": [const Color(0xFFE5001C), const Color(0xFF2B2A29)],
    "KKR": [const Color(0xFF3A225D), const Color(0xFFB3A123)],
    "GT": [const Color(0xFF1B2133), const Color(0xFF0B1220)],
    "SRH": [const Color(0xFFF26522), const Color(0xFFFF9B25)],
    "RR": [const Color(0xFFEA1A85), const Color(0xFF001D48)],
    "DC": [const Color(0xFF004C93), const Color(0xFFF83430)],
    "PBKS": [const Color(0xFFED1B24), const Color(0xFFA71216)],
    "LSG": [const Color(0xFF00BFFF), const Color(0xFF00008B)],
  };
  
  Map<String, String> _lockedTeams = {};

  late AnimationController _bgController;
  late AnimationController _spotlightController;
  
  // Real-time states
  int _currentBid = 0;
  String _highestBidder = "";
  bool _sold = false;
  
  // Current player data
  String _currentPlayerId = "";
  String _currentPlayerName = "Waiting for Host...";
  String _currentPlayerRole = "";
  String _currentPlayerNationality = "";
  String _currentPlayerImage = "https://via.placeholder.com/150";
  int _currentPlayerBasePrice = 0;

  // Timer logic
  int _endTimeEpoch = 0;
  int _timerSetting = 30; // 30 sec by default
  int _remainingTime = 30;
  bool _auctionStarted = false;

  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);
    _spotlightController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

    // Host must also enter name and select team
    // widget.isHost flag is purely for extra controls now.

    _listenToRoom();
    _startLocalTimerSync();
  }

  void _listenToRoom() {
    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        var data = snapshot.data()!;
        setState(() {
          _currentBid = data["currentBid"] ?? 0;
          _highestBidder = data["highestBidder"] ?? "";
          _sold = data["sold"] ?? false;
          _auctionStarted = data["auctionStarted"] ?? false;
          
          _currentPlayerId = data["currentPlayerId"] ?? "";
          _currentPlayerName = data["currentPlayerName"] ?? "Waiting for Host...";
          _currentPlayerRole = data["currentPlayerRole"] ?? "N/A";
          _currentPlayerNationality = data["currentPlayerNationality"] ?? "N/A";
          _currentPlayerImage = data["currentPlayerImage"] ?? "https://via.placeholder.com/150";
          _currentPlayerBasePrice = data["currentPlayerBasePrice"] ?? 0;
          
          _timerSetting = data["timerSetting"] ?? 30;
          _endTimeEpoch = data["endTimeEpoch"] ?? 0;
        });

        // Track locked teams if needed (mock for now, storing in activity or subcollection is better)
      }
    });
  }

  void _startLocalTimerSync() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      
      if (_auctionStarted && !_sold && _endTimeEpoch > 0) {
        int now = DateTime.now().millisecondsSinceEpoch;
        int diff = ((_endTimeEpoch - now) / 1000).ceil();
        
        if (diff <= 0) {
          diff = 0;
          if (widget.isHost && !_sold) {
             _markSold(); // Auto mark sold if host and timer expires
          }
        }
        
        setState(() {
          _remainingTime = diff;
        });
      }
      return true;
    });
  }

  void _markSold() {
    bool isUnsold = _highestBidder.isEmpty;
    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).update({
      "sold": true,
    });
    
    if (_currentPlayerName != "Waiting for Host...") {
       String resultText = isUnsold ? "UNSOLD! $_currentPlayerName goes unsold." : "SOLD! $_currentPlayerName goes to $_highestBidder for ₹${(_currentBid/10000000).toStringAsFixed(2)} Cr";
       FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("activity").add({
          "text": resultText,
          "timestamp": FieldValue.serverTimestamp(),
          "type": "system",
       });

       if (!isUnsold && _currentPlayerId.isNotEmpty) {
           // Save to sold subcollection
           FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("soldPlayers").doc(_currentPlayerId).set({
              "name": _currentPlayerName,
              "team": _highestBidder,
              "price": _currentBid,
              "basePrice": _currentPlayerBasePrice,
              "role": _currentPlayerRole,
              "nationality": _currentPlayerNationality,
              "imageUrl": _currentPlayerImage,
           });
       } else if (isUnsold && _currentPlayerId.isNotEmpty) {
           // Save to unsold subcollection
           FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("unsoldPlayers").doc(_currentPlayerId).set({
              "name": _currentPlayerName,
              "basePrice": _currentPlayerBasePrice,
              "role": _currentPlayerRole,
              "nationality": _currentPlayerNationality,
              "imageUrl": _currentPlayerImage,
           });
       }
    }

    // Automatically select next player after 4 seconds
    if (widget.isHost) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) _startAuction();
      });
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _spotlightController.dispose();
    _playerNameController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _joinLobby() async {
    if (_playerNameController.text.isEmpty || _selectedTeam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter name and select a team!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }

    HapticFeedback.heavyImpact();
    
    // Double validation protection
    var doc = await FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("participants").doc(_selectedTeam).get();
    if (doc.exists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team already selected by another player', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      setState(() => _selectedTeam = "");
      return;
    }

    _playerName = _playerNameController.text;

    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("activity").add({
       "text": "$_playerName joined as $_selectedTeam",
       "timestamp": FieldValue.serverTimestamp(),
       "type": "system",
    });

    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("participants").doc(_selectedTeam).set({
      "team": _selectedTeam,
      "playerName": _playerName,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() {
      _hasJoined = true;
    });
  }

  void _startAuction() async {
    // 1. Fetch available players
    var playersSnap = await FirebaseFirestore.instance.collection("players").get();
    var soldSnap = await FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("soldPlayers").get();
    var unsoldSnap = await FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("unsoldPlayers").get();
    
    Set<String> processedIds = soldSnap.docs.map((d) => d.id).toSet();
    processedIds.addAll(unsoldSnap.docs.map((d) => d.id).toSet());
    List<QueryDocumentSnapshot> available = playersSnap.docs.where((p) => !processedIds.contains(p.id)).toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No more players available!")));
      }
      return;
    }

    // 2. Randomly select one
    var randomPlayer = available[Random().nextInt(available.length)];
    var data = randomPlayer.data() as Map<String, dynamic>;

    // 3. Update room
    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).update({
      "auctionStarted": true,
      "currentPlayerId": randomPlayer.id,
      "currentPlayerName": data["name"] ?? "Unknown",
      "currentPlayerRole": data["role"] ?? "Unknown",
      "currentPlayerNationality": data["nationality"] ?? "Unknown",
      "currentPlayerImage": data["imageUrl"] ?? "https://via.placeholder.com/150",
      "currentPlayerBasePrice": data["basePrice"] ?? 0,
      "currentBid": data["basePrice"] ?? 0,
      "highestBidder": "",
      "sold": false,
      "endTimeEpoch": DateTime.now().millisecondsSinceEpoch + (_timerSetting * 1000),
    });

    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("activity").add({
       "text": "Auction started for ${data['name']}",
       "timestamp": FieldValue.serverTimestamp(),
       "type": "system",
    });
  }

  void _placeBid(int amount) {
    if (_sold || !_auctionStarted) return;
    
    int newBid = _currentBid + amount;
    
    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).update({
      "currentBid": newBid,
      "highestBidder": _selectedTeam,
      "endTimeEpoch": DateTime.now().millisecondsSinceEpoch + (_timerSetting * 1000), // Reset timer on bid
    });
    
    String formattedBid = amount >= 10000000 ? "${amount ~/ 10000000} Cr" : "${amount ~/ 100000}L";
    
    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("activity").add({
       "text": "$_selectedTeam bid +$formattedBid for $_currentPlayerName. Total: ₹${(newBid / 10000000).toStringAsFixed(2)} Cr",
       "timestamp": FieldValue.serverTimestamp(),
       "type": "bid",
    });
    
    // System sound or haptics mimicking the 'Bip'
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }
  
  void _sendChat() {
    if (_chatController.text.isEmpty) return;
    FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("activity").add({
       "text": "$_playerName: ${_chatController.text}",
       "timestamp": FieldValue.serverTimestamp(),
       "type": "chat",
    });
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06), 
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(),
          
          SafeArea(
            child: !_hasJoined ? _buildJoinPopup() : _buildMainLobby(),
          ),
          
          // Confetti / Sold Badge Overlay
          if (_sold && _hasJoined && _auctionStarted && _currentPlayerName != "Waiting for Host...")
            IgnorePointer(
               child: Container(
                  color: Colors.black54,
                  child: Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Text("SOLD", style: TextStyle(color: Colors.redAccent, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 8, shadows: [Shadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 5))])),
                         const SizedBox(height: 16),
                         Text(_highestBidder.isNotEmpty ? "To $_highestBidder" : "UNSOLD", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
                       ],
                     ),
                  ),
               ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E1005), Color(0xFF0A0502)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            Positioned(
              top: -100 + (_bgController.value * 50),
              right: -150 + (_bgController.value * 100),
              child: Container(
                width: 500, height: 500,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFDAA520).withOpacity(0.15), Colors.transparent])),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJoinPopup() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x66FFD700), blurRadius: 30, spreadRadius: -5), BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2E1C0C), Color(0xFF1E1005)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: const Color(0xFFDAA520).withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gavel_rounded, color: Color(0xFFFFD700), size: 48),
                    const SizedBox(height: 16),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text("Join Auction Lobby", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 30),
                    
                    TextField(
                      controller: _playerNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Enter Player Name",
                        labelStyle: const TextStyle(color: Color(0xFFDAA520)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFFDAA520)),
                        filled: true, fillColor: Colors.black45,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text("Select Franchise", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("participants").snapshots(),
                        builder: (context, snapshot) {
                          Set<String> takenTeams = {};
                          if (snapshot.hasData) {
                            takenTeams = snapshot.data!.docs.map((d) => d["team"] as String).toSet();
                          }
                          
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5, 
                              mainAxisSpacing: 10, 
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: iplTeams.length,
                            itemBuilder: (context, index) {
                              String t = iplTeams[index];
                              bool isSelected = _selectedTeam == t;
                              bool isLocked = takenTeams.contains(t) && !isSelected;
                              List<Color> colors = teamColors[t] ?? [Colors.grey, Colors.blueGrey];
                              
                              return GestureDetector(
                                onTap: isLocked ? null : () {
                                  setState(() => _selectedTeam = t);
                                  HapticFeedback.selectionClick();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isLocked 
                                      ? const LinearGradient(colors: [Colors.black26, Colors.black38])
                                      : LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    border: Border.all(color: isSelected ? Colors.white : (isLocked ? Colors.transparent : Colors.white24), width: isSelected ? 3 : 1),
                                    boxShadow: isSelected ? [BoxShadow(color: colors[0], blurRadius: 15, spreadRadius: 4)] : [],
                                  ),
                                  child: Center(
                                    child: Opacity(
                                      opacity: isLocked ? 0.3 : 1.0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          if (isLocked) const Text("Taken", style: TextStyle(color: Colors.white54, fontSize: 8)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      ),
                    
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700), foregroundColor: const Color(0xFF1E1005),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 10, shadowColor: const Color(0xFFFFD700),
                        ),
                        onPressed: _joinLobby,
                        child: const Text("JOIN AUCTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                      ),
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

  Widget _buildMainLobby() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.exit_to_app, color: Colors.white54), onPressed: () => Navigator.pop(context)),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text("ROOM: ${widget.roomId}", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.isHost) 
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: !_auctionStarted || _sold ? Colors.green : Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _auctionStarted && !_sold ? null : _startAuction,
                  child: Text(!_auctionStarted ? "START AUCTION" : (_sold ? "WAITING..." : "LIVE"), style: const TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
        
        _buildActiveParticipantsRow(),
        const SizedBox(height: 8),

        Expanded(flex: 4, child: _buildAuctionStage()),
        Expanded(flex: 5, child: _buildInteractionPanel()),
      ],
    );
  }

  Widget _buildActiveParticipantsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("participants").orderBy("timestamp").limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        
        var docs = snapshot.data!.docs;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: docs.map((d) {
                String team = d["team"] ?? "";
                String pName = d["playerName"] ?? "";
                bool isHighest = team == _highestBidder;
                List<Color> c = teamColors[team] ?? [Colors.grey, Colors.blueGrey];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 55, height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: c),
                          border: Border.all(color: isHighest ? Colors.white : Colors.transparent, width: isHighest ? 3 : 0),
                          boxShadow: [BoxShadow(color: c[0].withOpacity(isHighest ? 0.8 : 0.4), blurRadius: isHighest ? 15 : 8, spreadRadius: isHighest ? 4 : 1)],
                        ),
                        child: Center(
                          child: Text(team, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        child: Text(pName, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuctionStage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1005).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDAA520).withOpacity(0.3)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
           Expanded(
             child: Stack(
               alignment: Alignment.center,
               children: [
                  AnimatedBuilder(
                    animation: _spotlightController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _auctionStarted ? (0.5 + (_spotlightController.value * 0.5)) : 0.0,
                        child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x66FFD700), blurRadius: 50, spreadRadius: 10)])),
                      );
                    }
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Container(
                         width: 100, height: 100,
                         decoration: BoxDecoration(
                           color: Colors.black, shape: BoxShape.circle,
                           border: Border.all(color: const Color(0xFFFFD700), width: 2),
                           image: DecorationImage(image: NetworkImage(_currentPlayerImage.isNotEmpty ? _currentPlayerImage : "https://via.placeholder.com/150"), fit: BoxFit.cover),
                         ),
                       ),
                       const SizedBox(height: 12),
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         child: FittedBox(
                           fit: BoxFit.scaleDown,
                           child: Text(_currentPlayerName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                         ),
                       ),
                       const SizedBox(height: 4),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           if (_currentPlayerRole.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blueAccent)), child: Text(_currentPlayerRole.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontSize: 10))),
                           const SizedBox(width: 8),
                           if (_currentPlayerNationality.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green)), child: Text(_currentPlayerNationality.toUpperCase(), style: const TextStyle(color: Colors.green, fontSize: 10))),
                         ],
                       )
                    ],
                  ),
                  Positioned(top: 10, right: 10, child: _buildHighestBidderTag()),
                  Positioned(top: 10, left: 10, child: _buildTimerTag()),
               ],
             ),
           ),
           
           Container(
             padding: const EdgeInsets.all(16),
             decoration: const BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
             child: Column(
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("CURRENT BID", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text("₹${(_currentBid / 10000000).toStringAsFixed(2)} Cr", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 26, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bid Action Bar
                      if (_auctionStarted && !_sold)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                               _buildBidButton("+10L", 1000000),
                               const SizedBox(width: 4),
                               _buildBidButton("+50L", 5000000),
                               const SizedBox(width: 4),
                               _buildBidButton("+1Cr", 10000000),
                            ],
                          ),
                        )
                   ],
                 ),
                 const SizedBox(height: 12),
                 LinearProgressIndicator(
                   value: _timerSetting > 0 ? (_remainingTime / _timerSetting).clamp(0.0, 1.0) : 0,
                   backgroundColor: Colors.white12,
                   valueColor: AlwaysStoppedAnimation<Color>((_remainingTime) <= 5 ? Colors.red : const Color(0xFFDAA520)),
                   minHeight: 6,
                   borderRadius: BorderRadius.circular(3),
                 ),
                 const SizedBox(height: 8),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text("Purse Remaining: ₹100.0 Cr", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                     Text("Status: ${_sold ? 'SOLD' : (_auctionStarted ? 'LIVE' : 'WAITING')}", style: TextStyle(color: _sold ? Colors.red : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                   ],
                 )
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildBidButton(String label, int amount) {
    return InkWell(
      onTap: () => _placeBid(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
           color: const Color(0xFFFFD700),
           borderRadius: BorderRadius.circular(8),
           boxShadow: const [BoxShadow(color: Color(0x66FFD700), blurRadius: 5)],
        ),
        child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildHighestBidderTag() {
    if (_highestBidder.isEmpty) return const SizedBox.shrink();
    List<Color> c = teamColors[_highestBidder] ?? [const Color(0xFFDAA520), const Color(0xFFB8860B)];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: c), 
        borderRadius: BorderRadius.circular(8), 
        boxShadow: [BoxShadow(color: c[0].withOpacity(0.6), blurRadius: 12, spreadRadius: 2)]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text("$_highestBidder bidding", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimerTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black54, border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text("${_remainingTime}s", style: TextStyle(color: _remainingTime <= 5 ? Colors.red : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInteractionPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF140B05),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, -5))],
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Color(0xFFFFD700), labelColor: Color(0xFFFFD700), unselectedLabelColor: Colors.white54,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), isScrollable: true,
              tabs: [
                Tab(text: "ACTIVITY", icon: Icon(Icons.chat_bubble_outline, size: 18)),
                Tab(text: "STATS", icon: Icon(Icons.bar_chart, size: 18)),
                Tab(text: "SQUAD", icon: Icon(Icons.shield_outlined, size: 18)),
                Tab(text: "SETTINGS", icon: Icon(Icons.settings_outlined, size: 18)),
              ],
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: TabBarView(
                children: [
                  _buildActivityTab(),
                  _buildStatsTab(),
                  _buildSquadTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("activity").orderBy("timestamp", descending: true).limit(5).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
              var docs = snapshot.data!.docs.reversed.toList();
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String text = data["text"] ?? "";
                  String type = data["type"] ?? "system";
                  
                  Color bgColor; Color textColor;
                  if (type == "bid") { bgColor = const Color(0xFFDAA520).withOpacity(0.2); textColor = const Color(0xFFFFD700); } 
                  else if (type == "system") { bgColor = Colors.white.withOpacity(0.05); textColor = Colors.white54; } 
                  else { bgColor = const Color(0xFF4169E1).withOpacity(0.2); textColor = Colors.white; }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: textColor.withOpacity(0.3))),
                    child: Text(text, style: TextStyle(color: textColor, fontSize: 13)),
                  );
                },
              );
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Colors.black54, border: Border(top: BorderSide(color: Colors.white12))),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.gif_box_outlined, color: Color(0xFFDAA520)), onPressed: (){}),
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Message the lobby...", hintStyle: const TextStyle(color: Colors.white38),
                    filled: true, fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendChat,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFFD700), shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.black87, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.black26,
            child: const TabBar(
              isScrollable: true, indicatorColor: Colors.transparent, labelColor: Colors.white, unselectedLabelColor: Colors.white38,
              tabs: [Tab(text: "Upcoming"), Tab(text: "Sold"), Tab(text: "Unsold"), Tab(text: "Leaderboard")],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                 _buildUpcomingView(),
                 _buildSoldPlayersView(),
                 _buildUnsoldPlayersView(),
                 _buildLeaderboardView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpcomingView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent.withOpacity(0.5))),
          child: const Text("Upcoming players will be chosen randomly from each set during the auction.", style: TextStyle(color: Colors.blueAccent, fontSize: 12), textAlign: TextAlign.center),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("players").snapshots(),
            builder: (context, playersSnapshot) {
              if (!playersSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("soldPlayers").snapshots(),
                builder: (context, soldSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("unsoldPlayers").snapshots(),
                    builder: (context, unsoldSnapshot) {
                      if (!soldSnapshot.hasData || !unsoldSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                      
                      Set<String> processedIds = {};
                      processedIds.addAll(soldSnapshot.data!.docs.map((d) => d.id));
                      processedIds.addAll(unsoldSnapshot.data!.docs.map((d) => d.id));
                      
                      var upcomingPlayers = playersSnapshot.data!.docs.where((p) => !processedIds.contains(p.id) && p.id != _currentPlayerId).toList();

                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 110, 
                          childAspectRatio: 0.65, 
                          crossAxisSpacing: 10, 
                          mainAxisSpacing: 10
                        ),
                        itemCount: upcomingPlayers.length,
                        itemBuilder: (context, index) {
                          var p = upcomingPlayers[index].data() as Map<String, dynamic>;
                          return PlayerGridCard(player: p, status: "");
                        },
                      );
                    }
                  );
                }
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSoldPlayersView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("soldPlayers").orderBy("price", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No sold players yet.", style: TextStyle(color: Colors.white54)));
        
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110, 
            childAspectRatio: 0.65, 
            crossAxisSpacing: 10, 
            mainAxisSpacing: 10
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return PlayerGridCard(player: data, status: "SOLD");
          },
        );
      },
    );
  }

  Widget _buildPlaceholderList(String title) {
    return Center(child: Text("$title List Empty", style: const TextStyle(color: Colors.white38)));
  }

  Widget _buildUnsoldPlayersView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("unsoldPlayers").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No unsold players yet.", style: TextStyle(color: Colors.white54)));
        
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110, 
            childAspectRatio: 0.65, 
            crossAxisSpacing: 10, 
            mainAxisSpacing: 10
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return PlayerGridCard(player: data, status: "UNSOLD");
          },
        );
      },
    );
  }

  Widget _buildLeaderboardView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("soldPlayers").orderBy("price", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No sold players yet.", style: TextStyle(color: Colors.white54)));
        
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1E1005).withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDAA520).withOpacity(0.4))),
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(12), width: double.infinity, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFDAA520), width: 1))), child: const Text("Most Expensive Buys", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center)),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Text("${index + 1}.", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
                      title: Text(data["name"] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(data["team"] ?? "Unknown", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: Text("₹${(data["price"]/10000000).toStringAsFixed(2)} Cr", style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquadTab() {
    if (_selectedTeam.isEmpty || _selectedTeam == "Host") return const Center(child: Text("Hosts do not have a squad.", style: TextStyle(color: Colors.white54)));
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).collection("soldPlayers").where("team", isEqualTo: _selectedTeam).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Your Squad • $_selectedTeam", style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(data["name"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(data["role"], style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
                       ],
                     ),
                     Text("₹${(data["price"]/10000000).toStringAsFixed(2)} Cr", style: const TextStyle(color: Color(0xFFDAA520), fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList()
          ],
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    if (!widget.isHost) {
      return const Center(child: Text("Only the Host can access settings.", style: TextStyle(color: Colors.white54)));
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Host Controls", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ListTile(
          title: const Text("Bid Timer Duration", style: TextStyle(color: Colors.white)),
          subtitle: const Text("Updates dynamically for everyone", style: TextStyle(color: Colors.white54)),
          trailing: DropdownButton<int>(
            dropdownColor: const Color(0xFF1E1005),
            value: _timerSetting,
            items: [30, 25, 20, 15, 5].map((v) => DropdownMenuItem(value: v, child: Text("$v sec", style: const TextStyle(color: Color(0xFFFFD700))))).toList(),
            onChanged: (val) {
              if (val != null) {
                FirebaseFirestore.instance.collection("rooms").doc(widget.roomId).update({"timerSetting": val});
                HapticFeedback.selectionClick();
              }
            },
          ),
        ),
      ],
    );
  }
}

class PlayerGridCard extends StatefulWidget {
  final Map<String, dynamic> player;
  final String status; // "", "SOLD", "UNSOLD"
  const PlayerGridCard({super.key, required this.player, this.status = ""});

  @override
  State<PlayerGridCard> createState() => _PlayerGridCardState();
}

class _PlayerGridCardState extends State<PlayerGridCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDAA520).withOpacity(0.6)),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.15), blurRadius: 10, spreadRadius: 1)
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Stack(
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       if (widget.player["imageUrl"] != null && widget.player["imageUrl"].toString().isNotEmpty)
                         Expanded(
                           flex: 2,
                           child: Image.network(
                             widget.player["imageUrl"],
                             fit: BoxFit.cover,
                             errorBuilder: (context, error, stackTrace) => Container(color: Colors.black45, child: const Icon(Icons.person, color: Colors.white54, size: 24)),
                           ),
                         ),
                       Expanded(
                         flex: 4,
                         child: Padding(
                           padding: const EdgeInsets.all(4.0),
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: [
                               Text(widget.player["name"] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                     decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blueAccent.withOpacity(0.5))),
                                     child: Text(widget.player["role"]?.toString().substring(0,3).toUpperCase() ?? "N/A", style: const TextStyle(color: Colors.blueAccent, fontSize: 7, fontWeight: FontWeight.bold)),
                                   ),
                                   const SizedBox(width: 4),
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                     decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.withOpacity(0.5))),
                                     child: Text((widget.player["nationality"] ?? "N/A").toUpperCase() == "INDIAN" ? "IND" : "OVS", style: const TextStyle(color: Colors.green, fontSize: 7, fontWeight: FontWeight.bold)),
                                   ),
                                 ],
                               ),
                               Text("Base: ₹${((widget.player["basePrice"]??0)/10000000).toStringAsFixed(2)} Cr", style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 8)),
                             ],
                           ),
                         ),
                       ),
                     ],
                   ),
                   if (widget.status == "SOLD")
                     Positioned(
                       top: 4, right: 4,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                         decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                         child: const Text("SOLD", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                       )
                     ),
                   if (widget.status == "UNSOLD")
                     Positioned(
                       top: 4, right: 4,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                         decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                         child: const Text("UNSOLD", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                       )
                     ),
                ]
              ),
            ),
          ),
        ),
      ),
    );
  }
}