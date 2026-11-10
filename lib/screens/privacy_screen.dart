import 'package:flutter/material.dart';

import '../models.dart';
import '../services/agreement_service.dart';
import '../widgets.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen>
    with SingleTickerProviderStateMixin {
  static const _documents = [
    (
      key: AgreementService.privacyKey,
      title: '隐私政策',
      icon: Icons.shield_outlined,
    ),
    (
      key: AgreementService.registerKey,
      title: '平台注册协议',
      icon: Icons.description_outlined,
    ),
  ];

  final _service = AgreementService();
  final Map<String, Future<String>> _requests = {};
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _documents.length,
      initialIndex: widget.initialIndex.clamp(0, _documents.length - 1),
      vsync: this,
    )..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _service.close();
    super.dispose();
  }

  Future<String> _document(String key) {
    return _requests.putIfAbsent(key, () => _service.fetch(key));
  }

  void _retry(String key) {
    setState(() => _requests.remove(key));
  }

  void _changeTabBySwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 180) return;
    final target = velocity < 0
        ? _tabController.index + 1
        : _tabController.index - 1;
    if (target >= 0 && target < _documents.length) {
      _tabController.animateTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = _documents[_tabController.index];
    final primary = Theme.of(context).colorScheme.primary;
    return PageFrame(
      title: '隐私与协议',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appBorder),
            ),
            child: TabBar(
              controller: _tabController,
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Color.lerp(primary, Colors.white, 0.88),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: primary,
              unselectedLabelColor: appMuted,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                for (final document in _documents)
                  Tab(height: 40, text: document.title),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _changeTabBySwipe,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _AgreementDocument(
                key: ValueKey(document.key),
                icon: document.icon,
                content: _document(document.key),
                onRetry: () => _retry(document.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementDocument extends StatelessWidget {
  const _AgreementDocument({
    super.key,
    required this.icon,
    required this.content,
    required this.onRetry,
  });

  final IconData icon;
  final Future<String> content;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: content,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Column(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 14),
                Text(
                  '正在加载协议内容…',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError || snapshot.data?.trim().isEmpty != false) {
          return SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(height: 14),
                const Text(
                  '协议内容加载失败',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                const Text(
                  '请检查网络后重新加载',
                  style: TextStyle(color: appMuted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: '重新加载',
                  icon: Icons.refresh_rounded,
                  expanded: false,
                  onPressed: onRetry,
                ),
              ],
            ),
          );
        }

        return SoftCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          child: SelectableText(
            snapshot.data!,
            style: const TextStyle(
              color: Color(0xFF55534F),
              fontSize: 14,
              height: 1.75,
            ),
          ),
        );
      },
    );
  }
}
