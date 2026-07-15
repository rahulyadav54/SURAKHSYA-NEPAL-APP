import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    final nearbyResponders = [
      {'name': 'अस्पताल एम्बुलेन्स (Bir Hospital Ambulance)', 'status': 'ACTIVE', 'distance': '1.2 km away', 'type': 'Ambulance'},
      {'name': 'दमकल एकाइ १२ (Fire Station Unit 12)', 'status': 'ON WAY', 'distance': '2.5 km away', 'type': 'Fire'},
      {'name': 'महानगरीय प्रहरी वृत्त (Police Patrol 4)', 'status': 'ACTIVE', 'distance': '0.8 km away', 'type': 'Police'},
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Mock Map Background Visuals
          Container(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            child: Stack(
              children: [
                // Custom drawn grid lines
                CustomPaint(
                  size: Size.infinite,
                  painter: MapGridPainter(theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                
                // Pulsating Responders on Map
                // Police
                Positioned(
                  left: size.width * 0.25,
                  top: size.height * 0.35,
                  child: _buildMapPin(theme, Icons.local_police_rounded, Colors.blue, 'Police #4'),
                ),
                // Ambulance
                Positioned(
                  right: size.width * 0.2,
                  top: size.height * 0.22,
                  child: _buildMapPin(theme, Icons.local_hospital_rounded, Colors.red, 'Bir Amb'),
                ),
                // Fire
                Positioned(
                  left: size.width * 0.35,
                  bottom: size.height * 0.32,
                  child: _buildMapPin(theme, Icons.fire_truck_rounded, Colors.orange, 'Fire 12'),
                ),
                
                // User Current Position
                Positioned(
                  left: size.width * 0.5 - 24,
                  top: size.height * 0.5 - 24,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 2.seconds)
                      .fadeOut(duration: 2.seconds),
                      
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Map Search Overlays
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Box Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: theme.colorScheme.outline),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'खोज्नुहोस् (Search hospital, fire station...)',
                                hintStyle: TextStyle(color: theme.colorScheme.outline),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                  
                  const Spacer(),
                  
                  // Sliding Bottom Cards
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearbyResponders.length,
                      itemBuilder: (context, index) {
                        final resp = nearbyResponders[index];
                        final isAmbulance = resp['type'] == 'Ambulance';
                        final isPolice = resp['type'] == 'Police';
                        final color = isAmbulance ? Colors.red : (isPolice ? Colors.blue : Colors.orange);
                        final icon = isAmbulance ? Icons.local_hospital_rounded : (isPolice ? Icons.local_police_rounded : Icons.fire_truck_rounded);

                        return Container(
                          width: size.width * 0.8,
                          margin: const EdgeInsets.only(right: 16, bottom: 8),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: color, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          resp['name'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.directions_run_rounded, size: 14, color: theme.colorScheme.outline),
                                            const SizedBox(width: 4),
                                            Text(
                                              resp['distance'] as String,
                                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                resp['status'] as String,
                                                style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.outline),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(ThemeData theme, IconData icon, Color color, String label) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1500.ms),
            
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class MapGridPainter extends CustomPainter {
  final Color gridColor;
  MapGridPainter(this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const double step = 60.0;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
