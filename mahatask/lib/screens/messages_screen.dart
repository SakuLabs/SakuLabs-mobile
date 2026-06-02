import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../services/social_service.dart';
import '../services/unread_provider.dart';
import 'add_friend_screen.dart';
import 'chat_detail_screen.dart';

enum _MessageTab { group, direct }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with AutomaticKeepAliveClientMixin {
  final SocialService _socialService = SocialService();

  _MessageTab _tab = _MessageTab.direct;
  bool _loading = true;
  String? _error;
  List<SocialGroup> _groups = const <SocialGroup>[];
  List<SocialUser> _friends = const <SocialUser>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Future.wait<dynamic>([
        _socialService.getGroups(),
        _socialService.getFriends(),
      ]);
      if (!mounted) return;
      setState(() {
        _groups = data[0] as List<SocialGroup>;
        _friends = data[1] as List<SocialUser>;
      });
      await context.read<UnreadProvider>().refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddFriend() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFriendScreen()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final body = _MessagesBody(
      tab: _tab,
      loading: _loading,
      error: _error,
      groups: _groups,
      friends: _friends,
      onReload: _load,
      onAddFriend: _openAddFriend,
      onTabChanged: (tab) => setState(() => _tab = tab),
    );

    if (widget.embedded) return body;
    return Scaffold(backgroundColor: const Color(0xFF1D1D1F), body: body);
  }
}

class _MessagesBody extends StatelessWidget {
  const _MessagesBody({
    required this.tab,
    required this.loading,
    required this.error,
    required this.groups,
    required this.friends,
    required this.onReload,
    required this.onAddFriend,
    required this.onTabChanged,
  });

  final _MessageTab tab;
  final bool loading;
  final String? error;
  final List<SocialGroup> groups;
  final List<SocialUser> friends;
  final VoidCallback onReload;
  final VoidCallback onAddFriend;
  final ValueChanged<_MessageTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name.trim();
    final displayName = name == null || name.isEmpty ? 'Name' : name;
    final unreadByUser = context.watch<UnreadProvider>().directUnreadByUser;
    final totalUnread = context.watch<UnreadProvider>().totalUnread;

