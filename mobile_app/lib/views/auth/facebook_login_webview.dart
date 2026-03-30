import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Facebook Login bằng WebView + Authorization Code flow
/// Trả về authorization code (String) hoặc null nếu user huỷ
class FacebookLoginWebView extends StatefulWidget {
  final String appId;
  final String redirectUri;

  const FacebookLoginWebView({
    super.key,
    required this.appId,
    required this.redirectUri,
  });

  @override
  State<FacebookLoginWebView> createState() => _FacebookLoginWebViewState();
}

class _FacebookLoginWebViewState extends State<FacebookLoginWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandledResult = false;

  @override
  void initState() {
    super.initState();
    // Xoá cookies Facebook cũ để luôn hiện trang login mới
    WebViewCookieManager().clearCookies();

    // Dùng response_type=code (Authorization Code flow)
    // Implicit flow (response_type=token) không hoạt động ở Development mode
    final loginUrl = 'https://www.facebook.com/v18.0/dialog/oauth'
        '?client_id=${widget.appId}'
        '&redirect_uri=${Uri.encodeComponent(widget.redirectUri)}'
        '&scope=email,public_profile'
        '&response_type=code'
        '&display=touch';

    debugPrint('🔵 Facebook OAuth URL: $loginUrl');

    _controller = WebViewController()

    // Xoá cookies cũ để luôn hiện trang login mới
    ..clearLocalStorage()
    ..clearCache()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('🌐 FB started: $url');
            if (mounted) setState(() => _isLoading = true);
            _checkForCode(url);
          },
          onPageFinished: (url) {
            debugPrint('✅ FB finished: $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            debugPrint('🔗 FB nav: ${request.url}');
            if (_checkForCode(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('❌ FB error: ${error.description} (${error.errorCode})');
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  /// Kiểm tra URL có chứa authorization code không
  bool _checkForCode(String url) {
    if (_hasHandledResult) return true;

    if (url.startsWith(widget.redirectUri)) {
      _hasHandledResult = true;
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (code != null && code.isNotEmpty) {
        debugPrint('✅ Got Facebook authorization code!');
        Navigator.pop(context, code);
      } else {
        debugPrint('❌ Facebook error: $error');
        Navigator.pop(context, null);
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(
          'Đăng nhập Facebook',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1877F2)),
            ),
        ],
      ),
    );
  }
}
