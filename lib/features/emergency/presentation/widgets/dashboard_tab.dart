import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import '../controllers/emergency_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';


class SimulatedCoordinates {
  final double latitude;
  final double longitude;
  final String label;

  const SimulatedCoordinates({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}

final simulatedLocationProvider = StateProvider<SimulatedCoordinates?>((ref) => null);

final currentLocationNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final sim = ref.watch(simulatedLocationProvider);
  if (sim != null) {
    return sim.label;
  }
  
  try {
    final locationService = ref.watch(locationServiceProvider);
    final position = await locationService.getCurrentLocation();
    
    double lat = position.latitude;
    double lon = position.longitude;
    
    // Auto-detect standard Google Emulator default coords and show Kathmandu
    if (lat >= 37.421 && lat <= 37.423 && lon >= -122.085 && lon <= -122.083) {
      return 'Kathmandu, Nepal';
    }
    
    final placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      final pm = placemarks.first;
      final city = pm.locality ?? pm.subAdministrativeArea ?? pm.administrativeArea ?? '';
      final country = pm.country ?? 'Nepal';
      if (city.isNotEmpty) {
        return '$city, $country';
      }
    }
    return 'Kathmandu, Nepal';
  } catch (e) {
    debugPrint('Geocoding error: $e');
    return 'Kathmandu, Nepal';
  }
});

final weatherProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  try {
    double lat;
    double lon;
    
    final sim = ref.watch(simulatedLocationProvider);
    if (sim != null) {
      lat = sim.latitude;
      lon = sim.longitude;
    } else {
      final locationService = ref.watch(locationServiceProvider);
      final position = await locationService.getCurrentLocation();
      lat = position.latitude;
      lon = position.longitude;
      
      // Auto-detect standard Google Emulator default coords and map to Kathmandu
      if (lat >= 37.421 && lat <= 37.423 && lon >= -122.085 && lon <= -122.083) {
        lat = 27.7172;
        lon = 85.3240;
      }
    }
    
    final client = HttpClient();
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true'
    );
    final request = await client.getUrl(uri);
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final jsonString = await response.transform(utf8.decoder).join();
      final data = json.decode(jsonString);
      final current = data['current_weather'];
      final temp = current['temperature'];
      final code = current['weathercode'];
      
      String desc = 'Clear';
      if (code >= 1 && code <= 3) desc = 'Partly Cloudy';
      else if (code >= 45 && code <= 48) desc = 'Foggy';
      else if (code >= 51 && code <= 67) desc = 'Rainy';
      else if (code >= 71 && code <= 77) desc = 'Snowy';
      else if (code >= 80 && code <= 82) desc = 'Showers';
      else if (code >= 95) desc = 'Thunderstorm';
      
      return {
        'temp': '${temp.toStringAsFixed(0)}°C',
        'desc': desc,
      };
    }
    return {'temp': '24°C', 'desc': 'Clear'};
  } catch (e) {
    debugPrint('Weather fetch error: $e');
    return {'temp': '24°C', 'desc': 'Clear'};
  }
});

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  void _showServicesDirectorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    'Emergency Service Directory',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Direct dial emergency hotlines or submit formal geolocated dispatch requests.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildDirectoryItem(
                          title: 'Ambulance & Medical Care',
                          hotline: '102',
                          desc: 'Immediate dispatch for severe accidents, cardiac events, trauma, and medical transport.',
                          icon: Icons.airport_shuttle_rounded,
                          color: const Color(0xFFFFEBEE),
                          iconColor: const Color(0xFFD32F2F),
                          route: '/ambulance',
                        ),
                        _buildDirectoryItem(
                          title: 'Fire Brigade & Evacuation',
                          hotline: '101',
                          desc: 'Rapid fire control, hazardous material containment, and rescue operations.',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFFFF3E0),
                          iconColor: const Color(0xFFF57C00),
                          route: '/fire',
                        ),
                        _buildDirectoryItem(
                          title: 'Police & Citizen Protection',
                          hotline: '100',
                          desc: 'Emergency security dispatch, reporting active threats, and public safety support.',
                          icon: Icons.local_police_rounded,
                          color: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF1976D2),
                          route: '/police',
                        ),
                        _buildDirectoryItem(
                          title: 'Hospitals & Trauma Centers',
                          hotline: '985-1010101',
                          desc: 'Directory list of critical trauma units, emergency centers, and ICUs around Nepal.',
                          icon: Icons.local_hospital_rounded,
                          color: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF388E3C),
                          route: '/hospitals',
                        ),
                        _buildDirectoryItem(
                          title: 'Blood Bank Directory',
                          hotline: '984-2020202',
                          desc: 'Connect directly with local blood banks, active blood donor registries, and stock controls.',
                          icon: Icons.bloodtype_rounded,
                          color: const Color(0xFFFEEBEE),
                          iconColor: const Color(0xFFE64A19),
                          onTap: () {
                            Navigator.pop(context);
                            ref.read(homeTabIndexProvider.notifier).state = 3;
                          },
                        ),
                        _buildDirectoryItem(
                          title: 'Disaster Support & Alert Control',
                          hotline: '1155',
                          desc: 'Live disaster tracking, early warning announcements, and safety advisory manuals.',
                          icon: Icons.campaign_rounded,
                          color: const Color(0xFFF3E5F5),
                          iconColor: const Color(0xFF8E24AA),
                          route: '/disaster-alerts',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDirectoryItem({
    required String title,
    required String hotline,
    required String desc,
    required IconData icon,
    required Color color,
    required Color iconColor,
    String? route,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toll-Free Hotline: $hotline',
                      style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Simulating call to $hotline...'),
                        backgroundColor: iconColor,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text('Call Hotline', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: iconColor,
                    side: BorderSide(color: iconColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onTap != null) {
                      onTap();
                    } else if (route != null) {
                      context.push(route);
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Request Dispatch', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLocationSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currentSim = ref.watch(simulatedLocationProvider);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Active Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a city to simulate Nepalese weather and geolocated dispatches, or use your live GPS coordinates.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              
              // Live GPS Location Option
              ListTile(
                leading: Icon(
                  Icons.my_location_rounded,
                  color: currentSim == null ? const Color(0xFFC62828) : Colors.grey,
                ),
                title: Text(
                  'Live GPS coordinates',
                  style: TextStyle(
                    fontWeight: currentSim == null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: currentSim == null
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFFC62828))
                    : null,
                onTap: () {
                  ref.read(simulatedLocationProvider.notifier).state = null;
                  Navigator.pop(context);
                },
              ),
              
              // Kathmandu
              _buildCityListTile('Kathmandu, Nepal', 27.7172, 85.3240, currentSim),
              // Pokhara
              _buildCityListTile('Pokhara, Nepal', 28.2096, 83.9856, currentSim),
              // Lalitpur
              _buildCityListTile('Lalitpur, Nepal', 27.6744, 85.3223, currentSim),
              // Biratnagar
              _buildCityListTile('Biratnagar, Nepal', 26.4525, 87.2718, currentSim),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCityListTile(String label, double lat, double lon, SimulatedCoordinates? currentSim) {
    final isSelected = currentSim != null && currentSim.label == label;
    return ListTile(
      leading: Icon(
        Icons.location_city_rounded,
        color: isSelected ? const Color(0xFFC62828) : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFFC62828))
          : null,
      onTap: () {
        ref.read(simulatedLocationProvider.notifier).state = SimulatedCoordinates(
          latitude: lat,
          longitude: lon,
          label: label,
        );
        Navigator.pop(context);
      },
    );
  }

  void _showCustomAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.security_rounded, color: Color(0xFFB71C1C), size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Suraksha Nepal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'Version 1.2.0',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: const Text(
            'Unified AI Emergency Response Platform supporting local geolocated dispatches, meteorological alerts, first-aid guidance, and dynamic donor records.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/licenses');
              },
              child: Text(
                'View licenses',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  int _activeBannerIndex = 0;
  PageController? _bannerPageController;
  Timer? _bannerTimer;

  final List<Map<String, String>> _awarenessBanners = [
    {
      'title': 'EARTHQUAKE SAFETY',
      'subtitle': 'Drop, Cover, and Hold On!',
      'tip': 'Protect your head & stay under sturdy furniture.',
      'image': 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000&auto=format&fit=crop',
    },
    {
      'title': 'FIRE EMERGENCY TIPS',
      'subtitle': 'Crawl low under smoke & evacuate',
      'tip': 'Do not use lifts. Evacuate immediately.',
      'image': 'https://images.unsplash.com/photo-1599733589046-10c005739ef9?q=80&w=1000&auto=format&fit=crop',
    },
    {
      'title': 'FIRST-AID: CPR RULES',
      'subtitle': 'Chest compressions must be steady',
      'tip': 'Push hard and fast in the center of the chest.',
      'image': 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?q=80&w=1000&auto=format&fit=crop',
    },
    {
      'title': 'FLOOD PREPARATION',
      'subtitle': 'Turn around, don\'t drown!',
      'tip': 'Never walk or drive through flood waters.',
      'image': 'https://images.unsplash.com/photo-1547683905-f686c993aae5?q=80&w=1000&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(initialPage: 0);
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerPageController?.hasClients ?? false) {
        final nextPage = (_activeBannerIndex + 1) % _awarenessBanners.length;
        _bannerPageController?.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _isCountingDown = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  void _startSosCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdownSeconds == 1) {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        _triggerSosAlert();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  void _cancelSosCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS Trigger Cancelled.'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Future<void> _triggerSosAlert() async {
    final success = await ref.read(emergencyControllerProvider.notifier).triggerSosAlert();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS Alert Transmitted Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      ref.read(homeTabIndexProvider.notifier).state = 1; // Switch to History
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bannerTimer?.cancel();
    _bannerPageController?.dispose();
    super.dispose();
  }

  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 72,
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 600.ms),
              const SizedBox(height: 16),
              const Text(
                'Emergency Alert Initiating',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Text(
                'TRANSMITTING SOS SIGNAL IN...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: _countdownSeconds / 3,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Text(
                    '$_countdownSeconds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                  .animate(key: ValueKey(_countdownSeconds))
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 300.ms)
                  .fadeIn(duration: 300.ms),
                ],
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: _cancelSosCountdown,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 24),
                label: const Text(
                  'CANCEL SOS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationNameAsync = ref.watch(currentLocationNameProvider);
    final services = [
      {
        'title': 'Ambulance',
        'subtitle': 'Get immediate medical help',
        'icon': Icons.medical_services_rounded,
        'color': const Color(0xFFE53935),
        'bgColor': const Color(0xFFFFEBEE),
        'route': '/ambulance-request',
      },
      {
        'title': 'Fire Brigade',
        'subtitle': 'Report fire emergencies',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFF57C00),
        'bgColor': const Color(0xFFFFF3E0),
        'route': '/fire-report',
      },
      {
        'title': 'Police',
        'subtitle': 'Report crime or get protection',
        'icon': Icons.local_police_rounded,
        'color': const Color(0xFF1565C0),
        'bgColor': const Color(0xFFE3F2FD),
        'route': '/police-report',
      },
      {
        'title': 'Hospitals',
        'subtitle': 'Find nearby hospitals',
        'icon': Icons.local_hospital_rounded,
        'color': const Color(0xFF00897B),
        'bgColor': const Color(0xFFE0F2F1),
        'route': '/hospital-list',
      },
      {
        'title': 'Blood Bank',
        'subtitle': 'Find donors & request blood',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF7B1FA2),
        'bgColor': const Color(0xFFF3E5F5),
        'route': null,
      },
      {
        'title': 'Disaster',
        'subtitle': 'Disaster alerts & safety info',
        'icon': Icons.landslide_rounded,
        'color': const Color(0xFF00796B),
        'bgColor': const Color(0xFFE0F2F1),
        'route': '/disaster-alerts',
      },
    ];

    final quickActions = [
      {'title': 'Emergency Contacts', 'icon': Icons.person_add_alt_1_rounded, 'color': const Color(0xFF1976D2)},
      {'title': 'Live Tracking', 'icon': Icons.location_on_rounded, 'color': const Color(0xFF388E3C)},
      {'title': 'First Aid Guide', 'icon': Icons.medical_information_rounded, 'color': const Color(0xFFE64A19)},
      {'title': 'Alerts', 'icon': Icons.campaign_rounded, 'color': const Color(0xFF8E24AA)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB71C1C), Color(0xFF7B0000)],
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.security_rounded, color: Color(0xFFB71C1C), size: 36),
                    ),
                  ),
                ),
              ),
              accountName: const Text(
                'Suraksha Nepal User',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('Emergency Response Platform'),
            ),
            
            // Drawer Items
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Color(0xFFB71C1C)),
              title: const Text('Citizen Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.blue),
              title: const Text('Admin Dispatch Portal', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: Colors.orange),
              title: const Text('Emergency History Logs', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ref.read(homeTabIndexProvider.notifier).state = 1;
              },
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy_rounded, color: Colors.teal),
              title: const Text('AI First-Aid Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ref.read(homeTabIndexProvider.notifier).state = 2;
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop_rounded, color: Colors.red),
              title: const Text('Blood Bank Directory', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ref.read(homeTabIndexProvider.notifier).state = 3;
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Colors.purple),
              title: const Text('Emergency Profile Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ref.read(homeTabIndexProvider.notifier).state = 4;
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authControllerProvider.notifier).signOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About Suraksha Nepal'),
              onTap: () {
                Navigator.pop(context);
                _showCustomAboutDialog(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Top Header Row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Menu Icon
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu_rounded, size: 26, color: Color(0xFF333333)),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),

                    // Center: App Logo + Title
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, color: Color(0xFFB71C1C), size: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'SURAKSHYA ',
                                    style: TextStyle(
                                      color: Color(0xFF0D253F),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'NEPAL',
                                    style: TextStyle(
                                      color: Color(0xFFC62828),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'One Tap. Every Emergency.',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right: Notification Bell Badge
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, size: 26, color: Color(0xFF333333)),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFC62828),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 2. Location & Weather Bar ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    // Location Pill
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          _showLocationSelectionSheet();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFC62828), size: 18),
                              const SizedBox(width: 6),
                              locationNameAsync.when(
                                data: (name) => Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF333333)),
                                ),
                                loading: () => const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC62828)),
                                ),
                                error: (_, __) => const Text(
                                  'Kathmandu, Nepal',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF333333)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Weather Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ref.watch(weatherProvider).when(
                            data: (wData) => Row(
                              children: [
                                const Icon(Icons.wb_cloudy_rounded, color: Color(0xFFFFA726), size: 18),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wData['temp'] ?? '24°C',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF333333)),
                                    ),
                                    Text(
                                      wData['desc'] ?? 'Clear',
                                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            loading: () => const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFA726)),
                            ),
                            error: (_, __) => const Row(
                              children: [
                                Icon(Icons.wb_cloudy_rounded, color: Color(0xFFFFA726), size: 18),
                                SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '24°C',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF333333)),
                                    ),
                                    Text(
                                      'Clear',
                                      style: TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Mountain Backdrop + Glowing Red SOS Button ─────────────
              // Auto-sliding Awareness Carousel Banner
              Container(
                height: 168,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _bannerPageController,
                        onPageChanged: (index) {
                          setState(() {
                            _activeBannerIndex = index;
                          });
                        },
                        itemCount: _awarenessBanners.length,
                        itemBuilder: (context, index) {
                          final item = _awarenessBanners[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background Image
                              Image.network(
                                item['image']!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1A1F2C),
                                  child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 48),
                                ),
                              ),
                              // Gradient Overlay for Legibility
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.25),
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                  ),
                                ),
                              ),
                              // Content Column
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFC62828).withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.campaign_rounded, color: Colors.white, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['title']!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['subtitle']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                        shadows: [
                                          Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['tip']!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      // Dot Indicators overlay
                      Positioned(
                        right: 20,
                        top: 20,
                        child: Row(
                          children: List.generate(
                            _awarenessBanners.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _activeBannerIndex == index ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _activeBannerIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 4. Emergency Services Card Container ──────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Emergency Services',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _showServicesDirectorySheet();
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final item = services[index];
                        return InkWell(
                          onTap: () {
                            if (item['route'] != null) {
                              context.push(item['route'] as String);
                            } else if (item['title'] == 'Blood Bank') {
                              ref.read(homeTabIndexProvider.notifier).state = 3;
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: item['bgColor'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: item['color'] as Color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['subtitle'] as String,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. Quick Actions Section ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: quickActions.map((qa) {
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              final title = qa['title'] as String;
                              if (title == 'Emergency Contacts') {
                                context.push('/create-profile');
                              } else if (title == 'Live Tracking') {
                                context.push('/live-map');
                              } else if (title == 'First Aid Guide') {
                                ref.read(homeTabIndexProvider.notifier).state = 3;
                              } else if (title == 'Alerts') {
                                ref.read(homeTabIndexProvider.notifier).state = 1;
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(qa['icon'] as IconData, color: qa['color'] as Color, size: 24),
                                  const SizedBox(height: 6),
                                  Text(
                                    qa['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 6. Preparedness Banner ────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stay Prepared, Stay Safe',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D47A1)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Enable location and notifications to get real-time updates.',
                            style: TextStyle(fontSize: 10, color: Color(0xFF1565C0)),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref.read(homeTabIndexProvider.notifier).state = 3;
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Enable Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
          if (_isCountingDown)
            _buildCountdownOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _startSosCountdown,
        backgroundColor: const Color(0xFFBD0022),
        shape: const CircleBorder(),
        elevation: 6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .shake(duration: 1000.ms),
            const SizedBox(height: 2),
            const Text(
              'SOS',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
