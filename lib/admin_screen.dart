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
  final TextEditingController _basePriceCtrl = TextEditingController(text: "2000000"); // 20 Lakhs
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

    await FirebaseFirestore.instance.collection("players").add({
      "name": _nameCtrl.text.trim(),
      "role": _role,
      "nationality": _nationality,
      "basePrice": int.tryParse(_basePriceCtrl.text) ?? 2000000,
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
              _buildInput("Base Price (₹)", _basePriceCtrl, true),
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
}
