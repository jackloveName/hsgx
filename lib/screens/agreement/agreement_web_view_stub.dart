import 'package:flutter/material.dart';

class AgreementWebView extends StatelessWidget {
  const AgreementWebView({
    super.key,
    required this.url,
    required this.onMessage,
    this.onExternalUrl,
  });

  final String url;
  final ValueChanged<Object?> onMessage;
  final ValueChanged<String>? onExternalUrl;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('内嵌服务页面仅支持 Android 和 iOS App。'));
  }
}
