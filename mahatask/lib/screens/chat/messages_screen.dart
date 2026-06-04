import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mahatask/services/auth_provider.dart';
import 'package:mahatask/services/realtime_service.dart';
import 'package:mahatask/services/social_service.dart';
import 'package:mahatask/services/task_service.dart';
import 'package:mahatask/services/unread_provider.dart';
import 'package:mahatask/screens/social/add_friend_screen.dart';
import 'package:mahatask/screens/chat/chat_detail_screen.dart';

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
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();

  _MessageTab _tab = _MessageTab.direct;
  bool _loading = true;
  String? _error;
  String _query = '';
  List<SocialGroup> _groups = const <SocialGroup>[];
  List<SocialUser> _friends = const <SocialUser>[];
  List<dynamic> _friendRequests = const <dynamic>[];
  List<dynamic> _groupInvites = const <dynamic>[];
  List<TaskItem> _groupTasks = const <TaskItem>[];
  StreamSubscription<RealtimeEvent>? _socialSubscription;
  StreamSubscription<RealtimeEvent>? _messageSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.connect();
    _socialSubscription = RealtimeService.instance.socialEvents.listen(
      _handleSocialRealtime,
    );
    _messageSubscription = RealtimeService.instance.messageEvents.listen((_) {
      if (!mounted) return;
      context.read<UnreadProvider>().refresh();
    });
    _load();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _socialSubscription?.cancel();
    _messageSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await Future.wait<dynamic>([
        _socialService.getGroups(),
        _socialService.getFriends(),
        _socialService.getFriendRequests(),
        _socialService.getGroupInvites(),
        _taskService.fetchTasks(),
      ]);
      if (!mounted) return;
      setState(() {
        _groups = data[0] as List<SocialGroup>;
        _friends = data[1] as List<SocialUser>;
        _friendRequests = data[2] as List<dynamic>;
        _groupInvites = data[3] as List<dynamic>;
        _groupTasks = (data[4] as List<TaskItem>)
            .where((task) => task.isGroupTask)
            .toList(growable: false);
      });
      await context.read<UnreadProvider>().refresh();
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _handleSocialRealtime(RealtimeEvent event) async {
    if (!mounted) return;
    if (event.type == 'disconnect' || event.type == 'presence:update') return;
    await _load(silent: true);
    if (!mounted) return;

    final message = switch (event.type) {
      'friendRequest' => 'Ada friend request baru.',
      'friendRequestAccepted' => 'Friend request diterima.',
      'friendRequestRejected' => 'Friend request ditolak.',
      'groupInvite' => 'Ada undangan grup baru.',
      'groupInviteAccepted' => 'Undangan grup diterima.',
      'groupInviteRejected' => 'Undangan grup ditolak.',
      _ => '',
    };
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openAddFriend() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => const AddFriendDialog(),
    );
    if (changed == true) await _load(silent: true);
  }

  Future<void> _openFriendRequests() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _NotificationRequestDialog(
        friendRequests: _friendRequests,
        groupInvites: _groupInvites,
      ),
    );
    if (changed == true) await _load(silent: true);
  }

  Future<void> _openInviteFriends(SocialGroup group) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _GroupInviteDialog(group: group, friends: _friends),
    );
    if (changed == true) await _load(silent: true);
  }

  Future<void> _openCreateGroup() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _CreateGroupDialog(friends: _friends),
    );
    if (changed == true) await _load(silent: true);
  }

  void _openCallLog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => const _CallLogDialog(),
    );
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
      friendRequests: _friendRequests,
      groupInvites: _groupInvites,
      groupTasks: _groupTasks,
      searchController: _searchController,
      query: _query,
      onReload: _load,
      onAddFriend: _openAddFriend,
      onCreateGroup: _openCreateGroup,
      onOpenRequests: _openFriendRequests,
      onOpenCallLog: _openCallLog,
      onInviteFriends: _openInviteFriends,
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
    required this.friendRequests,
    required this.groupInvites,
    required this.groupTasks,
    required this.searchController,
    required this.query,
    required this.onReload,
    required this.onAddFriend,
    required this.onCreateGroup,
    required this.onOpenRequests,
    required this.onOpenCallLog,
    required this.onInviteFriends,
    required this.onTabChanged,
  });

  final _MessageTab tab;
  final bool loading;
  final String? error;
  final List<SocialGroup> groups;
  final List<SocialUser> friends;
  final List<dynamic> friendRequests;
  final List<dynamic> groupInvites;
  final List<TaskItem> groupTasks;
  final TextEditingController searchController;
  final String query;
  final VoidCallback onReload;
  final VoidCallback onAddFriend;
  final VoidCallback onCreateGroup;
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenCallLog;
  final ValueChanged<SocialGroup> onInviteFriends;
  final ValueChanged<_MessageTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name.trim();
    final displayName = name == null || name.isEmpty ? 'Name' : name;
    final unreadByUser = context.watch<UnreadProvider>().directUnreadByUser;
    final unreadByGroup = context.watch<UnreadProvider>().groupUnreadById;
    final topInset = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale = _ChatScale(width: width, height: height);
        final filteredGroups = query.isEmpty
            ? groups
            : groups
                  .where((group) => group.name.toLowerCase().contains(query))
                  .toList(growable: false);
        final filteredFriends = query.isEmpty
            ? friends
            : friends
                  .where(
                    (friend) =>
                        friend.name.toLowerCase().contains(query) ||
                        (friend.userCode ?? '').toLowerCase().contains(query),
                  )
                  .toList(growable: false);
        final visibleItems = tab == _MessageTab.group
            ? filteredGroups
            : filteredFriends;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB), Color(0xFFE0C3FC)],
              stops: [0, 0.5, 1],
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              scale.x(30),
              topInset + scale.y(58),
              scale.x(30),
              scale.y(122),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChatHeader(
                  scale: scale,
                  displayName: displayName,
                  requestCount: friendRequests.length + groupInvites.length,
                  primaryIcon: tab == _MessageTab.group
                      ? Icons.add_rounded
                      : Icons.person_add_alt_1_rounded,
                  onPrimaryAction: tab == _MessageTab.group
                      ? onCreateGroup
                      : onAddFriend,
                  onOpenRequests: onOpenRequests,
                  onOpenCallLog: onOpenCallLog,
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
                SizedBox(height: scale.h(12)),
                _SearchBox(scale: scale, controller: searchController),
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
                  _ChatError(scale: scale, error: error!, onReload: onReload)
                else if (visibleItems.isEmpty)
                  _EmptyChatList(
                    scale: scale,
                    isGroup: tab == _MessageTab.group,
                    onCreateGroup: tab == _MessageTab.group
                        ? onCreateGroup
                        : null,
                  )
                else if (tab == _MessageTab.group)
                  ...filteredGroups.map((group) {
                    final tasks = groupTasks
                        .where((task) => task.groupId == group.id)
                        .toList(growable: false);
                    return _ConversationTile(
                      scale: scale,
                      title: group.name,
                      subtitle:
                          '${group.members.length} members • ${tasks.length} assigned task${tasks.length == 1 ? '' : 's'}',
                      icon: Icons.groups_2_outlined,
                      accent: const Color(0xFF2386A2),
                      unread: unreadByGroup[group.id] ?? 0,
                      pinnedTaskCount: tasks.length,
                      taskPreview: tasks.isEmpty ? null : tasks.first,
                      onTaskTap: tasks.isEmpty
                          ? null
                          : () => _openGroupTasks(context, group, tasks),
                      onInviteTap: () => onInviteFriends(group),
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
                  ...filteredFriends.map((friend) {
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
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.scale,
    required this.displayName,
    required this.requestCount,
    required this.primaryIcon,
    required this.onPrimaryAction,
    required this.onOpenRequests,
    required this.onOpenCallLog,
  });

  final _ChatScale scale;
  final String displayName;
  final int requestCount;
  final IconData primaryIcon;
  final VoidCallback onPrimaryAction;
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenCallLog;

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
        _CircleAction(
          scale: scale,
          color: Colors.black,
          icon: primaryIcon,
          iconColor: Colors.white,
          onTap: onPrimaryAction,
        ),
        SizedBox(width: scale.x(9)),
        _CircleAction(
          scale: scale,
          color: Colors.white,
          icon: Icons.notifications_none_rounded,
          iconColor: Colors.black,
          badge: requestCount,
          onTap: onOpenRequests,
        ),
        SizedBox(width: scale.x(9)),
        _CircleAction(
          scale: scale,
          color: const Color(0xFFFF5D5D),
          icon: Icons.phone_rounded,
          iconColor: Colors.white,
          onTap: onOpenCallLog,
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
    this.pinnedTaskCount = 0,
    this.taskPreview,
    this.onTaskTap,
    this.onInviteTap,
  });

  final _ChatScale scale;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final int unread;
  final VoidCallback onTap;
  final String? avatarUrl;
  final int pinnedTaskCount;
  final TaskItem? taskPreview;
  final VoidCallback? onTaskTap;
  final VoidCallback? onInviteTap;

  @override
  Widget build(BuildContext context) {
    final framed = onInviteTap != null;
    return Padding(
      padding: EdgeInsets.only(bottom: scale.h(18)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: framed
              ? EdgeInsets.all(scale.x(13))
              : EdgeInsets.symmetric(horizontal: scale.x(2)),
          decoration: framed
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(scale.radius(20)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                )
              : null,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Row(
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: scale.font(15),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (pinnedTaskCount > 0) ...[
                                SizedBox(width: scale.x(5)),
                                _TaskPinBadge(
                                  scale: scale,
                                  count: pinnedTaskCount,
                                  onTap: onTaskTap,
                                ),
                              ],
                              if (onInviteTap != null) ...[
                                SizedBox(width: scale.x(5)),
                                _MiniInviteButton(
                                  scale: scale,
                                  onTap: onInviteTap!,
                                ),
                              ],
                            ],
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
                    else if (onInviteTap == null)
                      SizedBox(width: scale.w(23)),
                  ],
                ),
                if (taskPreview != null) ...[
                  SizedBox(height: scale.h(10)),
                  GestureDetector(
                    onTap: onTaskTap,
                    child: _GroupTaskPreview(scale: scale, task: taskPreview!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniInviteButton extends StatelessWidget {
  const _MiniInviteButton({required this.scale, required this.onTap});

  final _ChatScale scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scale.w(27),
        height: scale.w(27),
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_add_alt_1_rounded,
          color: Colors.white,
          size: scale.w(15),
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

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.scale, required this.controller});

  final _ChatScale scale;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: scale.h(44),
      padding: EdgeInsets.symmetric(horizontal: scale.x(14)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(scale.radius(22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.black54, size: scale.w(18)),
          SizedBox(width: scale.x(8)),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: Colors.black,
                fontSize: scale.font(12),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Search friends or groups',
                hintStyle: TextStyle(
                  color: const Color(0xFF8A8A8A),
                  fontSize: scale.font(12),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPinBadge extends StatelessWidget {
  const _TaskPinBadge({
    required this.scale,
    required this.count,
    required this.onTap,
  });

  final _ChatScale scale;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: scale.h(22),
        padding: EdgeInsets.symmetric(horizontal: scale.x(8)),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5D5D).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(scale.radius(12)),
          border: Border.all(color: const Color(0xFFFF5D5D)),
        ),
        child: Center(
          child: Text(
            'Pin $count',
            style: TextStyle(
              color: const Color(0xFFFF5D5D),
              fontSize: scale.font(8),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupTaskPreview extends StatelessWidget {
  const _GroupTaskPreview({required this.scale, required this.task});

  final _ChatScale scale;
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.x(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(scale.radius(14)),
        border: Border.all(color: const Color(0xFFFFD28A)),
      ),
      child: Row(
        children: [
          Container(
            width: scale.w(8),
            height: scale.w(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFF5D5D),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: scale.x(8)),
          Expanded(
            child: Text(
              '${task.title} • ${_taskStatusLabel(task.status)} • ${task.progress}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: scale.font(10),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTaskSheet extends StatelessWidget {
  const _GroupTaskSheet({required this.group, required this.tasks});

  final SocialGroup group;
  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${group.name} pinned tasks',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...tasks.take(6).map((task) {
              final description = task.description.trim().isEmpty
                  ? 'Belum ada detail pembagian. Tambahkan deskripsi task untuk menjelaskan siapa mengerjakan bagian apa.'
                  : task.description.trim();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${task.progress}%',
                          style: const TextStyle(
                            color: Color(0xFF2386A2),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniStatusPill(label: _taskStatusLabel(task.status)),
                        _MiniStatusPill(label: _priorityLabel(task.priority)),
                        ...group.members
                            .take(3)
                            .map(
                              (member) => _MiniStatusPill(label: member.name),
                            ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  const _MiniStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2386A2),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _NotificationRequestDialog extends StatefulWidget {
  const _NotificationRequestDialog({
    required this.friendRequests,
    required this.groupInvites,
  });

  final List<dynamic> friendRequests;
  final List<dynamic> groupInvites;

  @override
  State<_NotificationRequestDialog> createState() =>
      _NotificationRequestDialogState();
}

class _NotificationRequestDialogState
    extends State<_NotificationRequestDialog> {
  final SocialService _socialService = SocialService();
  late List<dynamic> _friendRequests = widget.friendRequests;
  late List<dynamic> _groupInvites = widget.groupInvites;
  bool _busy = false;

  Future<void> _respondFriend(String id, {required bool accept}) async {
    setState(() => _busy = true);
    try {
      if (accept) {
        await _socialService.acceptFriendRequest(id);
      } else {
        await _socialService.rejectFriendRequest(id);
      }
      if (!mounted) return;
      setState(() {
        _friendRequests = _friendRequests
            .where((item) => _requestId(item) != id)
            .toList();
      });
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respondGroup(String id, {required bool accept}) async {
    setState(() => _busy = true);
    try {
      if (accept) {
        await _socialService.acceptGroupInvite(id);
      } else {
        await _socialService.rejectGroupInvite(id);
      }
      if (!mounted) return;
      setState(() {
        _groupInvites = _groupInvites
            .where((item) => _requestId(item) != id)
            .toList();
      });
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_friendRequests.isEmpty && _groupInvites.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No incoming requests.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else ...[
              ..._friendRequests.map((request) {
                final id = _requestId(request);
                final name = _requestSenderName(request);
                return _RequestRow(
                  icon: Icons.person_rounded,
                  title: name,
                  subtitle: 'wants to be your friend',
                  busy: _busy || id.isEmpty,
                  onDecline: () => _respondFriend(id, accept: false),
                  onAccept: () => _respondFriend(id, accept: true),
                );
              }),
              ..._groupInvites.map((invite) {
                final id = _requestId(invite);
                return _RequestRow(
                  icon: Icons.groups_2_rounded,
                  title: _groupInviteTitle(invite),
                  subtitle: _groupInviteSubtitle(invite),
                  busy: _busy || id.isEmpty,
                  onDecline: () => _respondGroup(id, accept: false),
                  onAccept: () => _respondGroup(id, accept: true),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onDecline,
    required this.onAccept,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFBFEAF2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : onDecline,
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: busy ? null : onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5D5D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}

class _CallLogDialog extends StatelessWidget {
  const _CallLogDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Call Log',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No calls yet. Video calls you start from chat will appear here once call history is connected.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
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

class _InviteSettings {
  const _InviteSettings({this.role = 'MEMBER', this.canCreateSchedule = false});

  final String role;
  final bool canCreateSchedule;

  _InviteSettings copyWith({String? role, bool? canCreateSchedule}) {
    return _InviteSettings(
      role: role ?? this.role,
      canCreateSchedule: canCreateSchedule ?? this.canCreateSchedule,
    );
  }
}

class _FriendSearchField extends StatelessWidget {
  const _FriendSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        hintText: 'Search friend name',
        hintStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFEAF0F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _InviteFriendTile extends StatelessWidget {
  const _InviteFriendTile({
    required this.friend,
    required this.settings,
    required this.onChanged,
  });

  final SocialUser friend;
  final _InviteSettings? settings;
  final ValueChanged<_InviteSettings?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = settings != null;
    final current = settings ?? const _InviteSettings();
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF7FB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF2386A2) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: const Color(0xFF2386A2),
                onChanged: (value) {
                  onChanged(value == true ? current : null);
                },
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD7D7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (friend.userCode?.isNotEmpty == true)
                      Text(
                        friend.userCode!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (selected) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _InviteRoleChip(
                        label: 'Member',
                        active: current.role == 'MEMBER',
                        onTap: () =>
                            onChanged(current.copyWith(role: 'MEMBER')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InviteRoleChip(
                        label: 'Mod',
                        active: current.role == 'MODERATOR',
                        onTap: () =>
                            onChanged(current.copyWith(role: 'MODERATOR')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => onChanged(
                    current.copyWith(
                      canCreateSchedule: !current.canCreateSchedule,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          current.canCreateSchedule
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: current.canCreateSchedule
                              ? const Color(0xFF2386A2)
                              : const Color(0xFF64748B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Can create schedule',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteRoleChip extends StatelessWidget {
  const _InviteRoleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        decoration: BoxDecoration(
          color: active ? Colors.black : const Color(0xFFEAF0F6),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteEmptyState extends StatelessWidget {
  const _InviteEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD28A)),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GroupInviteDialog extends StatefulWidget {
  const _GroupInviteDialog({required this.group, required this.friends});

  final SocialGroup group;
  final List<SocialUser> friends;

  @override
  State<_GroupInviteDialog> createState() => _GroupInviteDialogState();
}

class _GroupInviteDialogState extends State<_GroupInviteDialog> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, _InviteSettings> _selected = <String, _InviteSettings>{};
  String _query = '';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SocialUser> get _candidates {
    final memberIds = widget.group.members.map((member) => member.id).toSet();
    final candidates = widget.friends
        .where((friend) => !memberIds.contains(friend.id))
        .toList(growable: false);
    if (_query.isEmpty) return candidates;
    return candidates
        .where(
          (friend) =>
              friend.name.toLowerCase().contains(_query) ||
              (friend.userCode ?? '').toLowerCase().contains(_query),
        )
        .toList(growable: false);
  }

  Future<void> _sendInvites() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      for (final entry in _selected.entries) {
        await _socialService.inviteToGroup(
          groupId: widget.group.id,
          userId: entry.key,
          role: entry.value.role,
          canCreateSchedule: entry.value.canCreateSchedule,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group invite sent.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Invite to ${widget.group.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'All friends are already in this group.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              _FriendSearchField(controller: _searchController),
            if (candidates.isNotEmpty) const SizedBox(height: 10),
            if (candidates.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 96,
                  maxHeight: 246,
                ),
                child: candidates.isEmpty
                    ? const _InviteEmptyState(text: 'No friends found.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final friend = candidates[index];
                          return _InviteFriendTile(
                            friend: friend,
                            settings: _selected[friend.id],
                            onChanged: (settings) {
                              setState(() {
                                if (settings == null) {
                                  _selected.remove(friend.id);
                                } else {
                                  _selected[friend.id] = settings;
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _selected.isEmpty || _sending ? null : _sendInvites,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _sending
                      ? 'Sending...'
                      : 'Invite ${_selected.length} friend${_selected.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog({required this.friends});

  final List<SocialUser> friends;

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final SocialService _socialService = SocialService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, _InviteSettings> _selected = <String, _InviteSettings>{};
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SocialUser> get _filteredFriends {
    if (_query.isEmpty) return widget.friends;
    return widget.friends
        .where(
          (friend) =>
              friend.name.toLowerCase().contains(_query) ||
              (friend.userCode ?? '').toLowerCase().contains(_query),
        )
        .toList(growable: false);
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final group = await _socialService.createGroup(name);
      for (final entry in _selected.entries) {
        await _socialService.inviteToGroup(
          groupId: group.id,
          userId: entry.key,
          role: entry.value.role,
          canCreateSchedule: entry.value.canCreateSchedule,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group created.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFriends = _filteredFriends;
    final height = MediaQuery.sizeOf(context).height;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.82),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Group',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _create(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: 'Group name',
                  hintStyle: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEAF0F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Invite friends',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _FriendSearchField(controller: _searchController),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 96,
                  maxHeight: 246,
                ),
                child: widget.friends.isEmpty
                    ? const _InviteEmptyState(
                        text:
                            'Belum ada teman. Tambahkan friend dulu dari tombol Add Friend.',
                      )
                    : filteredFriends.isEmpty
                    ? const _InviteEmptyState(text: 'No friends found.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];
                          return _InviteFriendTile(
                            friend: friend,
                            settings: _selected[friend.id],
                            onChanged: (settings) {
                              setState(() {
                                if (settings == null) {
                                  _selected.remove(friend.id);
                                } else {
                                  _selected[friend.id] = settings;
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _saving ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(_saving ? 'Creating...' : 'Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatList extends StatelessWidget {
  const _EmptyChatList({
    required this.scale,
    required this.isGroup,
    required this.onCreateGroup,
  });

  final _ChatScale scale;
  final bool isGroup;
  final VoidCallback? onCreateGroup;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: scale.h(150),
      child: Center(
        child: isGroup
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No group chats yet.',
                    style: TextStyle(
                      color: const Color(0xFF5E7A83),
                      fontSize: scale.font(13),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: scale.h(12)),
                  ElevatedButton(
                    onPressed: onCreateGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(scale.radius(18)),
                      ),
                    ),
                    child: const Text('Create Group'),
                  ),
                ],
              )
            : Text(
                'No friends yet.',
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
    this.badge = 0,
  });

  final _ChatScale scale;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: scale.w(34),
        height: scale.w(34),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: scale.w(20)),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints: BoxConstraints(minWidth: scale.w(16)),
                  height: scale.w(16),
                  padding: EdgeInsets.symmetric(horizontal: scale.x(4)),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5D5D),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: scale.font(7),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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

String _taskStatusLabel(String status) {
  final value = status.toUpperCase();
  if (value == 'DONE' || value == 'COMPLETED') return 'Done';
  if (value == 'IN_PROGRESS') return 'Doing';
  if (value == 'EXPIRED') return 'Expired';
  return 'To do';
}

String _priorityLabel(String priority) {
  final value = priority.toUpperCase();
  if (value == 'HIGH') return 'High';
  if (value == 'LOW') return 'Low';
  return 'Medium';
}

String _requestId(dynamic request) {
  if (request is Map<String, dynamic>) return (request['id'] ?? '').toString();
  return '';
}

String _requestSenderName(dynamic request) {
  if (request is Map<String, dynamic>) {
    final sender = request['sender'];
    if (sender is Map<String, dynamic>) {
      return (sender['name'] ?? 'Unknown user').toString();
    }
    return (request['senderName'] ?? 'Unknown user').toString();
  }
  return 'Unknown user';
}

String _groupInviteTitle(dynamic invite) {
  if (invite is Map<String, dynamic>) {
    final group = invite['group'];
    if (group is Map<String, dynamic>) {
      return (group['name'] ?? 'Group invite').toString();
    }
  }
  return 'Group invite';
}

String _groupInviteSubtitle(dynamic invite) {
  if (invite is Map<String, dynamic>) {
    final inviter = invite['inviter'];
    if (inviter is Map<String, dynamic>) {
      return 'invited by ${(inviter['name'] ?? 'a friend').toString()}';
    }
  }
  return 'invited you to join';
}

void _openGroupTasks(
  BuildContext context,
  SocialGroup group,
  List<TaskItem> tasks,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _GroupTaskSheet(group: group, tasks: tasks),
  );
}
