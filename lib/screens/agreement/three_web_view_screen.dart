import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/borrow_agreement_service.dart';
import '../../widgets.dart';
import 'agreement_web_view.dart';

class ThreeWebViewScreen extends StatefulWidget {
  const ThreeWebViewScreen({super.key, required this.url});

  final String url;

  @override
  State<ThreeWebViewScreen> createState() => _ThreeWebViewScreenState();
}

class _ThreeWebViewScreenState extends State<ThreeWebViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!isSafeWebUrl(widget.url)) {
        showAppSnack(context, '链接地址无效');
        Navigator.pop(context);
        return;
      }
      if (isExternalWebUrl(widget.url)) {
        _openExternal(widget.url);
      }
    });
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Object {
        opened = false;
      }
    }
    if (mounted) {
      if (!opened) showAppSnack(context, '无法打开外部链接');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 42,
        title: const SizedBox.shrink(),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: isSafeWebUrl(widget.url) && !isExternalWebUrl(widget.url)
          ? AgreementWebView(
              key: ValueKey(widget.url),
              url: widget.url,
              onMessage: (_) {},
              onExternalUrl: _openExternal,
            )
          : const SizedBox.shrink(),
    );
  }
}
