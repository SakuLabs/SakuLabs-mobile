import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mahatask/services/auth_provider.dart';
import 'package:mahatask/services/session_store.dart';
import 'package:mahatask/services/theme_provider.dart';
import 'package:mahatask/services/unread_provider.dart';

enum _SettingsSection { profile, account, appearance, notifications }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsSection _section = _SettingsSection.profile;
  bool _marketingEmail = false;
  bool _socialEmail = false;
  bool _securityEmail = true;
  final TextEditingController _nameController = TextEditingController(text: SessionStore.user?.name ?? '');
  final TextEditingController _bioController = TextEditingController(text: SessionStore.user?.bio ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<UnreadProvider>().totalUnread;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark ? const Color(0xFF111111) : Colors.white;
    final muted = isDark ? Colors.white38 : Colors.black54;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          child: Column(
            children: [
              _menuTile(_SettingsSection.profile, Icons.person_outline, 'Profile', scheme, muted),
              _menuTile(_SettingsSection.account, Icons.settings_outlined, 'Account', scheme, muted),
              _menuTile(_SettingsSection.appearance, Icons.palette_outlined, 'Appearance', scheme, muted),
              _menuTile(
                _SettingsSection.notifications,
                Icons.notifications_outlined,
                'Notifications',
                scheme,
                muted,
                trailing: unread > 0 ? '$unread' : null,
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey(_section),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: _buildSectionContent(unread, scheme, muted, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(
    _SettingsSection value,
    IconData icon,
    String title,
    ColorScheme scheme,
    Color muted, {
    String? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _section == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: active ? (isDark ? Colors.white10 : scheme.primary.withValues(alpha: 0.1)) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ListTile(
        onTap: () => setState(() => _section = value),
        leading: Icon(icon, color: active ? scheme.primary : muted),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing == null
            ? Icon(Icons.chevron_right, color: muted)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trailing,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionContent(int unread, ColorScheme scheme, Color muted, bool isDark) {
    switch (_section) {
      case _SettingsSection.profile:
        return _profilePanel(scheme, muted, isDark);
      case _SettingsSection.account:
        return _accountPanel(scheme, muted, isDark);
      case _SettingsSection.appearance:
        return _appearancePanel(scheme, muted, isDark);
      case _SettingsSection.notifications:
        return _notificationPanel(unread, scheme, muted, isDark);
    }
  }

  Widget _profilePanel(ColorScheme scheme, Color muted, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Public profile', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 4),
        Text('This is how others will see you.', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 14),
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark ? Colors.white24 : Colors.black12,
              child: Icon(Icons.person, color: muted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _nameController,
                style: TextStyle(color: scheme.onSurface),
                decoration: _inputDecoration('Username', scheme, muted, isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bioController,
          style: TextStyle(color: scheme.onSurface),
          maxLines: 3,
          decoration: _inputDecoration('Bio', scheme, muted, isDark),
        ),
        const SizedBox(height: 10),
        TextField(
          enabled: false,
          style: TextStyle(color: muted),
          decoration: _inputDecoration(SessionStore.user?.email ?? 'email@example.com', scheme, muted, isDark),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: scheme.secondary),
            child: const Text('Save changes'),
          ),
        ),
      ],
    );
  }

  Widget _accountPanel(ColorScheme scheme, Color muted, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Settings', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: 'English',
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          style: TextStyle(color: scheme.onSurface),
          decoration: _inputDecoration('Language', scheme, muted, isDark),
          items: const [
            DropdownMenuItem(value: 'English', child: Text('English')),
            DropdownMenuItem(value: 'Indonesia', child: Text('Indonesia')),
          ],
          onChanged: (_) {},
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            color: Colors.redAccent.withValues(alpha: 0.08),
          ),
          child: Text(
            'Danger Zone: Delete account is irreversible.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }

  Widget _appearancePanel(ColorScheme scheme, Color muted, bool isDark) {
    final theme = context.watch<ThemeProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 6),
        Text('Customize interface mode.', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 12),
        _themeTile('Dark', Icons.dark_mode_outlined, ThemeMode.dark, theme, scheme, muted, isDark),
        const SizedBox(height: 8),
        _themeTile('Light', Icons.light_mode_outlined, ThemeMode.light, theme, scheme, muted, isDark),
        const SizedBox(height: 8),
        _themeTile('System', Icons.phone_android_outlined, ThemeMode.system, theme, scheme, muted, isDark),
      ],
    );
  }

  Widget _themeTile(
    String label,
    IconData icon,
    ThemeMode mode,
    ThemeProvider theme,
    ColorScheme scheme,
    Color muted,
    bool isDark,
  ) {
    final active = theme.mode == mode;
    return InkWell(
      onTap: () => theme.setMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? (isDark ? Colors.white12 : scheme.primary.withValues(alpha: 0.12)) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? scheme.primary : (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? scheme.primary : muted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: scheme.onSurface)),
            const Spacer(),
            if (active) Icon(Icons.check_circle, color: scheme.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _notificationPanel(int unread, ColorScheme scheme, Color muted, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 6),
        Text('Unread direct messages: $unread', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _switchTile(
          title: 'Marketing emails',
          subtitle: 'Receive newsletter and product tips.',
          value: _marketingEmail,
          onChanged: (v) => setState(() => _marketingEmail = v),
          muted: muted,
          isDark: isDark,
          onSurface: scheme.onSurface,
        ),
        _switchTile(
          title: 'Social emails',
          subtitle: 'Friend request and group updates.',
          value: _socialEmail,
          onChanged: (v) => setState(() => _socialEmail = v),
          muted: muted,
          isDark: isDark,
          onSurface: scheme.onSurface,
        ),
        _switchTile(
          title: 'Security emails',
          subtitle: 'Important account alerts.',
          value: _securityEmail,
          onChanged: (v) => setState(() => _securityEmail = v),
          muted: muted,
          isDark: isDark,
          onSurface: scheme.onSurface,
        ),
      ],
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color muted,
    required bool isDark,
    required Color onSurface,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, ColorScheme scheme, Color muted, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: muted),
      filled: true,
      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary),
      ),
    );
  }
}

