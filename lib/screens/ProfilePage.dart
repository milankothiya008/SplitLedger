import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/screens/Settings.dart';
import 'package:SmartSpend/widgets/common.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _genders = ['Male', 'Female', 'Others'];

  final _formKey = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  String? _gender;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mobile.dispose();
    _address.dispose();
    _pincode.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('Users').doc(uid);

  Future<void> _load() async {
    final user = context.read<AppData>().user;
    if (user == null) return;
    try {
      var data = (await _doc(user.uid).get()).data();
      // Older accounts may have been stored under a different document id.
      if ((data == null || data['Mobile'] == null) && user.email != null) {
        final byEmail = await FirebaseFirestore.instance
            .collection('Users')
            .where('Email', isEqualTo: user.email)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) data = {...byEmail.docs.first.data(), ...?data};
      }
      if (data != null) {
        _mobile.text = (data['Mobile'] as String?) ?? '';
        _address.text = (data['Address'] as String?) ?? '';
        _pincode.text = (data['Pincode'] as String?) ?? '';
        final g = data['Gender'];
        _gender = _genders.contains(g) ? g as String : null;
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Could not load your profile.', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AppData>().user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await _doc(user.uid).set({
        'Name': user.displayName,
        'Email': user.email,
        'Gender': _gender,
        'Mobile': _mobile.text.trim(),
        'Address': _address.text.trim(),
        'Pincode': _pincode.text.trim(),
      }, SetOptions(merge: true));
      if (mounted) showSnack(context, 'Profile saved');
    } catch (_) {
      if (mounted) showSnack(context, 'Could not save your profile. Please try again.', error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppData>().user;
    final scheme = Theme.of(context).colorScheme;
    final name = user?.displayName ?? 'SmartSpend user';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageListView(
                maxWidth: 640,
                bottom: 32,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: scheme.primaryContainer,
                          foregroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          onForegroundImageError: user?.photoURL != null ? (_, __) {} : null,
                          child: Text(initial,
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(user?.email ?? '', style: TextStyle(color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader('Personal details'),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.person_outline_rounded)),
                    items: [for (final g in _genders) DropdownMenuItem(value: g, child: Text(g))],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      return s.isEmpty || s.length == 10 ? null : 'Enter a 10-digit mobile number';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _address,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pincode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_outlined)),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      return s.isEmpty || s.length == 6 ? null : 'Enter a 6-digit pincode';
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
