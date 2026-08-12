import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SafetyTipsTab extends StatefulWidget {
  const SafetyTipsTab({super.key});

  @override
  State<SafetyTipsTab> createState() => _SafetyTipsTabState();
}

class _SafetyTipsTabState extends State<SafetyTipsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allTips = [
    {
      'title': 'Earthquake Safety',
      'icon': Icons.landslide_rounded,
      'color': Colors.amber.shade800,
      'bgColor': Colors.amber.shade50,
      'shortDesc': 'Drop, Cover, and Hold On! Stay prepared for tremors.',
      'steps': [
        'Drop down onto your hands and knees immediately under a sturdy table or desk.',
        'Cover your head and neck with your arms, and hold onto your shelter firmly.',
        'Keep away from glass windows, mirrors, doors, and tall storage cabinets.',
        'If outdoors, move immediately to an open space away from buildings, power lines, and trees.',
        'Do not use elevators. Wait for the shaking to stop completely before using emergency exit stairs.'
      ],
    },
    {
      'title': 'Fire Emergency',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.red.shade700,
      'bgColor': Colors.red.shade50,
      'shortDesc': 'Crawl low in smoke, stop-drop-roll, and handle burns.',
      'steps': [
        'Crawl low under smoke to exit the building safely to prevent smoke inhalation.',
        'If clothing catches fire, do not run: Stop, Drop, and Roll on the floor immediately.',
        'Cool minor burns under clean flowing water for 10-15 minutes. Avoid ice, butter, or grease.',
        'Open all windows and doors if gas leakage is suspected, and do not toggle electrical switches.'
      ],
    },
    {
      'title': 'Snake Bite First Aid',
      'icon': Icons.bug_report_rounded,
      'color': Colors.teal.shade700,
      'bgColor': Colors.teal.shade50,
      'shortDesc': 'Keep calm, immobilize the bite area, and seek antivenom.',
      'steps': [
        'Keep the victim completely calm and still to slow down venom transmission.',
        'Keep the bitten limb positioned at or below heart level.',
        'Remove any constricting jewelry, rings, tight shoes, or clothing near the bite area.',
        'Do not cut the wound, use tourniquets, or attempt to suck out the venom.',
        'Cover the area with a loose clean dressing and transport to an antivenom clinic immediately.'
      ],
    },
    {
      'title': 'Severe Bleeding Control',
      'icon': Icons.bloodtype_rounded,
      'color': Colors.deepOrange.shade800,
      'bgColor': Colors.deepOrange.shade50,
      'shortDesc': 'Apply direct pressure, elevate the limb, and bandage.',
      'steps': [
        'Apply direct, continuous pressure to the wound with a clean cloth or bandage.',
        'Elevate the injured limb above heart level if no fracture is suspected.',
        'Do not remove blood-soaked dressing; add more layers on top and continue pressure.',
        'If bleeding continues, cover the patient to retain body heat and seek immediate emergency care.'
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final filteredTips = _allTips.where((tip) {
      final title = tip['title'].toString().toLowerCase();
      final desc = tip['shortDesc'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || desc.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('EMERGENCY SAFETY TIPS'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: theme.colorScheme.outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search safety guides...',
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

            // Tips list
            Expanded(
              child: filteredTips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No guidelines matching your search.',
                            style: TextStyle(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      itemCount: filteredTips.length,
                      itemBuilder: (context, index) {
                        final item = filteredTips[index];
                        return _buildExpandableTipCard(context, item, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableTipCard(BuildContext context, Map<String, dynamic> item, int index) {
    final theme = Theme.of(context);
    final color = item['color'] as Color;
    final bgColor = item['bgColor'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'] as IconData, color: color, size: 24),
          ),
          title: Text(
            item['title'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    item['shortDesc'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Key Actions & Steps:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...(item['steps'] as List<String>).map((step) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
