import 'package:flutter/material.dart';

import '../app.dart';
import '../app_store.dart';
import '../components/app_menu_tile.dart';
import '../components/icon_shortcut.dart';
import '../components/local_data_status_banner.dart';
import '../components/stored_image.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'account_security_screen.dart';
import 'badges_screen.dart';
import 'collection_screen.dart';
import 'login_screen.dart';
import 'privacy_screen.dart';
import 'profile_edit_screen.dart';
import 'recovery_screen.dart';
import 'skin_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final store = AppStore.instance;
        final primary = Theme.of(context).colorScheme.primary;
        final softPrimary = AppThemeTokens.of(context).softPrimary;
        return AppBackdrop(
          child: SafeArea(
            bottom: false,
            child: ContentPane(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 116),
                children: [
                  const Text(
                    '拾花人',
                    style: TextStyle(
                      fontFamily: 'Songti SC',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '把值得留下的日子，一物一物拾进匣中',
                    style: TextStyle(color: appMuted, fontSize: 10),
                  ),
                  const SizedBox(height: 16),
                  GradientCard(
                    padding: const EdgeInsets.all(22),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -42,
                          bottom: -44,
                          child: ClipOval(
                            child: Opacity(
                              opacity: 0.07,
                              child: Image.asset(
                                'static/image/app-icon-192.png',
                                width: 170,
                                height: 170,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: ClipOval(
                                    child: _ProfileAvatar(
                                      path: store.accountAvatarPath,
                                      fallback: store.displayName.trim().isEmpty
                                          ? '拾'
                                          : store.displayName
                                                .trim()
                                                .characters
                                                .first,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            store.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '已拾入 ${store.items.length} 件物',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (store.hasForeignCurrencyItems) ...[
                              const SizedBox(height: 8),
                              Text(
                                '金额统计仅合计人民币，另有 '
                                '${store.foreignCurrencyItemCount} 件外币物品',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _ProfileValue(
                                    label: '入匣花费',
                                    value:
                                        '¥${formatMoney(store.totalPurchaseValue)}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ProfileValue(
                                    label: '净回血',
                                    value:
                                        '¥${formatMoney(store.recoveredAmount)}',
                                    onTap: () => _push(
                                      context,
                                      const RecoveryScreen(recovered: true),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ProfileValue(
                                    label: '匣中估值',
                                    value:
                                        '¥${formatMoney(store.totalCurrentValue, compact: true)}',
                                  ),
                                ),
                              ],
                            ),
                            if (store.isGuest) ...[
                              const SizedBox(height: 15),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  13,
                                  10,
                                  8,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: const Icon(
                                        Icons.cloud_off_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '游客记录保存在本机',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            store.guestExpiryWarning
                                                ? '本地数据即将到期 · 还可添加 '
                                                      '${store.guestAddsRemaining} 次'
                                                : '还可添加 '
                                                      '${store.guestAddsRemaining} 次',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _openLogin(context),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 34),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                        ),
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.13),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      child: const Text('登录继续'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const LocalDataStatusBanner(margin: EdgeInsets.only(top: 12)),
                  const SizedBox(height: 16),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    child: Row(
                      children: [
                        Expanded(
                          child: IconShortcut(
                            label: '心愿匣',
                            icon: Icons.favorite_rounded,
                            color: primary,
                            backgroundColor: softPrimary,
                            compact: true,
                            onTap: () => _push(context, const WishlistScreen()),
                          ),
                        ),
                        Expanded(
                          child: IconShortcut(
                            label: '匣光',
                            icon: Icons.workspace_premium_rounded,
                            color: primary,
                            backgroundColor: softPrimary,
                            compact: true,
                            onTap: () => _push(context, const BadgesScreen()),
                          ),
                        ),
                        Expanded(
                          child: IconShortcut(
                            label: '珍爱',
                            icon: Icons.auto_awesome_rounded,
                            color: primary,
                            backgroundColor: softPrimary,
                            compact: true,
                            onTap: () =>
                                _push(context, const CollectionScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (store.isAuthenticated) ...[
                    const SectionHeading(title: '账号'),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Column(
                        children: [
                          AppMenuTile(
                            title: '个人信息',
                            icon: Icons.badge_outlined,
                            iconColor: primary,
                            iconBackground: softPrimary,
                            onTap: () =>
                                _push(context, const ProfileEditScreen()),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1EDE7)),
                          AppMenuTile(
                            title: '账号与安全',
                            icon: Icons.security_rounded,
                            iconColor: primary,
                            iconBackground: softPrimary,
                            onTap: () =>
                                _push(context, const AccountSecurityScreen()),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SectionHeading(title: '应用与数据'),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: Column(
                      children: [
                        AppMenuTile(
                          title: '皮肤选择',
                          icon: Icons.palette_outlined,
                          iconColor: primary,
                          iconBackground: softPrimary,
                          value: store.skinIndex < 0
                              ? '跟随系统'
                              : appSkinAt(store.skinIndex).name,
                          onTap: () => _push(context, const SkinScreen()),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1EDE7)),
                        AppMenuTile(
                          title: '隐私与协议',
                          icon: Icons.lock_outline_rounded,
                          iconColor: primary,
                          iconBackground: softPrimary,
                          onTap: () => _push(context, const PrivacyScreen()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Center(
                    child: Text(
                      '记录拥有，理性添置，愿每件物品都被善用。',
                      style: TextStyle(color: Color(0xFFAAA49C), fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _openLogin(BuildContext context) async {
    final synced = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const LoginScreen()));
    if (synced == true && context.mounted) {
      MainShell.of(context).selectTab(0);
      showAppSnack(context, '登录成功，本机记录继续保存在当前设备');
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.path, required this.fallback});

  final String path;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final clean = path.trim();
    return StoredImage(path: clean, fit: BoxFit.cover, fallback: _letter());
  }

  Widget _letter() {
    return ColoredBox(
      color: Colors.white24,
      child: Center(
        child: Text(
          fallback,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileValue extends StatelessWidget {
  const _ProfileValue({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}
