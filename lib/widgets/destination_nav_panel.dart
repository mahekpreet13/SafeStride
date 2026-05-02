import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:safe_stride/bloc/navigation_bloc.dart';
import 'package:safe_stride/bloc/navigation_event.dart';
import 'package:safe_stride/bloc/navigation_state.dart';
import 'package:safe_stride/services/route_danger_analysis_service.dart';
import 'package:safe_stride/services/predictive_alert_service.dart';
import 'package:safe_stride/services/navigation_voice_service.dart';

/// A premium destination search + danger-aware navigation panel.
///
/// Shows:
/// - Address search bar with live autocomplete
/// - GO / Stop navigation button
/// - Danger-on-route banner with spoken reason
/// - Live step-by-step instruction card
class DestinationNavPanel extends StatefulWidget {
  const DestinationNavPanel({super.key});

  @override
  State<DestinationNavPanel> createState() => _DestinationNavPanelState();
}

class _DestinationNavPanelState extends State<DestinationNavPanel>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  RouteDangerReport? _lastSpokenReport;
  late AnimationController _bannerAnim;
  late Animation<double> _bannerSlide;

  @override
  void initState() {
    super.initState();
    _bannerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bannerSlide = CurvedAnimation(parent: _bannerAnim, curve: Curves.easeOut);
    
    _startGlobalVoiceListener();
  }

  Future<void> _startGlobalVoiceListener() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && mounted) _startGlobalVoiceListener();
      },
    );
    if (available) {
      _speech.listen(
        onResult: (result) {
          final spoken = result.recognizedWords.toLowerCase();
          
          if (spoken.contains('navigate to') || spoken.contains('go to')) {
            final destination = spoken.split(RegExp(r'navigate to|go to')).last.trim();
            if (destination.isNotEmpty) {
              _controller.text = destination;
              _submitSearch();
            }
          } else if (spoken.contains('start navigation') || (spoken.contains('start') && !spoken.contains('journey'))) {
            final state = context.read<NavigationBloc>().state;
            if (state.routePoints != null && !state.isNavigating && !state.routeLoading) {
               context.read<NavigationBloc>().add(StartNavigation());
            }
          } else if (spoken.contains('stop navigation') || spoken.contains('stop')) {
             _controller.clear();
             _lastSpokenReport = null;
             context.read<NavigationBloc>().add(StopNavigation());
          }
        },
      );
    }
  }

  void _speak(String text, [VoicePriority priority = VoicePriority.info]) {
    navigationVoice.speak(text, priority);
  }

  void _onReportReceived(RouteDangerReport report) {
    if (_lastSpokenReport == report) return;
    _lastSpokenReport = report;
    _bannerAnim.forward(from: 0);
    _speak(report.reason,
        report.isDangerous ? VoicePriority.safety : VoicePriority.info);
  }

  void _submitSearch() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _focusNode.unfocus();
    context.read<NavigationBloc>()
      ..add(DestinationAddressChanged(text))
      ..add(ShowSuggestionsChanged(false))
      ..add(SearchAddress(text));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _bannerAnim.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NavigationBloc, NavigationState>(
      listenWhen: (prev, curr) =>
          curr.routeDangerReport != null &&
          curr.routeDangerReport != prev.routeDangerReport,
      listener: (context, state) {
        if (state.routeDangerReport != null) {
          _onReportReceived(state.routeDangerReport!);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Search bar ──────────────────────────────────────────────────
            _SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              isNavigating: state.isNavigating,
              isLoading: state.routeLoading,
              onChanged: (v) {
                context.read<NavigationBloc>().add(UpdateSuggestions(v));
              },
              onSubmitted: (_) => _submitSearch(),
              onSearch: _submitSearch,
              onStop: () {
                _controller.clear();
                _lastSpokenReport = null;
                context.read<NavigationBloc>().add(StopNavigation());
              },
            ),

            // ── Autocomplete suggestions ────────────────────────────────────
            if (state.showSuggestions && state.suggestions.isNotEmpty)
              _SuggestionDropdown(
                suggestions: state.suggestions,
                onSelect: (s) {
                  _controller.text = s;
                  context.read<NavigationBloc>()
                    ..add(DestinationAddressChanged(s))
                    ..add(SelectSuggestion(s));
                },
              ),

            // ── Danger/safe banner ──────────────────────────────────────────
            if (state.routeDangerReport != null)
              SizeTransition(
                sizeFactor: _bannerSlide,
                child: _DangerBanner(report: state.routeDangerReport!),
              ),

            // ── GO button (shown after route loaded, before navigating) ─────
            if (state.routePoints != null &&
                !state.isNavigating &&
                !state.routeLoading)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    context.read<NavigationBloc>().add(StartNavigation());
                    // The bloc now handles the fused GO announcement.
                  },
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text(
                    'GO – Start Navigation',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),

            // ── Fused step + predictive card ────────────────────────────────
            if (state.isNavigating)
              _FusedStepCard(
                instructions: state.instructions,
                predictiveAlert: state.predictiveAlert,
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isNavigating;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;
  final VoidCallback onStop;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isNavigating,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSearch,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        elevation: 4,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: isNavigating,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: isNavigating
                ? 'Navigating…'
                : 'Enter destination address',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search_rounded),
            ),
            suffixIcon: isNavigating
                ? IconButton(
                    icon: const Icon(Icons.stop_circle_rounded,
                        color: Colors.red, size: 28),
                    tooltip: 'Stop navigation',
                    onPressed: onStop,
                  )
                : (controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: Color(0xFF1565C0)),
                        tooltip: 'Search',
                        onPressed: onSearch,
                      )
                    : null),
            filled: true,
            fillColor: theme.cardColor.withOpacity(0.8),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionDropdown extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  const _SuggestionDropdown({
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, thickness: 0.5),
            itemBuilder: (context, i) {
              final s = suggestions[i];
              return InkWell(
                onTap: () => onSelect(s),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DangerBanner extends StatelessWidget {
  final RouteDangerReport report;

  const _DangerBanner({required this.report});

  @override
  Widget build(BuildContext context) {
    final isDanger = report.isDangerous;
    final bgColor = isDanger
        ? const Color(0xFFEF4444).withOpacity(0.9)
        : const Color(0xFF10B981).withOpacity(0.9);
    final icon = isDanger
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;
    final label = isDanger ? '⚠️ Danger on Route' : '✅ Route is Clear';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: isDanger
                  ? Colors.red.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    report.reason,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      height: 1.4,
                    ),
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

/// Fused turn-by-turn + safety card.
///
/// Shows the current navigation step and overlays a danger ribbon above it
/// when a predictive alert is active.
class _FusedStepCard extends StatelessWidget {
  final List<dynamic> instructions;
  final PredictiveAlert predictiveAlert;

  const _FusedStepCard({
    required this.instructions,
    required this.predictiveAlert,
  });

  @override
  Widget build(BuildContext context) {
    final step = instructions.isNotEmpty ? instructions.first : null;

    final hasAlert = predictiveAlert.level != PredictiveAlertLevel.none;
    final isImminent = predictiveAlert.level == PredictiveAlertLevel.imminent;

    // Gradient: blue for safe nav, orange approaching, red imminent
    final List<Color> gradientColors = hasAlert
        ? (isImminent
            ? [const Color(0xFFEF4444), const Color(0xFF991B1B)]
            : [const Color(0xFFF59E0B), const Color(0xFFB45309)])
        : [const Color(0xFF2563EB), const Color(0xFF1E40AF)];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (hasAlert ? Colors.orange : Colors.blue).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Predictive danger ribbon (only when approaching / imminent) ───
          if (hasAlert)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(
                    isImminent
                        ? Icons.warning_rounded
                        : Icons.sensors_rounded,
                    color: Colors.amberAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      predictiveAlert.uiLabel,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Turn instruction ──────────────────────────────────────────────
          if (step != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _turnIcon(step['sign'] ?? 0),
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _buildStepText(step),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else if (!hasAlert)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                'Follow the route…',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  String _buildStepText(dynamic step) {
    final text =
        (step['text'] ?? step['instruction'] ?? 'Follow the route').toString();
    final distanceM = (step['distance'] as num?)?.toInt() ?? 0;
    final distLabel = distanceM > 0 ? ' — ${_formatDistance(distanceM)}' : '';
    return '$text$distLabel';
  }

  /// Maps GraphHopper sign codes to turn icons.
  IconData _turnIcon(int sign) {
    switch (sign) {
      case -3:
        return Icons.turn_sharp_left_rounded;
      case -2:
        return Icons.turn_left_rounded;
      case -1:
        return Icons.turn_slight_left_rounded;
      case 1:
        return Icons.turn_slight_right_rounded;
      case 2:
        return Icons.turn_right_rounded;
      case 3:
        return Icons.turn_sharp_right_rounded;
      case 4:
        return Icons.flag_rounded; // destination
      case 5:
        return Icons.u_turn_left_rounded;
      case 6:
        return Icons.u_turn_right_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '$meters m';
  }
}

