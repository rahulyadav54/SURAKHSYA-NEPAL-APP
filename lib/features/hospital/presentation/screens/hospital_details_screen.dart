import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/hospital.dart';

class HospitalDetailsScreen extends StatelessWidget {
  final Hospital hospital;

  const HospitalDetailsScreen({
    super.key,
    required this.hospital,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latLng = LatLng(hospital.latitude, hospital.longitude);

    final Set<Marker> markers = {
      Marker(
        markerId: MarkerId(hospital.id),
        position: latLng,
        infoWindow: InfoWindow(title: hospital.name, snippet: hospital.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    final specialistList = hospital.specialists
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(hospital.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: latLng,
                    zoom: 15.0,
                  ),
                  markers: markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospital.address,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Dialing ${hospital.phone}')),
                            );
                          },
                          icon: const Icon(Icons.call_rounded),
                        ),
                      ],
                    ),
                    const Divider(height: 36),

                    Text(
                      'Emergency Beds Status',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: hospital.emergencyBedsAvailable / hospital.emergencyBedsTotal,
                                strokeWidth: 10,
                                backgroundColor: theme.colorScheme.outlineVariant,
                                color: hospital.emergencyBedsAvailable > 3 ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              '${hospital.emergencyBedsAvailable}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${hospital.emergencyBedsAvailable} out of ${hospital.emergencyBedsTotal} beds free',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bed occupancy changes in real time as admissions are cleared.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 36),

                    Text(
                      'Doctors On Duty (विशेषज्ञ चिकित्सकहरू)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: specialistList.map((spec) {
                        return Chip(
                          avatar: const Icon(Icons.person_pin_rounded, size: 16),
                          label: Text(spec),
                          backgroundColor: theme.colorScheme.surfaceContainerLow,
                        );
                      }).toList(),
                    ),

                    const Divider(height: 36),

                    Text(
                      'Blood Bank Inventory (रक्त उपलब्धता)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (hospital.bloodStock.isEmpty)
                      Text(
                        'No stock details listed for this facility.',
                        style: TextStyle(color: theme.colorScheme.outline),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: hospital.bloodStock.keys.length,
                        itemBuilder: (context, index) {
                          final group = hospital.bloodStock.keys.elementAt(index);
                          final bags = hospital.bloodStock[group];

                          return Card(
                            elevation: 0,
                            color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  group,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$bags bags',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
