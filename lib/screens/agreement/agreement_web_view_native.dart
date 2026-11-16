import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AgreementWebView extends StatefulWidget {
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
  State<AgreementWebView> createState() => _AgreementWebViewState();
}

class _AgreementWebViewState extends State<AgreementWebView> {
  static const _channelName = 'UniAppBridge';
  static const _bridgeScript = r'''
(function () {
  function send(value) {
    try {
      if (window.UniAppBridge) {
        window.UniAppBridge.postMessage(JSON.stringify({
          __uniapp_bridge__: true,
          data: value
        }));
      }
    } catch (_) {}
  }
  function install() {
    var uni = window.uni || {};
    uni.postMessage = function (message) { send(message); };
    uni.getEnv = function (callback) {
      if (typeof callback === 'function') {
        callback({
          plus: true,
          app: true,
          appPlus: true,
          nvue: false,
          miniProgram: false,
          h5: false
        });
      }
    };
    window.uni = uni;
    setTimeout(function () {
      document.dispatchEvent(new Event('plusready'));
      document.dispatchEvent(new Event('UniAppJSBridgeReady'));
    }, 0);
  }
  if (!window.__HSGX_UNI_MESSAGE_LISTENER__) {
    window.__HSGX_UNI_MESSAGE_LISTENER__ = true;
    window.addEventListener('message', function (event) {
      if (event && event.data) send(event.data);
    }, false);
  }
  install();
  document.addEventListener('DOMContentLoaded', install);
})();
''';

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController(onPermissionRequest: _handlePermission)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        _channelName,
        onMessageReceived: (message) => widget.onMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _injectBridge(),
          onPageFinished: (_) => _injectBridge(),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              final external = widget.onExternalUrl;
              if (external != null &&
                  RegExp(
                    r'apps\.apple\.com|open_external=true|\.(?:apk|plist)(?:$|[?#])',
                    caseSensitive: false,
                  ).hasMatch(request.url)) {
                external(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            }
            if (request.isMainFrame && uri.hasScheme) {
              widget.onExternalUrl?.call(request.url);
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _injectBridge() async {
    try {
      await _controller.runJavaScript(_bridgeScript);
    } on Object {
      // The page may still be starting or leaving; the load callbacks retry.
    }
  }

  Future<void> _handlePermission(WebViewPermissionRequest request) async {
    final permissions = <Permission>{
      if (request.types.contains(WebViewPermissionResourceType.camera))
        Permission.camera,
      if (request.types.contains(WebViewPermissionResourceType.microphone))
        Permission.microphone,
    };
    if (permissions.isEmpty) {
      await request.grant();
      return;
    }
    final result = await permissions.toList().request();
    if (result.values.every((status) => status.isGranted)) {
      await request.grant();
    } else {
      await request.deny();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
