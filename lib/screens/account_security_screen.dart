import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/app_menu_tile.dart';
import '../services/auth_service.dart';
import '../widgets.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return PageFrame(
      title: '账号与安全',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientCard(
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    store.accountName.trim().isEmpty
                        ? '拾'
                        : store.accountName.trim().characters.first,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.accountName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        store.accountPhone,
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '账号登录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                AppMenuTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFF8D7655),
                  iconBackground: const Color(0xFFF4EEE6),
                  title: '退出登录',
                  titleWeight: FontWeight.w700,
                  onTap: _processing ? null : _logout,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  iconBoxSize: 38,
                  iconSize: 19,
                  iconRadius: 12,
                ),
                const ContentDivider(),
                AppMenuTile(
                  icon: Icons.person_off_outlined,
                  iconColor: const Color(0xFFA65F5F),
                  iconBackground: const Color(0xFFFCEBEF),
                  title: '注销账号',
                  titleColor: const Color(0xFFA65F5F),
                  titleWeight: FontWeight.w700,
                  onTap: _processing ? null : _destroyAccount,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  iconBoxSize: 38,
                  iconSize: 19,
                  iconRadius: 12,
                ),
              ],
            ),
          ),
          if (_processing) ...[
            const SizedBox(height: 18),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await confirmAction(
      context,
      title: '退出登录',
      message: '退出后将清除本机账号缓存并进入新的游客模式，云端数据不会删除。',
      confirmLabel: '退出登录',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processing = true);
    final store = AppStore.instance;
    final auth = AuthService(
      onUnauthorized: AppStore.instance.handleUnauthorized,
    );
    try {
      if (store.cloudSyncPending || store.cloudSyncError != null) {
        final synced = await store.retryCloudSync();
        if (!synced) {
          if (!mounted) return;
          final discard = await confirmAction(
            context,
            title: '还有修改尚未同步',
            message: '立即退出会永久丢弃这些本机修改。确定要放弃并退出吗？',
            confirmLabel: '放弃并退出',
            destructive: true,
          );
          if (!discard || !mounted) return;
        }
      }
      try {
        await auth.logout(store.sessionToken);
      } on Object {
        // An expired remote session must not prevent local logout.
      }
      await store.logoutToGuest();
      if (!mounted) return;
      showAppSnack(context, '已退出登录');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      auth.close();
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _destroyAccount() async {
    final firstConfirmed = await confirmAction(
      context,
      title: '注销账号',
      message: '注销后账号和关联数据将永久删除，且无法恢复。是否继续？',
      confirmLabel: '继续',
      destructive: true,
    );
    if (!firstConfirmed || !mounted) return;

    final finalConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFA65F5F),
          size: 30,
        ),
        title: Text('最后确认'),
        content: Text('此操作不可撤销。账号、云端记录和本机缓存都会被清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA65F5F),
            ),
            child: Text('永久注销'),
          ),
        ],
      ),
    );
    if (finalConfirmed != true || !mounted) return;

    setState(() => _processing = true);
    final store = AppStore.instance;
    final auth = AuthService(
      onUnauthorized: AppStore.instance.handleUnauthorized,
    );
    try {
      await auth.destroyAccount(store.sessionToken);
      await store.logoutToGuest();
      if (!mounted) return;
      showAppSnack(context, '账号已注销');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        '注销失败：${error.toString().replaceFirst('Bad state: ', '')}',
      );
    } finally {
      auth.close();
      if (mounted) setState(() => _processing = false);
    }
  }
}
