import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../emergency/presentation/controllers/emergency_controller.dart';
import '../controllers/hospital_controller.dart';

class HospitalListScreen extends ConsumerStatefulWidget {
  const HospitalListScreen({super.key});

  @override
  ConsumerState<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends ConsumerState<HospitalListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final pos = await ref.read(locationServiceProvider).getCurrentLocation();
    setState(() {
      _userPosition = pos;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(hospitalsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Hospitals'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: theme.colorScheme.outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'खोज्नुहोस् (Search hospital...)',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Hospitals list grid
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(hospitalsListProvider);
                  await _loadUserLocation();
                },
                child: listAsync.when(
                  data: (hospitals) {
                    final filtered = hospitals.where((h) {
                      final nameMatch = h.name.toLowerCase().contains(_searchQuery);
                      final addressMatch = h.address.toLowerCase().contains(_searchQuery);
                      return nameMatch || addressMatch;
                    }).toList();

                    if (filtered.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.local_hospital_rounded, size: 64, color: theme.colorScheme.outline),
                                const SizedBox(height: 16),
                                Text(
                                  'No hospitals match your search.',
                                  style: TextStyle(color: theme.colorScheme.outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final hospital = filtered[index];
                        
                        double distance = 0.0;
                        if (_userPosition != null) {
                          distance = _calculateDistance(
                            _userPosition!.latitude,
                            _userPosition!.longitude,
                            hospital.latitude,
                            hospital.longitude,
                          );
                        }

                        final bedsAvailable = hospital.emergencyBedsAvailable;
                        final bedColor = bedsAvailable > 4 ? Colors.green : Colors.red;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          elevation: 0,
                          child: InkWell(
                            onTap: () {
                              context.push('/hospital-details', extra: hospital);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.business_rounded, color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hospital.name,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          hospital.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.directions_run_rounded, size: 14, color: theme.colorScheme.outline),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${distance.toStringAsFixed(1)} km away',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.outline,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(Icons.bed_rounded, size: 14, color: bedColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$bedsAvailable beds free',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: bedColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call_rounded),
                                    style: IconButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Dialing ${hospital.phone}')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
                      },
                    );
                  },
                  loading: () => const SurakshaLoading(size: 60),
                  error: (err, stack) => SurakshaErrorWidget(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(hospitalsListProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
