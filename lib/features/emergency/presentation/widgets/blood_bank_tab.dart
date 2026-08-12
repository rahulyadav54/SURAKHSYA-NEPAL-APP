import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cache_service.dart';

class BloodBankTab extends ConsumerStatefulWidget {
  const BloodBankTab({super.key});

  @override
  ConsumerState<BloodBankTab> createState() => _BloodBankTabState();
}

class _BloodBankTabState extends ConsumerState<BloodBankTab> {
  int _subTab = 0; // 0: Request Blood, 1: Donate Blood
  bool _isDonor = false;
  bool _isSubmitting = false;

  final _patientNameController = TextEditingController();
  String? _selectedBloodType;
  String? _selectedHospital;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _hospitals = [
    'Red Cross Central, Kathmandu',
    'Patan Hospital Blood Center, Lalitpur',
    'Bir Hospital, Kathmandu',
    'T.U. Teaching Hospital, Maharajgunj',
    'Nepal Mediciti Hospital, Lalitpur'
  ];

  static const String _donorKey = 'is_blood_donor';

  @override
  void initState() {
    super.initState();
    _loadDonorStatus();
  }

  Future<void> _loadDonorStatus() async {
    final prefs = ref.read(sharedPrefsProvider);
    setState(() {
      _isDonor = prefs.getBool(_donorKey) ?? false;
    });
  }

  Future<void> _toggleDonorStatus(bool val) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_donorKey, val);
    setState(() {
      _isDonor = val;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(val 
            ? 'Thank you! Registered as a Blood Donor successfully.' 
            : 'Unregistered from Donor List successfully.'),
        backgroundColor: val ? Colors.green.shade700 : Colors.blueGrey,
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (_patientNameController.text.trim().isEmpty || _selectedBloodType == null || _selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all form fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulated api delay
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency Broadcast Sent! Nearest donors notified.'),
        backgroundColor: Colors.red,
      ),
    );

    _patientNameController.clear();
    setState(() {
      _selectedBloodType = null;
      _selectedHospital = null;
    });
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Blood Bank & Donors'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Emergency Blood Request Alert Card ─────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFBD0022), // Primary Red
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'URGENT',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emergency Blood Needed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'High demand for O- and A+ blood types in your immediate vicinity. Your donation can save lives today.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _toggleDonorStatus(!_isDonor),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFBD0022),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Text(
                              _isDonor ? 'Registered (Tap to Exit)' : 'Register as Donor',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),

              // ── 2. Sliding Sub-Tabs Selector ──────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _subTabItem(0, 'Request Blood'),
                    _subTabItem(1, 'Donate Blood'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 3. Conditionally rendered Form or Donors List ─────────────
              if (_subTab == 0) ...[
                // Request Blood Form
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
                        const Text(
                          'Submit Request',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        
                        // Patient Name
                        const Text('Patient Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _patientNameController,
                          decoration: InputDecoration(
                            hintText: 'Enter patient name',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Blood Type Dropdown
                        const Text('Blood Type Required', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedBloodType,
                          hint: const Text('Select Type'),
                          items: _bloodTypes.map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedBloodType = val),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Hospital Selection
                        const Text('Hospital / Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedHospital,
                          hint: const Text('Search hospital'),
                          items: _hospitals.map((hospital) {
                            return DropdownMenuItem(value: hospital, child: Text(hospital));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedHospital = val),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit broadcast button
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFBD0022),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Broadcast Request', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ] else ...[
                // Donate Blood List (Active requests)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildActiveRequestCard('Ramesh Acharya', 'O-', 'Bir Hospital', 'HIGH', '2 mins ago'),
                    _buildActiveRequestCard('Maya Tamang', 'A+', 'Patan Hospital', 'MEDIUM', '1 hr ago'),
                    _buildActiveRequestCard('Binod Adhikari', 'AB-', 'Teaching Hospital', 'CRITICAL', 'Just now'),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // ── 4. Nearby Blood Banks ─────────────────────────────────────
              const Text(
                'Nearby Blood Banks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),

              _buildBloodBankCard(
                'Red Cross Central',
                '2.6 km away',
                true,
                {'A+': 'Low', 'B-': 'Medium', 'O-': 'Critical', 'AB+': 'High'},
              ),
              const SizedBox(height: 12),
              _buildBloodBankCard(
                'Patan Hospital Blood Center',
                '4.1 km away',
                true,
                {'B+': 'High', 'A-': 'Low', 'O+': 'Medium', 'AB-': 'Low'},
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subTabItem(int index, String title) {
    final isSelected = _subTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _subTab = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFFBD0022) : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRequestCard(String name, String bloodType, String hospital, String urgency, String time) {
    final theme = Theme.of(context);
    final urgencyColor = urgency == 'CRITICAL' || urgency == 'HIGH' ? Colors.red.shade700 : Colors.orange.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  bloodType,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.local_hospital_rounded, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(hospital, style: TextStyle(color: theme.colorScheme.outline, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        urgency,
                        style: TextStyle(color: urgencyColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: TextStyle(color: theme.colorScheme.outline, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Contacting request focal: $name...')),
                );
              },
              child: const Text('Contact'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildBloodBankCard(String name, String distance, bool isOpen, Map<String, String> stocks) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: isOpen ? Colors.green.shade700 : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              distance,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stocks.entries.map((entry) {
                final group = entry.key;
                final level = entry.value;
                
                Color stockColor = Colors.green;
                if (level == 'Low') {
                  stockColor = Colors.orange;
                } else if (level == 'Critical') {
                  stockColor = Colors.red;
                }

                return Column(
                  children: [
                    Text(
                      group,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(color: stockColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
