import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _baseAmountCtrl = TextEditingController(text: "20");
  String _baseUnit = "Lakhs";
  final TextEditingController _matchesCtrl = TextEditingController(text: "0");
  final TextEditingController _runsCtrl = TextEditingController(text: "0");
  final TextEditingController _wicketsCtrl = TextEditingController(text: "0");
  final TextEditingController _srCtrl = TextEditingController(text: "0.0");
  final TextEditingController _avgCtrl = TextEditingController(text: "0.0");
  final TextEditingController _imgUrlCtrl = TextEditingController(text: "https://via.placeholder.com/150");

  String _role = "Batsman";
  String _nationality = "Indian";

  bool _isLoading = false;

  Future<void> _addPlayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    int baseAmount = int.tryParse(_baseAmountCtrl.text) ?? 20;
    int calculatedBasePrice = _baseUnit == "Crores" ? baseAmount * 10000000 : baseAmount * 100000;

    await FirebaseFirestore.instance.collection("players").add({
      "name": _nameCtrl.text.trim(),
      "role": _role,
      "nationality": _nationality,
      "basePrice": calculatedBasePrice,
      "imageUrl": _imgUrlCtrl.text.trim(),
      "matches": int.tryParse(_matchesCtrl.text) ?? 0,
      "runs": int.tryParse(_runsCtrl.text) ?? 0,
      "wickets": int.tryParse(_wicketsCtrl.text) ?? 0,
      "strikeRate": double.tryParse(_srCtrl.text) ?? 0.0,
      "average": double.tryParse(_avgCtrl.text) ?? 0.0,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Player added successfully!"),
      backgroundColor: Colors.green,
    ));

    _nameCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
      appBar: AppBar(
        title: const Text("ADMIN: Add IPL Player", style: TextStyle(color: Color(0xFFFFD700))),
        backgroundColor: const Color(0xFF1E1005),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput("Player Name", _nameCtrl, false),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _role,
                      dropdownColor: const Color(0xFF1E1005),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Role", labelStyle: const TextStyle(color: Color(0xFFDAA520)),
                        filled: true, fillColor: Colors.black45,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ["Batsman", "Bowler", "All-Rounder", "Wicket Keeper"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _role = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _nationality,
                      dropdownColor: const Color(0xFF1E1005),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Nationality", labelStyle: const TextStyle(color: Color(0xFFDAA520)),
                        filled: true, fillColor: Colors.black45,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ["Indian", "Overseas"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _nationality = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(flex: 2, child: _buildInput("Base Amount", _baseAmountCtrl, true)),
                   const SizedBox(width: 16),
                   Expanded(
                     flex: 1,
                     child: DropdownButtonFormField<String>(
                       value: _baseUnit,
                       dropdownColor: const Color(0xFF1E1005),
                       style: const TextStyle(color: Colors.white),
                       decoration: InputDecoration(
                         labelText: "Unit", labelStyle: const TextStyle(color: Color(0xFFDAA520)),
                         filled: true, fillColor: Colors.black45,
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       items: ["Lakhs", "Crores"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                       onChanged: (val) => setState(() => _baseUnit = val!),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput("Image URL", _imgUrlCtrl, false),
              
              const SizedBox(height: 24),
              const Text("PLAYER STATS", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const Divider(color: Color(0xFFDAA520)),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildInput("Matches", _matchesCtrl, true)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildInput("Runs", _runsCtrl, true)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildInput("Wickets", _wicketsCtrl, true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildInput("Strike Rate", _srCtrl, true)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildInput("Average", _avgCtrl, true)),
                ],
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF1E1005),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _addPlayer,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text("ADD STRATEGIC PLAYER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 40),
              const Text("MANAGE STRATEGIC PLAYERS", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const Divider(color: Color(0xFFDAA520)),
              const SizedBox(height: 16),
              _buildPlayerList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, bool isNumber) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFDAA520)),
        filled: true,
        fillColor: Colors.black45,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
      ),
    );
  }

  Widget _buildPlayerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("players").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        if (snapshot.data!.docs.isEmpty) return const Text("No players found.", style: TextStyle(color: Colors.white54));
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(data["imageUrl"] ?? "https://via.placeholder.com/150")),
                title: Text(data["name"] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("${data['role']} • ₹${((data['basePrice'] ?? 0) / 10000000).toStringAsFixed(2)} Cr", style: const TextStyle(color: Colors.white54)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showEditDialog(doc)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deletePlayer(doc.id)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deletePlayer(String docId) async {
    bool? conf = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1005),
        title: const Text("Delete Player?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ]
      )
    );
    if (conf == true) {
      FirebaseFirestore.instance.collection("players").doc(docId).delete();
    }
  }

  void _showEditDialog(QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    TextEditingController nameCtrl = TextEditingController(text: data["name"]);
    TextEditingController basePriceCtrl = TextEditingController(text: (data["basePrice"] ?? 0).toString());
    TextEditingController imgUrlCtrl = TextEditingController(text: data["imageUrl"]);
    String role = data["role"] ?? "Batsman";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1005),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Player", style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Name", labelStyle: TextStyle(color: Colors.white54))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                dropdownColor: const Color(0xFF1E1005),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Role", labelStyle: TextStyle(color: Colors.white54)),
                items: ["Batsman", "Bowler", "All-Rounder", "Wicket Keeper"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => role = v!,
              ),
              const SizedBox(height: 16),
              TextField(controller: basePriceCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Base Price (Full Amount ₹)", labelStyle: TextStyle(color: Colors.white54))),
              const SizedBox(height: 16),
              TextField(controller: imgUrlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Image URL", labelStyle: TextStyle(color: Colors.white54))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
                  onPressed: () {
                    FirebaseFirestore.instance.collection("players").doc(doc.id).update({
                      "name": nameCtrl.text.trim(),
                      "role": role,
                      "basePrice": int.tryParse(basePriceCtrl.text) ?? 0,
                      "imageUrl": imgUrlCtrl.text.trim(),
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Save Changes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ]
          )
        );
      }
    );
  }
}
