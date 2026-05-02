import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../bloc/nav_bloc.dart';
import 'dart:ui' as ui;

class PlaceholderPage extends StatefulWidget {
  const PlaceholderPage({super.key});

  @override
  State<PlaceholderPage> createState() => _PlaceholderPageState();
}

class _PlaceholderPageState extends State<PlaceholderPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && mounted) _startListening();
      },
    );
    if (available) {
      _speech.listen(
        onResult: (result) {
          final spoken = result.recognizedWords.toLowerCase();
          if (spoken.contains('start navigation') || spoken.contains('navigation')) {
            _speech.stop();
            context.read<NavBloc>().add(const NavTo(AppPage.navigation));
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'SAFESTRIDE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        actions: isWide ? [
          _navLink('Home'),
          _navLink('Safety'),
          _navLink('About'),
          _navLink('Contact'),
          const SizedBox(width: 24),
        ] : [
          IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E1A), Color(0xFF161B22)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Hero Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: isWide 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(flex: 5, child: _buildHeroContent(context)),
                        const SizedBox(width: 40),
                        Expanded(flex: 6, child: _buildHeroImage(context)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildHeroContent(context),
                        const SizedBox(height: 60),
                        _buildHeroImage(context),
                      ],
                    ),
              ),
              
              // Services Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Safety Services',
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 4,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 48),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            _serviceCard(context, 'Real-time Alerts', Icons.notifications_active_rounded, 'Get notified of nearby danger zones instantly.', constraints.maxWidth),
                            _serviceCard(context, 'Safe Routing', Icons.route_rounded, 'Find the safest paths optimized for VRUs.', constraints.maxWidth),
                            _serviceCard(context, 'Panic Button', Icons.emergency_rounded, 'Quickly alert emergency contacts when in danger.', constraints.maxWidth),
                          ],
                        );
                      }
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () {},
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFF94A3B8)],
          ).createShader(bounds),
          child: Text(
            "Navigate with\nConfidence.",
            style: theme.textTheme.displayLarge?.copyWith(
              height: 1.1,
              fontSize: 56,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "The world's most advanced safety companion for vulnerable road users. Stay alert, stay safe.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white60,
            fontSize: 18,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),
        
        // Input Card (Glassmorphism style)
        Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Start Your Safe Journey",
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _buildInputField(
                'Pickup Location', 
                Icons.circle_outlined,
                onSubmitted: (_) => context.read<NavBloc>().add(const NavTo(AppPage.navigation)),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                'Drop Destination', 
                Icons.location_on_rounded,
                onSubmitted: (_) => context.read<NavBloc>().add(const NavTo(AppPage.navigation)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<NavBloc>().add(const NavTo(AppPage.navigation));
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start Navigation'),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String hint, IconData icon, {ValueChanged<String>? onSubmitted}) {
    return TextField(
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [const Color(0xFF2563EB).withOpacity(0.2), const Color(0xFF7C3AED).withOpacity(0.2)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_rounded, size: 200, color: Colors.white.withOpacity(0.05)),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security_rounded, size: 80, color: Color(0xFF2563EB)),
              SizedBox(height: 24),
              Text(
                "Protection on every turn",
                style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(BuildContext context, String title, IconData icon, String desc, double maxWidth) {
    final theme = Theme.of(context);
    final cardWidth = (maxWidth - 40) / (maxWidth > 800 ? 3 : 1);
    
    return Container(
      width: cardWidth > 300 ? cardWidth : maxWidth,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
