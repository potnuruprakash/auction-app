import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  Design constants
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const kGold = Color(0xFFFFD700);
const kGoldDark = Color(0xFFB8860B);
const kBgDark = Color(0xFF0A0010);
const kPurpleDark = Color(0xFF1A0035);
const kGlassColor = Color(0x1AFFFFFF);
const kGlassBorder = Color(0x40FFD700);

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  AdminScreen â€“ entry widget
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ background gradient
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBgDark, kPurpleDark, Color(0xFF0D0020)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: isWide
                ? _buildWideLayout()
                : _buildNarrowLayout(),
          ),
        ],
      ),
    );
  }

  // â”€â”€ WIDE: left sidebar + tab content
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Sidebar
        _GlassCard(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 24),
                child: Text(
                  'ADMIN\nPANEL',
                  style: TextStyle(
                    color: kGold,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    height: 1.3,
                  ),
                ),
              ),
              _SidebarTile(
                icon: Icons.person_add_alt_1,
                label: 'Add Player',
                index: 0,
                controller: _tabCtrl,
              ),
              _SidebarTile(
                icon: Icons.manage_accounts,
                label: 'Manage Players',
                index: 1,
                controller: _tabCtrl,
              ),
              _SidebarTile(
                icon: Icons.file_upload_outlined,
                label: 'Import Players',
                index: 2,
                controller: _tabCtrl,
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              _AddPlayerTab(),
              _ModifyPlayerTab(),
              _ImportPlayersTab(),
            ],
          ),
        ),
      ],
    );
  }

  // â”€â”€ NARROW: top tab bar
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: kGold),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'ADMIN PANEL',
                style: TextStyle(
                  color: kGold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        // Tab bar
        _GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: EdgeInsets.zero,
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: kGold,
            indicatorWeight: 2,
            labelColor: kGold,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            tabs: const [
              Tab(icon: Icon(Icons.person_add_alt_1, size: 18), text: 'Add'),
              Tab(icon: Icon(Icons.manage_accounts, size: 18), text: 'Manage'),
              Tab(icon: Icon(Icons.upload_file_outlined, size: 18), text: 'Import'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              _AddPlayerTab(),
              _ModifyPlayerTab(),
              _ImportPlayersTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  TAB 1 â€“ Add Player
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _AddPlayerTab extends StatefulWidget {
  const _AddPlayerTab();
  @override
  State<_AddPlayerTab> createState() => _AddPlayerTabState();
}

class _AddPlayerTabState extends State<_AddPlayerTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _baseAmountCtrl = TextEditingController(text: '20');
  final _imgCtrl = TextEditingController(text: 'https://via.placeholder.com/150');
  final _matchesCtrl = TextEditingController(text: '0');
  final _runsCtrl = TextEditingController(text: '0');
  final _wicketsCtrl = TextEditingController(text: '0');
  final _srCtrl = TextEditingController(text: '0.0');
  final _avgCtrl = TextEditingController(text: '0.0');
  final _economyCtrl = TextEditingController(text: '0.0');
  final _fieldingCtrl = TextEditingController(text: '0');
  String _role = 'Batsman';
  String _nationality = 'Indian';
  String _unit = 'Lakhs';
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    final base = int.tryParse(_baseAmountCtrl.text) ?? 20;
    final price = _unit == 'Crores' ? base * 10000000 : base * 100000;
    await FirebaseFirestore.instance.collection('players').add({
      'name': _nameCtrl.text.trim(),
      'role': _role,
      'nationality': _nationality,
      'basePrice': price,
      'imageUrl': _imgCtrl.text.trim(),
      'matches': int.tryParse(_matchesCtrl.text) ?? 0,
      'runs': int.tryParse(_runsCtrl.text) ?? 0,
      'wickets': int.tryParse(_wicketsCtrl.text) ?? 0,
      'strikeRate': double.tryParse(_srCtrl.text) ?? 0.0,
      'average': double.tryParse(_avgCtrl.text) ?? 0.0,
      'economy': double.tryParse(_economyCtrl.text) ?? 0.0,
      'fielding': int.tryParse(_fieldingCtrl.text) ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    _nameCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Player added!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Add New Player'),
            const SizedBox(height: 16),
            _GlassCard(
              child: Column(
                children: [
                  // Basic info - responsive grid
                  isWide
                      ? Row(children: [
                          Expanded(child: _field('Player Name', _nameCtrl, false, required: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _field('Image URL', _imgCtrl, false)),
                        ])
                      : Column(children: [
                          _field('Player Name', _nameCtrl, false, required: true),
                          const SizedBox(height: 12),
                          _field('Image URL', _imgCtrl, false),
                        ]),
                  const SizedBox(height: 16),
                  isWide
                      ? Row(children: [
                          Expanded(child: _dropdown('Role', _role, ['Batsman', 'Bowler', 'All-Rounder', 'Wicket Keeper'], (v) => setState(() => _role = v!))),
                          const SizedBox(width: 16),
                          Expanded(child: _dropdown('Nationality', _nationality, ['Indian', 'Overseas'], (v) => setState(() => _nationality = v!))),
                        ])
                      : Column(children: [
                          _dropdown('Role', _role, ['Batsman', 'Bowler', 'All-Rounder', 'Wicket Keeper'], (v) => setState(() => _role = v!)),
                          const SizedBox(height: 12),
                          _dropdown('Nationality', _nationality, ['Indian', 'Overseas'], (v) => setState(() => _nationality = v!)),
                        ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(flex: 2, child: _field('Base Amount', _baseAmountCtrl, true)),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: _dropdown('Unit', _unit, ['Lakhs', 'Crores'], (v) => setState(() => _unit = v!))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Player Stats'),
            const SizedBox(height: 12),
            _GlassCard(
              child: isWide
                  ? Column(children: [
                      Row(children: [
                        Expanded(child: _field('Matches', _matchesCtrl, true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Runs', _runsCtrl, true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Wickets', _wicketsCtrl, true)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _field('Strike Rate', _srCtrl, true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Average', _avgCtrl, true)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _field('Economy', _economyCtrl, true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Catches/Stumping', _fieldingCtrl, true)),
                      ]),
                    ])
                  : Column(children: [
                      _field('Matches', _matchesCtrl, true),
                      const SizedBox(height: 12),
                      _field('Runs', _runsCtrl, true),
                      const SizedBox(height: 12),
                      _field('Wickets', _wicketsCtrl, true),
                      const SizedBox(height: 12),
                      _field('Strike Rate', _srCtrl, true),
                      const SizedBox(height: 12),
                      _field('Average', _avgCtrl, true),
                      const SizedBox(height: 12),
                      _field('Economy', _economyCtrl, true),
                      const SizedBox(height: 12),
                      _field('Catches/Stumping', _fieldingCtrl, true),
                    ]),
            ),
            const SizedBox(height: 24),
            _GoldButton(
              label: 'ADD PLAYER',
              icon: Icons.add_circle_outline,
              loading: _loading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, bool numeric, {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      decoration: _inputDeco(label),
    );
  }

  Widget _dropdown(String label, String val, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: val,
      dropdownColor: kPurpleDark,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  TAB 2 â€“ Modify / Manage Players
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ModifyPlayerTab extends StatefulWidget {
  const _ModifyPlayerTab();
  @override
  State<_ModifyPlayerTab> createState() => _ModifyPlayerTabState();
}

class _ModifyPlayerTabState extends State<_ModifyPlayerTab> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  Future<void> _deletePlayer(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPurpleDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Player', style: TextStyle(color: kGold)),
        content: Text('Delete $name?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('players').doc(id).delete();
    }
  }
  
  @override
  void initState() {
  super.initState();
  deleteDummyPlayers();
}
  Future<void> deleteDummyPlayers() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('players').get();

  final batch = FirebaseFirestore.instance.batch();

  for (var doc in snapshot.docs) {
    final data = doc.data();

    if ((data['name'] ?? '').toString().startsWith("Player_")) {
      batch.delete(doc.reference);
    }
  }

  await batch.commit();
}

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPurpleDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete ALL Players', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete every player. Are you sure?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE ALL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final snapshot = await FirebaseFirestore.instance.collection('players').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All players deleted.'), backgroundColor: Colors.red),
      );
    }
  }

  void _editPlayer(BuildContext ctx, String docId, Map<String, dynamic> data) {
  final nameCtrl = TextEditingController(text: data['name'] ?? '');
  final imgCtrl = TextEditingController(text: data['imageUrl'] ?? '');
  final economyCtrl = TextEditingController(text: (data['economy'] ?? 0.0).toString());
  final fieldingCtrl = TextEditingController(text: (data['fielding'] ?? 0).toString());

  String role = (data['role'] ?? 'Batsman').toString();

  // Normalize role to match dropdown values
  if (role.toUpperCase() == 'ALL-ROUNDER') role = 'All-Rounder';
  if (role.toUpperCase() == 'WICKETKEEPER') role = 'Wicket Keeper';

  const roleOptions = [
    'Batsman',
    'Bowler',
    'All-Rounder',
    'Wicket Keeper'
  ];

  if (!roleOptions.contains(role)) {
    role = 'Batsman';
  }
    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (sCtx, setSt) => AlertDialog(
          backgroundColor: kPurpleDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Player', style: TextStyle(color: kGold, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _styledField('Name', nameCtrl),
                const SizedBox(height: 12),
                _styledField('Image URL', imgCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _styledField('Economy', economyCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _styledField('Catches', fieldingCtrl)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: kPurpleDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Role'),
                  items: ['Batsman', 'Bowler', 'All-Rounder', 'Wicket Keeper']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setSt(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(sCtx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('players').doc(docId).update({
                  'name': nameCtrl.text.trim(),
                  'imageUrl': imgCtrl.text.trim(),
                  'role': role,
                  'economy': double.tryParse(economyCtrl.text) ?? 0.0,
                  'fielding': int.tryParse(fieldingCtrl.text) ?? 0,
                });
                if (mounted) Navigator.pop(sCtx);
              },
              child: const Text('Save', style: TextStyle(color: kGold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Responsive column counts: mobile=2, tablet=3, desktop=4-5
    int crossAxis = width >= 1000 ? (width >= 1400 ? 5 : 4) : (width >= 600 ? 3 : 2);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // â”€â”€ Search + Delete All row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Search player by name').copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: const Icon(Icons.search, color: kGold, size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            })
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Delete All Players',
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    backgroundColor: Colors.red.withOpacity(0.12),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
                    ),
                  ),
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: Text(width < 500 ? '' : 'Delete All'),
                  onPressed: _deleteAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // â”€â”€ Player Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('players').orderBy('name').snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kGold));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No players found.',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15))
                  );
                }
                final docs = snap.data!.docs.where((d) {
                   final data = d.data() as Map<String, dynamic>;
                   final name = (data['name'] ?? '').toString();

                   // Hide dummy players
                   if (name.startsWith("Player_")) {
                     return false;
                   }

                   return name.toLowerCase().contains(_search);
                }).toList();
                if (docs.isEmpty) {
                  return Center(child: Text('No matches for "$_search"',
                      style: const TextStyle(color: Colors.white54, fontSize: 14)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    // Compact aspect ratio ~175 px tall
                    childAspectRatio: 0.72,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final basePrice = data['basePrice'] as int? ?? 0;
                    final priceStr = basePrice >= 10000000
                        ? '\u20B9${(basePrice / 10000000).toStringAsFixed(1)} Cr'
                        : '\u20B9${(basePrice / 100000).toStringAsFixed(0)} L';
                    return _PlayerCard(
                      name: data['name'] ?? 'Unknown',
                      role: data['role'] ?? '',
                      imageUrl: data['imageUrl'] ?? '',
                      basePrice: priceStr,
                      onEdit: () => _editPlayer(context, doc.id, data),
                      onDelete: () => _deletePlayer(doc.id, data['name'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  TAB 3 â€“ Import Players
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ImportPlayersTab extends StatefulWidget {
  const _ImportPlayersTab();
  @override
  State<_ImportPlayersTab> createState() => _ImportPlayersTabState();
}

class _ImportPlayersTabState extends State<_ImportPlayersTab> {
  bool _loading = false;
  String _status = '';
  double _progress = 0;
  String? _csvFileName;

  // â”€â”€ shared upload helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _uploadPlayers(List<Map<String, dynamic>> players) async {
    setState(() { _status = 'Checking Firestore...'; _progress = 0.1; });

    final existing = await FirebaseFirestore.instance.collection('players').get();

    // delete stale Player_N docs
    final stale = existing.docs.where((d) =>
        RegExp(r'^Player_\d+$').hasMatch(
            (d.data() as Map<String, dynamic>)['name']?.toString() ?? '')).toList();
    if (stale.isNotEmpty) {
      setState(() { _status = 'Removing ${stale.length} old placeholders...'; _progress = 0.15; });
      for (int i = 0; i < stale.length; i += 400) {
        final chunk = stale.sublist(i, (i + 400).clamp(0, stale.length));
        final b = FirebaseFirestore.instance.batch();
        for (final d in chunk) { b.delete(d.reference); }
        await b.commit();
      }
    }

    final freshSnap = await FirebaseFirestore.instance.collection('players').get();
    final existingNames = freshSnap.docs
        .map((d) => (d.data() as Map<String, dynamic>)['name'].toString().toLowerCase())
        .toSet();

    final toAdd = players.where((p) =>
        !existingNames.contains((p['name'] ?? '').toString().toLowerCase())).toList();
    final skipped = players.length - toAdd.length;

    setState(() { _status = 'Uploading ${toAdd.length} players...'; _progress = 0.3; });

    int added = 0;
    for (int i = 0; i < toAdd.length; i += 400) {
      final chunk = toAdd.sublist(i, (i + 400).clamp(0, toAdd.length));
      final b = FirebaseFirestore.instance.batch();
      for (final p in chunk) {
        b.set(FirebaseFirestore.instance.collection('players').doc(), p);
        added++;
      }
      await b.commit();
      setState(() { _progress = 0.3 + 0.7 * (i + chunk.length) / toAdd.length.clamp(1, 99999); });
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _progress = 1;
      _status = 'âœ… Done! Added $added players. Skipped $skipped duplicates.';
    });
  }

  // â”€â”€ CSV import â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _importFromCsv() async {
    import_file_picker();
  }

  void import_file_picker() async {
    setState(() { _status = ''; _csvFileName = null; });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      _csvFileName = file.name;
      setState(() { _loading = true; _status = 'Parsing ${file.name}...'; _progress = 0; });

      final csvText = String.fromCharCodes(file.bytes!);
      final lines = csvText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.length < 2) {
        setState(() { _loading = false; _status = 'âŒ CSV has no data rows.'; });
        return;
      }

      // Parse header
      final headers = _parseCsvLine(lines[0]).map((h) => h.trim().toLowerCase()).toList();
      final idx = (String key) => headers.indexOf(key);

      final players = <Map<String, dynamic>>[];
      for (int i = 1; i < lines.length; i++) {
        final cols = _parseCsvLine(lines[i]);
        if (cols.isEmpty) continue;
        String get(String key) {
          final i = idx(key);
          return (i >= 0 && i < cols.length) ? cols[i].trim() : '';
        }
        final name = get('name');
        if (name.isEmpty) continue;
        final baseStr = get('base_price').isEmpty ? get('baseprice') : get('base_price');
        final baseAmount = double.tryParse(baseStr) ?? 20.0;
        final unit = get('unit');
        final price = unit.toLowerCase() == 'cr'
            ? (baseAmount * 10000000).toInt()
            : (baseAmount * 100000).toInt();
        players.add({
          'name': name,
          'role': get('role').isEmpty ? 'Batsman' : get('role'),
          'nationality': get('nationality').isEmpty ? 'Indian' : get('nationality'),
          'basePrice': price,
          'imageUrl': get('image_url').isEmpty ? 'https://via.placeholder.com/150' : get('image_url'),
          'matches': int.tryParse(get('matches')) ?? 0,
          'runs': int.tryParse(get('runs')) ?? 0,
          'wickets': int.tryParse(get('wickets')) ?? 0,
          'strikeRate': double.tryParse(get('strike_rate').isEmpty ? get('strikerate') : get('strike_rate')) ?? 0.0,
          'average': double.tryParse(get('average')) ?? 0.0,
          'economy': double.tryParse(get('economy')) ?? 0.0,
          'fielding': int.tryParse(get('fielding').isEmpty ? get('catches') : get('fielding')) ?? 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      print("Total CSV lines: ${lines.length}");
      print("Parsed players: ${players.length}");
      setState(() { _status = 'Parsed ${players.length} rows from CSV.'; _progress = 0.05; });
      await _uploadPlayers(players);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _status = 'â Œ Error: $e'; });
    }
  }

  // naive CSV line parser (handles quoted commas)
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString());
    return result;
  }

  Widget _progressSection() {
    if (!_loading && _status.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        if (_loading)
          LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(kGold),
            borderRadius: BorderRadius.circular(8),
            minHeight: 6,
          ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 10),
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 300),
            child: Text(_status, style: TextStyle(
              color: _status.startsWith('âŒ') ? Colors.redAccent : Colors.greenAccent,
              fontSize: 13, fontWeight: FontWeight.w500,
            )),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Import Players'),
          const SizedBox(height: 6),
          Text('Bulk import players into Firestore. Duplicates are automatically skipped.',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),

          // â”€â”€ CSV card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.table_chart_outlined, color: kGold, size: 26),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Import from CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Pick a .csv file from your device', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  )),
                ]),
                const SizedBox(height: 8),
                // CSV format hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kGlassBorder),
                  ),
                  child: const Text(
                    'name, role, base_price, unit, matches, runs, wickets, average, strike_rate',
                    style: TextStyle(color: Color(0xFFDAA520), fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 14),
                if (_csvFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      const Icon(Icons.insert_drive_file_outlined, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_csvFileName!,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                _GoldButton(
                  label: 'PICK CSV & IMPORT',
                  icon: Icons.upload_file_outlined,
                  loading: _loading,
                  onTap: _importFromCsv,
                ),
                _progressSection(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // â”€â”€ CSV format guide card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.help_outline, color: kGold, size: 18),
                  SizedBox(width: 8),
                  Text('CSV Format Guide', style: TextStyle(color: kGold, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
                const SizedBox(height: 12),
                const Text('Row 1 must be the header:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    'name,role,base_price,unit,matches,runs,wickets,average,strike_rate\n'
                    'Virat Kohli,Batsman,2,Cr,237,7263,4,37.2,130.4\n'
                    'Jasprit Bumrah,Bowler,50,Lakh,120,0,145,0,0',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.7, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 10),
                ...[
                  ('role', 'Batsman / Bowler / All-Rounder / Wicketkeeper'),
                  ('unit', 'Cr or Lakh'),
                  ('base_price', 'number (e.g. 2 for 2 Cr, or 50 for 50 Lakh)'),
                ].map((e) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.circle, color: kGold, size: 6),
                    const SizedBox(width: 8),
                    RichText(text: TextSpan(children: [
                      TextSpan(text: '${e.$1}: ', style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.bold)),
                      TextSpan(text: e.$2, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ])),
                  ]),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  Reusable Widgets
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•


class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const _GlassCard({required this.child, this.width, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kGlassColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGlassBorder, width: 1),
              boxShadow: [
                BoxShadow(color: kGold.withOpacity(0.05), blurRadius: 20, spreadRadius: 1),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final TabController controller;

  const _SidebarTile({required this.icon, required this.label, required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final selected = controller.index == index;
        return InkWell(
          onTap: () => controller.animateTo(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? kGold.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: selected ? Border.all(color: kGold.withOpacity(0.4)) : null,
            ),
            child: Row(children: [
              Icon(icon, color: selected ? kGold : Colors.white38, size: 18),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(
                color: selected ? kGold : Colors.white54,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              )),
            ]),
          ),
        );
      },
    );
  }
}

class _PlayerCard extends StatefulWidget {
  final String name, role, imageUrl, basePrice;
  final VoidCallback onEdit, onDelete;

  const _PlayerCard({
    required this.name, required this.role, required this.imageUrl,
    required this.basePrice, required this.onEdit, required this.onDelete,
  });

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard> {
  bool _hovered = false;

  Color get _roleColor {
    switch (widget.role) {
      case 'Batsman': return const Color(0xFF4FC3F7);
      case 'Bowler': return const Color(0xFFEF5350);
      case 'All-Rounder': return const Color(0xFF66BB6A);
      case 'Wicket Keeper': return const Color(0xFFFFA726);
      case 'Wicketkeeper': return const Color(0xFFFFA726);
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: _hovered
                  ? [BoxShadow(color: kGold.withOpacity(0.35), blurRadius: 14, spreadRadius: 1)]
                  : [BoxShadow(color: Colors.black38, blurRadius: 6)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: _hovered ? const Color(0x22FFD700) : const Color(0x15FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hovered ? kGold : kGlassBorder,
                      width: _hovered ? 1.2 : 0.8,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // â”€â”€ Circular avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _roleColor.withOpacity(0.7), width: 2),
                          boxShadow: [BoxShadow(color: _roleColor.withOpacity(0.3), blurRadius: 8)],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: kPurpleDark,
                          child: ClipOval(
                            child: Image.network(
                              widget.imageUrl,
                              width: 56, height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: kGold, size: 28),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // â”€â”€ Name
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // â”€â”€ Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _roleColor.withOpacity(0.5), width: 0.8),
                        ),
                        child: Text(
                          widget.role,
                          style: TextStyle(color: _roleColor, fontSize: 9, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // â”€â”€ Base price
                      Text(
                        widget.basePrice,
                        style: const TextStyle(color: kGold, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      // â”€â”€ Action buttons â€“ icon only
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _IconActionButton(
                            icon: Icons.edit_outlined,
                            color: kGold,
                            tooltip: 'Edit',
                            onTap: widget.onEdit,
                          ),
                          const SizedBox(width: 8),
                          _IconActionButton(
                            icon: Icons.delete_outline,
                            color: Colors.redAccent,
                            tooltip: 'Delete',
                            onTap: widget.onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny circular icon action button used inside player cards
class _IconActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionButton({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovered ? widget.color.withOpacity(0.2) : Colors.transparent,
              border: Border.all(color: widget.color.withOpacity(_hovered ? 0.8 : 0.4), width: 0.8),
            ),
            child: Icon(widget.icon, color: widget.color, size: 13),
          ),
        ),
      ),
    );
  }
}

class _GoldButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _GoldButton({required this.label, required this.icon, required this.loading, required this.onTap});

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [const Color(0xFFFFE44D), kGold, kGoldDark]
                  : [kGold, kGoldDark],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hovered
                ? [BoxShadow(color: kGold.withOpacity(0.4), blurRadius: 16, spreadRadius: 1)]
                : [BoxShadow(color: kGold.withOpacity(0.2), blurRadius: 8)],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.black87, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  Shared helpers
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
Widget _sectionTitle(String t) => Text(
  t.toUpperCase(),
  style: const TextStyle(
    color: kGold,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.5,
  ),
);

Widget _styledField(String label, TextEditingController ctrl) {
  return TextFormField(
    controller: ctrl,
    style: const TextStyle(color: Colors.white),
    decoration: _inputDeco(label),
  );
}

InputDecoration _inputDeco(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Color(0xFFDAA520)),
  filled: true,
  fillColor: Colors.white.withOpacity(0.05),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0x40FFD700)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0x40FFD700)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: kGold, width: 1.5),
  ),
);
