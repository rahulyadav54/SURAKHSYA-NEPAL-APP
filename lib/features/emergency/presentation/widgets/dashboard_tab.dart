import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        'route': '/hospital-list',
      },
      {
        'title': 'Disaster',
        'subtitle': 'Disaster alerts & safety info',
        'icon': Icons.landslide_rounded,
        'color': const Color(0xFF00796B),
        'bgColor': const Color(0xFFE0F2F1),
        'route': null,
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
      body: SafeArea(
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
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 26, color: Color(0xFF333333)),
                      onPressed: () {},
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
                      child: const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFFC62828), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Kathmandu, Nepal',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF333333)),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
                        ],
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
                      child: const Row(
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Mountain Backdrop + Glowing Red SOS Button ─────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  // Mountain Banner Image Backdrop
                  Container(
                    height: 220,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E9EAB), Color(0xFFEEF2F3)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                        opacity: 0.85,
                      ),
                    ),
                  ),

                  // SOS Pulsating Trigger Button
                  GestureDetector(
                    onTap: () {
                      context.push('/emergency-history');
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD32F2F),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD32F2F).withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28)
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .shake(duration: 1000.ms),
                          const SizedBox(height: 4),
                          const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Text(
                            'Tap for Help',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 1200.ms),
                  ),
                ],
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
                          onPressed: () {},
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
                                context.push('/ambulance-tracking');
                              } else if (title == 'First Aid Guide') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening First Aid Advisory Guide...')),
                                );
                              } else if (title == 'Alerts') {
                                context.push('/emergency-history');
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
                      onPressed: () {},
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
    );
  }
}
