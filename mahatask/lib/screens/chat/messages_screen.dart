import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mahatask/services/auth_provider.dart';
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
  List<TaskItem> _groupTasks = const <TaskItem>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _socialService.getFriendRequests(),
        _taskService.fetchTasks(),
      ]);
      if (!mounted) return;
      setState(() {
        _groups = data[0] as List<SocialGroup>;
        _friends = data[1] as List<SocialUser>;
        _friendRequests = data[2] as List<dynamic>;
        _groupTasks = (data[3] as List<TaskItem>)
            .where((task) => task.isGroupTask)
            .toList(growable: false);
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
    final changed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => const AddFriendDialog(),
    );
    if (changed == true) await _load();
  }

  Future<void> _openFriendRequests() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _FriendRequestDialog(requests: _friendRequests),
    );
    if (changed == true) await _load();
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
      groupTasks: _groupTasks,
      searchController: _searchController,
      query: _query,
      onReload: _load,
      onAddFriend: _openAddFriend,
      onOpenRequests: _openFriendRequests,
      onOpenCallLog: _openCallLog,
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
    required this.groupTasks,
    required this.searchController,
    required this.query,
    required this.onReload,
    required this.onAddFriend,
    required this.onOpenRequests,
    required this.onOpenCallLog,
    required this.onTabChanged,
  });

  final _MessageTab tab;
  final bool loading;
  final String? error;
  final List<SocialGroup> groups;
  final List<SocialUser> friends;
  final List<dynamic> friendRequests;
  final List<TaskItem> groupTasks;
  final TextEditingController searchController;
  final String query;
  final VoidCallback onReload;
  final VoidCallback onAddFriend;
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenCallLog;
  final ValueChanged<_MessageTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name.trim();
    final displayName = name == null || name.isEmpty ? 'Name' : name;
    final unreadByUser = context.watch<UnreadProvider>().directUnreadByUser;
    final unreadByGroup = context.watch<UnreadProvider>().groupUnreadById;
    final totalUnread = context.watch<UnreadProvider>().totalUnread;
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
        final visibleItems =
            tab == _MessageTab.group ? filteredGroups : filteredFriends;

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
                  totalUnread: totalUnread,
                  requestCount: friendRequests.length,
                  onAddFriend: onAddFriend,
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
                  }),              ],
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
    required this.totalUnread,
    required this.requestCount,
    required this.onAddFriend,
    required this.onOpenRequests,
    required this.onOpenCallLog,
  });

  final _ChatScale scale;
  final String displayName;
  final int totalUnread;
  final int requestCount;
  final VoidCallback onAddFriend;
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
          icon: Icons.call_made_rounded,
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
                        ...group.members.take(3).map(
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

class _FriendRequestDialog extends StatefulWidget {
  const _FriendRequestDialog({required this.requests});

  final List<dynamic> requests;

  @override
  State<_FriendRequestDialog> createState() => _FriendRequestDialogState();
}

class _FriendRequestDialogState extends State<_FriendRequestDialog> {
  final SocialService _socialService = SocialService();
  late List<dynamic> _requests = widget.requests;
  bool _busy = false;

  Future<void> _respond(String id, {required bool accept}) async {
    setState(() => _busy = true);
    try {
      if (accept) {
        await _socialService.acceptFriendRequest(id);
      } else {
        await _socialService.rejectFriendRequest(id);
      }
      if (!mounted) return;
      setState(() {
        _requests = _requests.where((item) => _requestId(item) != id).toList();
      });
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
                    'Friend Requests',
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
            if (_requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No incoming friend requests.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ..._requests.map((request) {
                final id = _requestId(request);
                final name = _requestSenderName(request);
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
                        child: const Icon(Icons.person_rounded, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _busy || id.isEmpty ? null : () => _respond(id, accept: false),
                        child: const Text('Decline'),
                      ),
                      ElevatedButton(
                        onPressed:
                            _busy || id.isEmpty ? null : () => _respond(id, accept: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5D5D),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
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


