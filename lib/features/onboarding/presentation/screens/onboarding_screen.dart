import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Unified Emergency Response',
      'titleNp': 'एकिकृत आपतकालीन सेवा',
      'description': 'Connect instantly with Ambulance, Fire Brigade, Police, Blood Banks, and Disaster Response Teams across Nepal.',
      'icon': Icons.emergency_rounded,
      'color': Colors.red,
    },
    {
      'title': 'Real-Time Location & SOS',
      'titleNp': 'वास्तविक समय स्थान र SOS',
      'description': 'Send instant distress signals with your precise GPS coordinates to responders and your trusted emergency contacts.',
      'icon': Icons.my_location_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'AI Rescue & First-Aid Guide',
      'titleNp': 'AI उद्धार र प्राथमिक उपचार',
      'description': 'Access AI-powered emergency instructions and first-aid guidelines tailored to your current crisis, available even with low connectivity.',
      'icon': Icons.psychology_rounded,
      'color': Colors.teal,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    // Calculate dynamic size constraint for layout compatibility
    final visualCardSize = (size.height < size.width ? size.height : size.width) * 0.35;
    final double cardBoundary = visualCardSize.clamp(100.0, 180.0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Skip',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
            
            // Carousel Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Slide Visual Card
                          Container(
                            width: cardBoundary,
                            height: cardBoundary,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (slide['color'] as Color).withValues(alpha: 0.1),
                            ),
                            child: Center(
                              child: Icon(
                                slide['icon'] as IconData,
                                size: cardBoundary * 0.5,
                                color: slide['color'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Slide Nepali Title
                          Text(
                            slide['titleNp'] as String,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // Slide English Title
                          Text(
                            slide['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Slide Description
                          Text(
                            slide['description'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Action Bar
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next/Get Started Button
                  SurakshaButton(
                    text: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _onNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
