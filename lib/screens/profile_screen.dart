import 'dart:io';

import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/app_menu_tile.dart';
import '../components/icon_shortcut.dart';
import '../models.dart';
import '../widgets.dart';
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
        return AppBackdrop(
          child: SafeArea(
            bottom: false,
            child: ContentPane(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 116),
                children: [
                  GradientCard(
                    colors: const [Color(0xFF61CBB4), Color(0xFF6A9DE8)],
                    padding: const EdgeInsets.all(22),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -42,
                          bottom: -44,
                          child: Opacity(
                            opacity: 0.11,
                            child: Image.asset(
                              'static/image/app-icon-192.png',
                              width: 170,
                              height: 170,
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
                                      fallback:
                                          store.displayName.characters.first,
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
                                          if (!store.isGuest) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white24,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                '云端同步',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '已登记 ${store.items.length} 件物品',
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
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _ProfileValue(
                                    label: '总花费',
                                    value:
                                        '¥${formatMoney(store.totalPurchaseValue)}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ProfileValue(
                                    label: '已回血',
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
                                    label: '当前资产',
                                    value:
                                        '¥${formatMoney(store.totalCurrentValue, compact: true)}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (store.isGuest) ...[
                    const SizedBox(height: 14),
                    SoftCard(
                      color: const Color(0xFFFFFBF2),
                      borderColor: const Color(0xFFF2E2BE),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                color: Color(0xFFC28B35),
                                size: 20,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  '游客模式',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '还可添加 ${store.guestAddsRemaining} 次物品。'
                            '游客记录只保存在本机，登录后会先上传云端，'
                            '同步成功后再清除本机游客副本。',
                            style: const TextStyle(
                              color: appMuted,
                              fontSize: 11,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: '登录并同步',
                            icon: Icons.cloud_sync_outlined,
                            onPressed: () => _openLogin(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    child: Row(
                      children: [
                        Expanded(
                          child: IconShortcut(
                            label: '心愿匣',
                            icon: Icons.favorite_rounded,
                            color: const Color(0xFFC6657D),
                            backgroundColor: const Color(0xFFFAEDF2),
                            compact: true,
                            onTap: () => _push(context, const WishlistScreen()),
                          ),
                        ),
                        Expanded(
                          child: IconShortcut(
                            label: '徽章',
                            icon: Icons.workspace_premium_rounded,
                            color: const Color(0xFFC28B35),
                            backgroundColor: const Color(0xFFFBF3DF),
                            compact: true,
                            onTap: () => _push(context, const BadgesScreen()),
                          ),
                        ),
                        Expanded(
                          child: IconShortcut(
                            label: '收藏馆',
                            icon: Icons.auto_awesome_rounded,
                            color: const Color(0xFF806CC2),
                            backgroundColor: const Color(0xFFF1EEF9),
                            compact: true,
                            onTap: () =>
                                _push(context, const CollectionScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeading(title: '应用与数据'),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: Column(
                      children: [
                        if (store.isAuthenticated) ...[
                          AppMenuTile(
                            title: '个人信息',
                            icon: Icons.badge_outlined,
                            iconColor: const Color(0xFF3A9D8A),
                            iconBackground: const Color(0xFFE7F6F1),
                            onTap: () =>
                                _push(context, const ProfileEditScreen()),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1EDE7)),
                        ],
                        AppMenuTile(
                          title: '皮肤选择',
                          icon: Icons.palette_outlined,
                          iconColor: const Color(0xFF8B78C9),
                          iconBackground: const Color(0xFFF1EEF9),
                          value: store.skinIndex < 0
                              ? '跟随系统'
                              : appSkinAt(store.skinIndex).name,
                          onTap: () => _push(context, const SkinScreen()),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1EDE7)),
                        AppMenuTile(
                          title: '隐私与协议',
                          icon: Icons.lock_outline_rounded,
                          iconColor: const Color(0xFF607FC7),
                          iconBackground: const Color(0xFFEDF2FB),
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
      showAppSnack(context, '游客数据已同步到云端，本机游客副本已清理');
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
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _letter(),
      );
    }
    if (clean.isNotEmpty) {
      return Image.file(
        File(clean),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _letter(),
      );
    }
    return _letter();
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
