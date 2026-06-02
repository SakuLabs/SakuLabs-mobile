import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.messagesUnread = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int messagesUnread;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.checklist_rounded, label: 'Tasks'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chats'),
    _NavItem(icon: Icons.ac_unit_rounded, label: 'SakuAI'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 38).clamp(0.0, 355.0);

            return Container(
              width: width,
              margin: const EdgeInsets.fromLTRB(19, 0, 19, 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isActive = currentIndex == index;
                  return _DashboardNavButton(
                    item: item,
                    active: isActive,
                    unread: index == 2 ? messagesUnread : 0,
                    onTap: () => onTap(index),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardNavButton extends StatelessWidget {
  const _DashboardNavButton({
    required this.item,
    required this.active,
    required this.unread,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: active ? 66 : 56,
        height: active ? 66 : 52,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF5D5D) : Colors.transparent,
          shape: active ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: active ? Colors.white : Colors.black,
                  size: active ? 28 : 21,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black,
                    fontSize: active ? 8 : 8,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (unread > 0)
              Positioned(
                top: 5,
                right: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
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

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