    return SafeArea(
      bottom: false,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(0.0, 393.0);
            final height = constraints.maxHeight;
            final scale = _ChatScale(width: width, height: height);
            final visibleItems = tab == _MessageTab.group ? groups : friends;

            return SizedBox(
              width: width,
              height: height,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  scale.x(39),
                  scale.y(31),
                  scale.x(39),
                  scale.y(96),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chats',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: scale.font(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: scale.y(12)),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: scale.h(785)),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFA1C4FD),
                            Color(0xFFC2E9FB),
                            Color(0xFFE0C3FC),
                          ],
                          stops: [0, 0.5, 1],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          scale.x(14),
                          scale.h(72),
                          scale.x(14),
                          scale.h(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ChatHeader(
                              scale: scale,
                              displayName: displayName,
                              totalUnread: totalUnread,
                              onAddFriend: onAddFriend,
                            ),
                            SizedBox(height: scale.h(20)),
                            Text(
                              'Messages',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: scale.font(25),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: scale.h(12)),
                            _ChatTabs(
                              scale: scale,
                              selected: tab,
                              groupsCount: groups.length,
                              friendsCount: friends.length,
                              onChanged: onTabChanged,
                            ),
                            SizedBox(height: scale.h(14)),
                            if (loading)
                              SizedBox(
                                height: scale.h(250),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2386A2),
                                  ),
                                ),
                              )
                            else if (error != null)
                              _ChatError(
                                scale: scale,
                                error: error!,
                                onReload: onReload,
                              )
                            else if (visibleItems.isEmpty)
                              _EmptyChatList(
                                scale: scale,
                                isGroup: tab == _MessageTab.group,
                              )
                            else if (tab == _MessageTab.group)
                              ...groups.map((group) {
                                return _ConversationTile(
                                  scale: scale,
                                  title: group.name,
                                  subtitle:
                                      '${group.members.length} members • Group room',
                                  icon: Icons.groups_2_outlined,
                                  accent: const Color(0xFF2386A2),
                                  unread: 0,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatDetailScreen(
                                          id: group.id,
                                          title: group.name,
                                          isGroup: true,
                                        ),
                                      ),
                                    ).then((_) => onReload());
                                  },
                                );
                              })
                            else
                              ...friends.map((friend) {
                                final unread = unreadByUser[friend.id] ?? 0;
                                return _ConversationTile(
                                  scale: scale,
                                  title: friend.name,
                                  subtitle: friend.userCode?.isNotEmpty == true
                                      ? 'Friend code ${friend.userCode}'
                                      : 'Tap to start a calm chat',
                                  icon: Icons.person_outline_rounded,
                                  accent: const Color(0xFFFF5D5D),
                                  unread: unread,
                                  avatarUrl: friend.avatarUrl,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatDetailScreen(
                                          id: friend.id,
                                          title: friend.name,
                                          isGroup: false,
                                        ),
                                      ),
                                    ).then((_) => onReload());
                                  },
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.scale,
    required this.displayName,
    required this.totalUnread,
    required this.onAddFriend,
  });

  final _ChatScale scale;
  final String displayName;
  final int totalUnread;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PixelAvatar(scale: scale, size: 32),
        SizedBox(width: scale.x(7)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(13),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: scale.font(8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (totalUnread > 0)
          Container(
            height: scale.h(28),
            padding: EdgeInsets.symmetric(horizontal: scale.x(10)),
            margin: EdgeInsets.only(right: scale.x(9)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(scale.radius(18)),
            ),
            child: Center(
              child: Text(
                '$totalUnread new',
                style: TextStyle(
                  color: const Color(0xFFFF5D5D),
                  fontSize: scale.font(10),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        _CircleAction(
          scale: scale,
          color: Colors.black,
          icon: Icons.person_add_alt_1_rounded,
          iconColor: Colors.white,
          onTap: onAddFriend,
        ),
      ],
    );
  }
}

class _ChatTabs extends StatelessWidget {
  const _ChatTabs({
    required this.scale,
    required this.selected,
    required this.groupsCount,
    required this.friendsCount,
    required this.onChanged,
  });

  final _ChatScale scale;
  final _MessageTab selected;
  final int groupsCount;
  final int friendsCount;
  final ValueChanged<_MessageTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabPill(
          scale: scale,
          label: 'Direct',
          count: friendsCount,
          icon: Icons.chat_bubble_outline_rounded,
          active: selected == _MessageTab.direct,
          onTap: () => onChanged(_MessageTab.direct),
        ),
        SizedBox(width: scale.x(8)),
        _TabPill(
          scale: scale,
          label: 'Groups',
          count: groupsCount,
          icon: Icons.groups_2_outlined,
          active: selected == _MessageTab.group,
          onTap: () => onChanged(_MessageTab.group),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.scale,
    required this.label,
    required this.count,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final _ChatScale scale;
  final String label;
  final int count;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: scale.h(38),
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(scale.radius(22)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : Colors.black,
                size: scale.w(15),
              ),
              SizedBox(width: scale.x(7)),
              Text(
                '$label $count',
                style: TextStyle(
                  color: active ? Colors.white : Colors.black,
                  fontSize: scale.font(12),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.scale,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.unread,
    required this.onTap,
    this.avatarUrl,
  });

  final _ChatScale scale;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final int unread;
  final VoidCallback onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.h(12)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            scale.x(13),
            scale.h(12),
            scale.x(11),
            scale.h(12),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(scale.radius(18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _ConversationAvatar(
                scale: scale,
                accent: accent,
                icon: icon,
                avatarUrl: avatarUrl,
                title: title,
              ),
              SizedBox(width: scale.x(11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: scale.font(15),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: scale.h(3)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF7A7A7A),
                        fontSize: scale.font(10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  constraints: BoxConstraints(minWidth: scale.w(23)),
                  height: scale.w(23),
                  margin: EdgeInsets.only(left: scale.x(8)),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: scale.font(9),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: scale.w(27),
                  height: scale.w(27),
                  margin: EdgeInsets.only(left: scale.x(8)),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9E9E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: const Color(0xFF8A8A8A),
                    size: scale.w(18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.scale,
    required this.accent,
    required this.icon,
    required this.title,
    this.avatarUrl,
  });

  final _ChatScale scale;
  final Color accent;
  final IconData icon;
  final String title;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: scale.w(42),
      height: scale.w(42),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.4),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(avatarUrl!, fit: BoxFit.cover)
            : Center(
                child: Icon(icon, color: Colors.black, size: scale.w(20)),
              ),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({
    required this.scale,
    required this.error,
    required this.onReload,
  });

  final _ChatScale scale;
  final String error;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.x(14)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(scale.radius(16)),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFFF5D5D),
              fontSize: scale.font(12),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: scale.h(8)),
          TextButton(onPressed: onReload, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyChatList extends StatelessWidget {
  const _EmptyChatList({required this.scale, required this.isGroup});

  final _ChatScale scale;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: scale.h(130),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(scale.radius(18)),
      ),
      child: Center(
        child: Text(
          isGroup ? 'No group chats yet.' : 'No friends yet.',
          style: TextStyle(
            color: const Color(0xFF5E7A83),
            fontSize: scale.font(13),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.scale,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final _ChatScale scale;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scale.w(34),
        height: scale.w(34),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: scale.w(20)),
      ),
    );
  }
}

class _PixelAvatar extends StatelessWidget {
  const _PixelAvatar({required this.scale, required this.size});

  final _ChatScale scale;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scaledSize = scale.w(size);
    return Container(
      width: scaledSize,
      height: scaledSize,
      padding: EdgeInsets.all(scaledSize * 0.07),
      decoration: BoxDecoration(
        color: const Color(0xFF78EF70),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.4),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/img/LandingPage1_icon.png',
          fit: BoxFit.cover,
          cacheWidth: 56,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}

class _ChatScale {
  const _ChatScale({required this.width, required this.height});

  final double width;
  final double height;

  double x(double value) => value * width / 393;
  double y(double value) => value * height / 852;
  double w(double value) => value * width / 393;
  double h(double value) => value * width / 393;
  double font(double value) => value * width / 393;
  double radius(double value) => value * width / 393;
}
