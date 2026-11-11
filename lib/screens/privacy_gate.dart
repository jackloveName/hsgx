import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models.dart';
import '../components/app_brand_icon.dart';
import '../services/agreement_page_launcher.dart';
import '../services/agreement_service.dart';
import '../storage/privacy_consent_store.dart';
import '../widgets.dart';
import 'privacy_screen.dart';

class PrivacyGate extends StatefulWidget {
  const PrivacyGate({super.key, required this.child});

  final Widget child;

  @override
  State<PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<PrivacyGate> {
  bool _loading = true;
  bool _accepted = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    var accepted = false;
    try {
      accepted = await PrivacyConsentStore.hasCurrentConsent();
    } on Object {
      accepted = false;
    }
    if (!mounted) return;
    setState(() {
      _accepted = accepted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    if (_loading) {
      return Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: IgnorePointer(child: widget.child),
          ),
          const ModalBarrier(dismissible: false, color: Colors.black38),
          Center(child: CircularProgressIndicator(color: primary)),
        ],
      );
    }
    if (_accepted) return widget.child;
    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: IgnorePointer(child: widget.child),
        ),
        const ModalBarrier(dismissible: false, color: Color(0x660D211D)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Dialog(
                key: const Key('privacy-consent-dialog'),
                insetPadding: EdgeInsets.zero,
                backgroundColor: scheme.surfaceContainerLowest,
                surfaceTintColor: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                elevation: 28,
                shadowColor: primary.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SizedBox(
                  width: 390,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                primary,
                                scheme.surfaceContainerLowest,
                                scheme.brightness == Brightness.dark
                                    ? 0.88
                                    : 0.86,
                              )!,
                              scheme.surfaceContainerLowest,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            AppBrandIcon(
                              size: 72,
                              radius: 23,
                              backgroundColor: scheme.surfaceContainerLowest,
                              shadowColor: primary.withValues(alpha: 0.14),
                              shadowBlur: 22,
                              shadowOffset: const Offset(0, 9),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '服务协议和隐私政策',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Songti SC',
                                color: context.appTextColor,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '开始使用前，请阅读并同意以下内容',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.appMutedColor,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  _AgreementEntry(
                                    icon: Icons.shield_outlined,
                                    title: '隐私政策',
                                    description: '了解个人信息如何被保护',
                                    accent: primary,
                                    onTap: () => _openAgreement(0),
                                  ),
                                  const ContentDivider(indent: 54),
                                  _AgreementEntry(
                                    icon: Icons.description_outlined,
                                    title: '平台注册协议',
                                    description: '查看平台服务与使用规范',
                                    accent: appAmber,
                                    onTap: () => _openAgreement(1),
                                  ),
                                ],
                              ),
                            ),
                            if (_blocked) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Color.alphaBlend(
                                    scheme.error.withValues(alpha: 0.12),
                                    scheme.surfaceContainerLowest,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '需要同意两份协议后才能继续使用',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF9B4457),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _refuse,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: context.appMutedColor,
                                      side: BorderSide(
                                        color: context.appBorderColor,
                                      ),
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text('暂不同意'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _accept,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                    ),
                                    child: Text('同意'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _accept() async {
    try {
      await PrivacyConsentStore.accept();
      if (!mounted) return;
      setState(() => _accepted = true);
    } on Object {
      if (mounted) setState(() => _blocked = true);
    }
  }

  Future<void> _refuse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认暂不同意'),
        content: Text('不同意协议将无法进入花拾归匣。你可以返回阅读协议，或确认暂不使用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('继续阅读'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('暂不使用'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await SystemNavigator.pop();
      return;
    }
    setState(() => _blocked = true);
  }

  Future<void> _openAgreement(int initialIndex) async {
    final key = initialIndex == 0
        ? AgreementService.privacyKey
        : AgreementService.registerKey;
    if (await AgreementPageLauncher.open(key) || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrivacyScreen(initialIndex: initialIndex),
      ),
    );
  }
}

class _AgreementEntry extends StatelessWidget {
  const _AgreementEntry({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.appTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: context.appMutedColor,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: context.appSurfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.appMutedColor,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
