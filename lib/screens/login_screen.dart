import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_store.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../widgets.dart';
import 'privacy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _cloudService = CloudSyncService();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _mode = 'password';
  bool _agreementAccepted = false;
  bool _passwordVisible = false;
  bool _submitting = false;
  bool _sendingCode = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  String? _error;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phone.dispose();
    _password.dispose();
    _code.dispose();
    _authService.close();
    _cloudService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: appBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop(child: SizedBox.expand())),
          Positioned(
            top: -120,
            right: -100,
            child: _GlowCircle(
              size: 300,
              color: primary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -130,
            child: _GlowCircle(
              size: 280,
              color: appPink.withValues(alpha: 0.09),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoginHeader(primary: primary),
                        const SizedBox(height: 30),
                        SoftCard(
                          radius: 28,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SyncSummary(
                                itemCount: store.items.length,
                                wishCount: store.wishlist.length,
                              ),
                              const SizedBox(height: 18),
                              _ModeSwitcher(
                                mode: _mode,
                                enabled: !_submitting,
                                onChanged: (value) {
                                  setState(() {
                                    _mode = value;
                                    _error = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                decoration: const InputDecoration(
                                  hintText: '请输入手机号',
                                  prefixIcon: Icon(
                                    Icons.phone_iphone_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) =>
                                    RegExp(r'^1[3-9]\d{9}$')
                                        .hasMatch(value ?? '')
                                    ? null
                                    : '请输入正确的手机号',
                              ),
                              const SizedBox(height: 12),
                              if (_mode == 'password')
                                TextFormField(
                                  controller: _password,
                                  obscureText: !_passwordVisible,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    hintText: '请输入登录密码',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _passwordVisible
                                          ? '隐藏密码'
                                          : '显示密码',
                                      onPressed: () => setState(
                                        () => _passwordVisible =
                                            !_passwordVisible,
                                      ),
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                  validator: (value) =>
                                      (value ?? '').length >= 6
                                      ? null
                                      : '密码至少需要 6 位',
                                )
                              else
                                TextFormField(
                                  controller: _code,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '请输入短信验证码',
                                    prefixIcon: const Icon(
                                      Icons.verified_outlined,
                                      size: 20,
                                    ),
                                    suffixIcon: TextButton(
                                      onPressed: _countdown > 0 || _sendingCode
                                          ? null
                                          : _sendCode,
                                      child: Text(
                                        _countdown > 0
                                            ? '${_countdown}s'
                                            : _sendingCode
                                            ? '发送中'
                                            : '获取验证码',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  validator: (value) =>
                                      RegExp(r'^\d{6}$').hasMatch(value ?? '')
                                      ? null
                                      : '请输入 6 位验证码',
                                ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                _ErrorBanner(message: _error!),
                              ],
                              const SizedBox(height: 14),
                              _AgreementRow(
                                value: _agreementAccepted,
                                enabled: !_submitting,
                                onChanged: (value) =>
                                    setState(() => _agreementAccepted = value),
                                onOpenAgreement: _openAgreement,
                              ),
                              const SizedBox(height: 16),
                              _LoginButton(
                                loading: _submitting,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '同步成功后清除本机游客副本；失败时数据完整保留',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: appMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context, false),
                          child: const Text('暂不登录，继续使用游客模式'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_agreementAccepted) {
      setState(() => _error = '请先阅读并同意隐私政策和平台注册协议');
      return;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(_phone.text)) {
      setState(() => _error = '请输入正确的手机号');
      return;
    }
    setState(() {
      _sendingCode = true;
      _error = null;
    });
    try {
      await _authService.sendLoginCode(_phone.text);
      if (!mounted) return;
      setState(() => _countdown = 60);
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _countdown <= 1) {
          timer.cancel();
          if (mounted) setState(() => _countdown = 0);
          return;
        }
        setState(() => _countdown -= 1);
      });
      showAppSnack(context, '验证码已发送');
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (!_agreementAccepted) {
      setState(() => _error = '请先阅读并同意隐私政策和平台注册协议');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = _mode == 'password'
          ? await _authService.loginWithPassword(
              phone: _phone.text,
              password: _password.text,
            )
          : await _authService.loginWithCode(
              phone: _phone.text,
              code: _code.text,
            );
      final profile = await _authService.getUserProfile(
        session.token,
        fallbackPhone: session.phone,
      );
      final guestData = AppStore.instance.guestCloudData;
      final result = await _cloudService.syncGuestData(
        phone: session.phone,
        token: session.token,
        guest: guestData,
      );
      await AppStore.instance.completeAccountSync(
        token: session.token,
        phone: session.phone,
        name: profile.name,
        result: result,
        avatarPath: profile.avatarPath,
        birthday: profile.birthday,
        gender: profile.gender,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              '登录或同步失败，游客数据仍保留在本机。'
              '${error.toString().replaceFirst('Bad state: ', '')}';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openAgreement(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrivacyScreen(initialIndex: initialIndex),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'static/image/app-icon-192.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '花拾归匣',
          style: TextStyle(
            fontFamily: 'Songti SC',
            color: appText,
            fontSize: 31,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          '物有所归，心有所安',
          style: TextStyle(color: appMuted, fontSize: 12, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

class _SyncSummary extends StatelessWidget {
  const _SyncSummary({required this.itemCount, required this.wishCount});

  final int itemCount;
  final int wishCount;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.lerp(primary, Colors.white, 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.cloud_upload_outlined, color: primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '登录后同步游客记录',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount 件物品 · $wishCount 个心愿等待同步',
                  style: const TextStyle(color: appMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final String mode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1EC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _ModeItem(
            label: '密码登录',
            selected: mode == 'password',
            onTap: enabled ? () => onChanged('password') : null,
          ),
          _ModeItem(
            label: '验证码登录',
            selected: mode == 'code',
            onTap: enabled ? () => onChanged('code') : null,
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF42392D).withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? primary : appMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onOpenAgreement,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final ValueChanged<int> onOpenAgreement;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: value,
            onChanged: enabled
                ? (checked) => onChanged(checked ?? false)
                : null,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              children: [
                const Text(
                  '已阅读并同意',
                  style: TextStyle(color: appMuted, fontSize: 11),
                ),
                _AgreementLink(
                  label: '《隐私政策》',
                  onTap: () => onOpenAgreement(0),
                ),
                const Text(
                  '和',
                  style: TextStyle(color: appMuted, fontSize: 11),
                ),
                _AgreementLink(
                  label: '《平台注册协议》',
                  onTap: () => onOpenAgreement(1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AgreementLink extends StatelessWidget {
  const _AgreementLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFC04F68),
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC04F68),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, Color.lerp(primary, appBlue, 0.28)!],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_sync_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Text(
                        '登录并同步',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
