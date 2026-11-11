import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'app_store.dart';
import 'models.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/item_form_screen.dart';
import 'screens/items_screen.dart';
import 'screens/login_screen.dart';
import 'screens/privacy_gate.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class HsgxApp extends StatefulWidget {
  const HsgxApp({super.key});

  @override
  State<HsgxApp> createState() => _HsgxAppState();
}

class _HsgxAppState extends State<HsgxApp> with WidgetsBindingObserver {
  late Brightness _platformBrightness;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppStore.instance.addListener(_handleGlobalNotice);
    _platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppStore.instance.removeListener(_handleGlobalNotice);
    super.dispose();
  }

  void _handleGlobalNotice() {
    final notice = AppStore.instance.consumeGlobalNotice();
    if (notice == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigatorContext = _navigatorKey.currentContext;
      if (navigatorContext != null) {
        showAppSnack(navigatorContext, notice);
      }
    });
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
            ? (_platformBrightness == Brightness.dark ? appSkins.length - 1 : 0)
            : skinIndex;
        final skin = appSkinAt(resolvedSkinIndex);
        final isDark = skin.brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: skin.background,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        );
        return MaterialApp(
          title: '花拾归匣',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: buildAppTheme(resolvedSkinIndex),
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const PrivacyGate(child: StartupGate()),
        );
      },
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _enteredAsGuest = false;
  late bool _wasAuthenticated;

  @override
  void initState() {
    super.initState();
    _wasAuthenticated = AppStore.instance.isAuthenticated;
    AppStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    final authenticated = AppStore.instance.isAuthenticated;
    final sessionEnded = _wasAuthenticated && !authenticated;
    _wasAuthenticated = authenticated;
    if (sessionEnded && mounted) {
      setState(() => _enteredAsGuest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    if (store.isAuthenticated || _enteredAsGuest) {
      return const MainShell();
    }
    return LoginScreen(
      onComplete: () {
        if (!mounted) return;
        setState(() => _enteredAsGuest = true);
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
  static const _pages = <Widget>[
    HomeScreen(),
    ItemsScreen(),
    InsightsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notice = AppStore.instance.consumeGuestDataNotice();
      if (notice != null && mounted) {
        showAppSnack(context, notice);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    AppStore.instance.expireGuestDataIfNeeded().then((expired) {
      if (expired && mounted) {
        showAppSnack(context, '游客数据已达到 3 天保存期限，已自动清理');
      }
    });
  }

  void selectTab(int index) {
    setState(() => currentIndex = index);
  }

  void openItems() {
    selectTab(1);
  }

  Future<void> openAddItem() async {
    if (!AppStore.instance.canAddGuestItem) {
      await _showGuestLimitDialog();
      return;
    }
    await Navigator.of(context).push<InventoryItem?>(
      MaterialPageRoute<InventoryItem?>(builder: (_) => const ItemFormScreen()),
    );
  }

  Future<void> _showGuestLimitDialog() async {
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.lock_clock_outlined, size: 30),
        title: Text('游客添加次数已用完'),
        content: Text(
          '游客模式最多可添加 3 次物品。登录后可以不限次数记录，'
          '现有记录不会丢失。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('登录继续'),
          ),
        ],
      ),
    );
    if (shouldLogin != true || !mounted) return;
    final synced = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (synced == true && mounted) {
      selectTab(0);
      showAppSnack(context, '登录成功');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: currentIndex, children: _pages),
      floatingActionButton: SizedBox(
        width: 66,
        height: 66,
        child: FloatingActionButton(
          onPressed: openAddItem,
          elevation: 8,
          tooltip: '拾一件',
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: const CircleBorder(),
          child: Icon(
            Icons.add_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 32,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _Dock(
        currentIndex: currentIndex,
        labels: _labels,
        icons: _icons,
        selectedIcons: _selectedIcons,
        onSelect: selectTab,
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.07),
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
    final scheme = Theme.of(context).colorScheme;
    final color = selected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.55);
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
          ],
        ),
      ),
    );
  }
}
