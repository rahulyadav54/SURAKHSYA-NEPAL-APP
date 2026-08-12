import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/cache_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class EmergencyContact {
  String name;
  String relation;
  String phone;
  bool notifyOnSos;

  EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
    required this.notifyOnSos,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'phone': phone,
        'notifyOnSos': notifyOnSos,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
        name: json['name'] ?? '',
        relation: json['relation'] ?? '',
        phone: json['phone'] ?? '',
        notifyOnSos: json['notifyOnSos'] ?? false,
      );
}

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _shareLocation = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _citizenshipController = TextEditingController();

  String? _selectedBloodType;
  XFile? _avatarFile;

  List<EmergencyContact> _contacts = [];

  final ImagePicker _picker = ImagePicker();

  // SharedPreferences Keys
  static const String _shareLocationKey = 'profile_share_location';
  static const String _nameKey = 'profile_name';
  static const String _bloodTypeKey = 'profile_blood_type';
  static const String _allergiesKey = 'profile_allergies';
  static const String _medicationsKey = 'profile_medications';
  static const String _dobKey = 'profile_dob';
  static const String _addressKey = 'profile_address';
  static const String _citizenshipKey = 'profile_citizenship';
  static const String _avatarKey = 'profile_avatar_path';
  static const String _contactsKey = 'profile_contacts_json';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = ref.read(sharedPrefsProvider);
    setState(() {
      _shareLocation = prefs.getBool(_shareLocationKey) ?? true;
      _nameController.text = prefs.getString(_nameKey) ?? '';
      _selectedBloodType = prefs.getString(_bloodTypeKey);
      _allergiesController.text = prefs.getString(_allergiesKey) ?? '';
      _medicationsController.text = prefs.getString(_medicationsKey) ?? '';
      _dobController.text = prefs.getString(_dobKey) ?? '';
      _addressController.text = prefs.getString(_addressKey) ?? '';
      _citizenshipController.text = prefs.getString(_citizenshipKey) ?? '';
      
      final avatarPath = prefs.getString(_avatarKey);
      if (avatarPath != null && avatarPath.isNotEmpty) {
        _avatarFile = XFile(avatarPath);
      }

      // Load Contacts
      final contactsStr = prefs.getStringList(_contactsKey);
      if (contactsStr != null) {
        _contacts = contactsStr.map((str) {
          final parts = str.split('||');
          return EmergencyContact(
            name: parts[0],
            relation: parts[1],
            phone: parts[2],
            notifyOnSos: parts[3] == 'true',
          );
        }).toList();
      } else {
        // Mock default contacts
        _contacts = [
          EmergencyContact(name: 'Sunita Sharma', relation: 'Spouse', phone: '+977-980-0000000', notifyOnSos: true),
          EmergencyContact(name: 'Ramesh Koirala', relation: 'Brother', phone: '+977-982-1111111', notifyOnSos: false),
        ];
      }
    });
  }

  Future<void> _saveProfileData() async {
    setState(() => _isSaving = true);

    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_shareLocationKey, _shareLocation);
    await prefs.setString(_nameKey, _nameController.text);
    if (_selectedBloodType != null) {
      await prefs.setString(_bloodTypeKey, _selectedBloodType!);
    }
    await prefs.setString(_allergiesKey, _allergiesController.text);
    await prefs.setString(_medicationsKey, _medicationsController.text);
    await prefs.setString(_dobKey, _dobController.text);
    await prefs.setString(_addressKey, _addressController.text);
    await prefs.setString(_citizenshipKey, _citizenshipController.text);
    
    if (_avatarFile != null) {
      await prefs.setString(_avatarKey, _avatarFile!.path);
    }

    // Save Contacts
    final contactsStr = _contacts.map((c) => '${c.name}||${c.relation}||${c.phone}||${c.notifyOnSos}').toList();
    await prefs.setStringList(_contactsKey, contactsStr);

    await Future.delayed(const Duration(seconds: 1)); // Simulated delay
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _avatarFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
    }
  }

  void _addOrEditContact({EmergencyContact? contact, int? index}) {
    final nameCtrl = TextEditingController(text: contact?.name);
    final relCtrl = TextEditingController(text: contact?.relation);
    final phoneCtrl = TextEditingController(text: contact?.phone);
    bool notify = contact?.notifyOnSos ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(contact == null ? 'Add Contact' : 'Edit Contact', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: relCtrl,
                      decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Notify on SOS', style: TextStyle(fontSize: 14)),
                      value: notify,
                      onChanged: (val) {
                        setDialogState(() {
                          notify = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                    setState(() {
                      if (contact == null) {
                        _contacts.add(EmergencyContact(
                          name: nameCtrl.text,
                          relation: relCtrl.text,
                          phone: phoneCtrl.text,
                          notifyOnSos: notify,
                        ));
                      } else {
                        _contacts[index!] = EmergencyContact(
                          name: nameCtrl.text,
                          relation: relCtrl.text,
                          phone: phoneCtrl.text,
                          notifyOnSos: notify,
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _citizenshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Emergency Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            onPressed: () => context.push('/admin'),
            tooltip: 'Admin Portal',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro
              Text(
                'Emergency Profile',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your critical information to assist responders during an emergency.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 20),

              // ── 1. Location Sharing Toggle & Settings ─────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Share Location with Rescuers',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Automatically send live location on SOS',
                          style: TextStyle(fontSize: 11),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.location_on_rounded, color: Colors.blue.shade700, size: 20),
                        ),
                        value: _shareLocation,
                        onChanged: (val) {
                          setState(() {
                            _shareLocation = val;
                          });
                        },
                      ),
                      const Divider(height: 16),
                      // Dark Theme Toggle
                      SwitchListTile(
                        title: const Text(
                          'Dark Theme Mode',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Toggle visual theme style mode',
                          style: TextStyle(fontSize: 11),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.dark_mode_outlined, color: Colors.purple.shade700, size: 20),
                        ),
                        value: ref.watch(themeModeProvider) == ThemeMode.dark ||
                            (ref.watch(themeModeProvider) == ThemeMode.system &&
                                MediaQuery.platformBrightnessOf(context) == Brightness.dark),
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms),

              const SizedBox(height: 16),

              // ── 2. Medical Information ────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_information_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          const Text('Medical Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Blood Type dropdown
                      const Text('Blood Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        hint: const Text('O Positive (O+)'),
                        items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedBloodType = val),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Allergies
                      const Text('Known Allergies', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _allergiesController,
                        decoration: InputDecoration(
                          hintText: 'None known',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Current Medications
                      const Text('Current Medications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _medicationsController,
                        decoration: InputDecoration(
                          hintText: 'Albuterol Inhaler (As needed)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Personal Details ───────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          const Text('Personal Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar Picker
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _avatarFile != null 
                                  ? FileImage(File(_avatarFile!.path)) 
                                  : null,
                              child: _avatarFile == null 
                                  ? const Icon(Icons.person_rounded, size: 40, color: Colors.grey) 
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _pickAvatar,
                              child: const Text('Change Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Full legal name
                      const Text('Full Legal Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Aarav Sharma',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // DOB
                      const Text('Date of Birth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: InputDecoration(
                          hintText: '15-05-1990',
                          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Address
                      const Text('Primary Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Kantipath, Kathmandu, Nepal',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Citizenship
                      const Text('National ID / Citizenship No.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _citizenshipController,
                        decoration: InputDecoration(
                          hintText: '27-01-71-00000',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 4. Emergency Contacts ─────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 10),
                              const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _addOrEditContact(),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_contacts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No emergency contacts added yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _contacts.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final c = _contacts[index];
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                                  child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                                          children: [
                                            TextSpan(text: c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            TextSpan(text: ' (${c.relation})', style: const TextStyle(color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(c.phone, style: TextStyle(color: theme.colorScheme.outline, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            c.notifyOnSos ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                            size: 12,
                                            color: c.notifyOnSos ? Colors.green : Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            c.notifyOnSos ? 'Notify on SOS (Active)' : 'Do not notify',
                                            style: TextStyle(
                                              color: c.notifyOnSos ? Colors.green.shade700 : Colors.grey,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blueGrey),
                                  onPressed: () => _addOrEditContact(contact: c, index: index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _contacts.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── 5. Save Button ────────────────────────────────────────────
              FilledButton(
                onPressed: _isSaving ? null : _saveProfileData,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFBD0022),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text(
                        'Save Profile Updates',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
