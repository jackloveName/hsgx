import 'package:flutter/material.dart';

import 'app_store.dart';
import 'components/items_filter_controller.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/item_form_screen.dart';
import 'screens/items_screen.dart';
import 'screens/login_screen.dart';
import 'screens/privacy_gate.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';

class HsgxApp extends StatefulWidget {
  const HsgxApp({super.key});

  @override
  State<HsgxApp> createState() => _HsgxAppState();
}

class _HsgxAppState extends State<HsgxApp> with WidgetsBindingObserver {
  late Brightness _platformBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (brightness != _platformBrightness) {
      setState(() => _platformBrightness = brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppStore.instance.skinListenable,
      builder: (context, skinIndex, _) {
        final resolvedSkinIndex = skinIndex < 0
            ? (_platformBrightness == Brightness.dark ? 9 : 0)
            : skinIndex;
        return MaterialApp(
          title: '花拾归匣',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(resolvedSkinIndex),
          home: const PrivacyGate(child: MainShell()),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static MainShellState of(BuildContext context) {
    return context.findAncestorStateOfType<MainShellState>()!;
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int currentIndex = 0;
  final _itemsFilterController = ItemsFilterController();

  static const _labels = ['首页', '物品', '洞察', '我的'];
  static const _icons = [
    Icons.home_outlined,
    Icons.inventory_2_outlined,
    Icons.auto_graph_rounded,
    Icons.person_outline_rounded,
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.inventory_2_rounded,
    Icons.auto_graph_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notice = AppStore.instance.consumeGuestDataNotice();
      if (notice != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(notice)));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _itemsFilterController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    AppStore.instance.expireGuestDataIfNeeded().then((expired) {
      if (expired && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('游客数据已达到 3 天保存期限，已自动清理')));
      }
    });
  }

  void selectTab(int index) {
    setState(() => currentIndex = index);
  }

  void openItemsFilter(String filter) {
    _itemsFilterController.value = filter;
    selectTab(1);
  }

  Future<void> openAddItem() async {
    if (!AppStore.instance.canAddGuestItem) {
      await _showGuestLimitDialog();
      return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ItemFormScreen()));
  }

  Future<void> _showGuestLimitDialog() async {
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_clock_outlined, size: 30),
        title: const Text('游客添加次数已用完'),
        content: const Text(
          '游客模式最多可添加 3 次物品。登录后可以不限次数记录，'
          '当前游客数据会在同步成功后迁移到云端。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('登录并同步'),
          ),
        ],
      ),
    );
    if (shouldLogin != true || !mounted) return;
    final synced = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (synced == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('登录成功，游客数据已同步到云端')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(),
      ItemsScreen(filterController: _itemsFilterController),
      const InsightsScreen(),
      const ProfileScreen(),
    ];
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: IndexedStack(index: currentIndex, children: pages),
          floatingActionButton: SizedBox(
            width: 66,
            height: 66,
            child: FloatingActionButton(
              onPressed: openAddItem,
              elevation: 8,
              tooltip: '添加物品',
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _Dock(
            currentIndex: currentIndex,
            labels: _labels,
            icons: _icons,
            selectedIcons: _selectedIcons,
            onSelect: selectTab,
          ),
        );
      },
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.currentIndex,
    required this.labels,
    required this.icons,
    required this.selectedIcons,
    required this.onSelect,
  });

  final int currentIndex;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: Color(0xFFF0EAE1))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42392D).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(
                  child: _DockItem(
                    label: labels[index],
                    icon: index == currentIndex
                        ? selectedIcons[index]
                        : icons[index],
                    selected: index == currentIndex,
                    onTap: () => onSelect(index),
                  ),
                ),
                if (index == 1) const SizedBox(width: 72),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF8E8990);
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
