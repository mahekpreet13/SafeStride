import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:ui' as ui;
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onFinish;
  
  const OnboardingPage({super.key, this.onFinish});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;
  late TextEditingController _contactController;
  VruCategory? _selectedCategory;
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsBloc>().state;
    _contactController = TextEditingController(
      text: state.emergencyContact ?? '',
    );
    _selectedCategory = state.vruCategory;
    
    // Start the automated flow
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutomatedFlow());
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _startAutomatedFlow() async {
    if (_step == 0) {
      await _speak('Welcome to SafeStride App.');
      await Future.delayed(const Duration(seconds: 2));
      await _speak("Let's get started.");
      await Future.delayed(const Duration(seconds: 1));
      _nextStep();
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  Future<void> _announceCurrentStep() async {
    if (_step == 1) {
      await _speak('Step 2: Tell us about yourself. Please say Blind or Visually Impaired.');
      _startVoiceListener();
    } else if (_step == 2) {
      await _speak('Step 3: Emergency contact number. Say dictate to enter number.');
      _startVoiceListener();
    } else if (_step == 3) {
      await _speak('Step 4: Location access. Say grant access to continue.');
      _startVoiceListener();
    } else if (_step == 4) {
      await _speak('Setup complete. Say start journey to begin.');
      _startVoiceListener();
    }
  }

  Future<void> _startVoiceListener() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListening && mounted) {
           // Keep listening if we are still on a voice-driven step
           if (_step > 0 && _step < 5) _startVoiceListener();
        }
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          final spoken = result.recognizedWords.toLowerCase();
          
          if (_step == 1) {
            if (spoken.contains('blind')) {
              _selectCategory(VruCategory.blind);
            } else if (spoken.contains('visually impaired') || spoken.contains('impaired')) {
              _selectCategory(VruCategory.visuallyImpaired);
            }
          } else if (_step == 2) {
            if (spoken.contains('dictate')) {
              _speech.stop();
              _listenForEmergencyContact();
            }
          } else if (_step == 3) {
            if (spoken.contains('grant access') || spoken.contains('grant')) {
              _nextStep();
            }
          } else if (_step == 4) {
            if (spoken.contains('start journey') || spoken.contains('start')) {
              _finishOnboarding();
            }
          }
        },
      );
    }
  }

  void _selectCategory(VruCategory cat) async {
    setState(() => _selectedCategory = cat);
    context.read<SettingsBloc>().add(SetVruCategory(cat));
    await _speak('${_getCategoryLabel(cat)} selected.');
    await Future.delayed(const Duration(milliseconds: 500));
    _nextStep();
  }

  Future<void> _listenForEmergencyContact() async {
    await _tts.stop();
    final available = await _speech.initialize();

    if (!available) return;

    await _speak('Speak the number now. Say done when finished.');
    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        final spokenText = result.recognizedWords.trim().toLowerCase();
        final cleanedText = spokenText.replaceAll('done', '').trim();
        final normalizedNumber = _normalizePhoneNumber(cleanedText);

        if (normalizedNumber.isNotEmpty) {
          if (mounted) setState(() => _contactController.text = normalizedNumber);
        }

        if (spokenText.contains('done')) {
          if (_contactController.text.trim().isNotEmpty) {
            _speech.stop();
            _nextStep();
          }
        }
      },
      listenMode: stt.ListenMode.confirmation,
    );
  }

  String _normalizePhoneNumber(String input) {
    final wordToDigit = {'zero': '0', 'oh': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4', 'for': '4', 'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'ate': '8', 'nine': '9'};
    final parts = input.toLowerCase().split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final part in parts) {
      final cleaned = part.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (wordToDigit.containsKey(cleaned)) {
        buffer.write(wordToDigit[cleaned]);
      } else {
        buffer.write(cleaned.replaceAll(RegExp(r'[^0-9]'), ''));
      }
    }
    return buffer.toString();
  }

  void _nextStep() {
    setState(() => _step++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceCurrentStep());
  }

  void _finishOnboarding() {
    if (_selectedCategory != null) {
      context.read<SettingsBloc>().add(SetVruCategory(_selectedCategory!));
    }
    context.read<SettingsBloc>().add(SetEmergencyContact(_normalizePhoneNumber(_contactController.text)));
    if (widget.onFinish != null) widget.onFinish!();
  }

  String _getCategoryLabel(VruCategory cat) {
    switch (cat) {
      case VruCategory.blind: return 'Blind';
      case VruCategory.visuallyImpaired: return 'Visually Impaired';
    }
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withOpacity(0.15),
            ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEC4899).withOpacity(0.1),
            ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContainer({required String title, required String subtitle, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          ...children,
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return _buildStepContainer(
      title: 'Welcome to\nSafeStride',
      subtitle: 'Your intelligent companion for safer navigation on the streets.',
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.3),
                    const Color(0xFF6366F1).withOpacity(0),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(Icons.shield_rounded, size: 72, color: Color(0xFF6366F1)),
            ),
          ],
        ),
        const SizedBox(height: 80),
        SizedBox(
          width: 280,
          child: ElevatedButton(
            onPressed: _nextStep,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('GET STARTED'),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategory() {
    return _buildStepContainer(
      title: 'Personalize\nExperience',
      subtitle: 'Select the option that best describes your needs.',
      children: [
        ...VruCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () async {
                setState(() => _selectedCategory = cat);
                context.read<SettingsBloc>().add(SetVruCategory(cat));
                await _speak('${_getCategoryLabel(cat)} selected');
                await Future.delayed(const Duration(milliseconds: 500));
                _nextStep();
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))
                  ] : [],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        cat == VruCategory.blind ? Icons.visibility_off_rounded : Icons.remove_red_eye_rounded,
                        color: isSelected ? Colors.white : Colors.white38,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCategoryLabel(cat),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat == VruCategory.blind ? 'Screen reader optimizations' : 'High contrast & large fonts',
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white60 : Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContact() {
    return _buildStepContainer(
      title: 'Emergency\nContact',
      subtitle: 'We will notify this contact if any critical situation arises.',
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextFormField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. +1 555 0000',
              prefixIcon: Icon(Icons.phone_iphone_rounded, color: Color(0xFF6366F1)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isListening ? null : _listenForEmergencyContact,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  backgroundColor: Colors.white.withOpacity(0.02),
                ),
                icon: Icon(_isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded, color: const Color(0xFFEC4899)),
                label: Text(_isListening ? 'LISTENING...' : 'DICTATE', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _contactController.text.trim().isNotEmpty ? _nextStep : null,
                child: const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissions() {
    return _buildStepContainer(
      title: 'Navigation\nPlaceholder',
      subtitle: 'Precise location is required for real-time safety monitoring.',
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Mock Map
              Opacity(
                opacity: 0.3,
                child: Icon(Icons.map_rounded, size: 200, color: Colors.white10),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, size: 48, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MAP PREVIEW',
                    style: TextStyle(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 280,
          child: ElevatedButton(
            onPressed: _nextStep,
            child: const Text('GRANT ACCESS'),
          ),
        ),
      ],
    );
  }

  Widget _buildFinish() {
    return _buildStepContainer(
      title: 'Ready for\nSafety',
      subtitle: 'Setup complete! You can now start navigating securely.',
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, size: 100, color: Color(0xFF10B981)),
        ),
        const SizedBox(height: 80),
        SizedBox(
          width: 280,
          child: ElevatedButton(
            onPressed: _finishOnboarding,
            child: const Text('START JOURNEY'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;
    switch (_step) {
      case 0: currentPage = _buildIntro(); break;
      case 1: currentPage = _buildCategory(); break;
      case 2: currentPage = _buildContact(); break;
      case 3: currentPage = _buildPermissions(); break;
      case 4: currentPage = _buildFinish(); break;
      default: currentPage = _buildIntro();
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_step > 0)
                        IconButton(
                          key: const ValueKey('onboarding_back_button'),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          onPressed: () => setState(() => _step--),
                          tooltip: 'Back',
                        )
                      else
                        const SizedBox(width: 48),
                      Text(
                        'STEP ${_step + 1} OF 5',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: Colors.white38),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey(_step),
                      child: currentPage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
