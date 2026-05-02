import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<SettingsBloc>().state;
      _controller.text = state.emergencyContact ?? '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _categoryLabel(VruCategory cat) {
    switch (cat) {
      case VruCategory.blind: return 'Blind';
      case VruCategory.visuallyImpaired: return 'Visually Impaired';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('SETTINGS'),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1E1E2E), Color(0xFF0F0F1A)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocConsumer<SettingsBloc, SettingsState>(
              listenWhen: (prev, curr) => prev.emergencyContact != curr.emergencyContact,
              listener: (context, state) {
                if (_controller.text != (state.emergencyContact ?? '')) {
                  _controller.text = state.emergencyContact ?? '';
                }
              },
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('PROFILE CONFIGURATION'),
                      _buildCard(
                        children: [
                          _buildSettingItem(
                            label: 'Impairment Mode',
                            child: DropdownButtonFormField<VruCategory>(
                              value: state.vruCategory,
                              isExpanded: true,
                              items: VruCategory.values.map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(_categoryLabel(cat)),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) context.read<SettingsBloc>().add(SetVruCategory(val));
                              },
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('SAFETY & EMERGENCY'),
                      _buildCard(
                        children: [
                          _buildSettingItem(
                            label: 'Emergency Number',
                            child: TextFormField(
                              controller: _controller,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                hintText: 'Enter phone number',
                                prefixIcon: Icon(Icons.phone_iphone_rounded, color: Color(0xFF6366F1), size: 20),
                              ),
                              onFieldSubmitted: (val) {
                                context.read<SettingsBloc>().add(SetEmergencyContact(val));
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle('SYSTEM PREFERENCES'),
                      _buildCard(
                        children: [
                          _buildActionItem(
                            icon: Icons.shield_moon_rounded,
                            label: 'Security & Permissions',
                            onTap: () => _showSimpleDialog(context, 'Permissions', 'Manage system access for SafeStride.'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                          ),
                          _buildActionItem(
                            icon: Icons.info_rounded,
                            label: 'About Version',
                            onTap: () => showAboutDialog(
                              context: context,
                              applicationName: 'SafeStride',
                              applicationVersion: '2.0.0 Premium',
                              applicationIcon: const Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 48),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),
                      _buildSectionTitle('ENGINEER OPTIONS', isDev: true),
                      _buildCard(
                        color: Colors.orangeAccent.withOpacity(0.02),
                        children: [
                          _buildActionItem(
                            icon: Icons.refresh_rounded,
                            label: 'Hard Reset Onboarding',
                            iconColor: Colors.orangeAccent,
                            onTap: () {
                              context.read<SettingsBloc>().add(ResetOnboarding());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Onboarding sequence reset.')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isDev = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isDev ? Colors.orangeAccent.withOpacity(0.6) : const Color(0xFF6366F1),
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white60, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required VoidCallback onTap, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF6366F1)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? const Color(0xFF6366F1), size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.1), size: 16),
          ],
        ),
      ),
    );
  }

  void _showSimpleDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('DISMISS')),
        ],
      ),
    );
  }
}
