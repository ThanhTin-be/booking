import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/api_service.dart';

class VnpayWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final String title;

  const VnpayWebviewScreen({
    super.key,
    required this.paymentUrl,
    this.title = 'Thanh toán VNPay',
  });

  @override
  State<VnpayWebviewScreen> createState() => _VnpayWebviewScreenState();
}

class _VnpayWebviewScreenState extends State<VnpayWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandledResult = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _checkReturnUrl(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkReturnUrl(url);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkReturnUrl(String url) {
    if (_hasHandledResult) return;

    if (url.contains('/api/vnpay/return')) {
      _hasHandledResult = true;
      final uri = Uri.parse(url);
      final responseCode = uri.queryParameters['vnp_ResponseCode'];
      final success = responseCode == '00';

      if (success) {
        // Gửi params tới backend qua API (bypass ngrok interstitial)
        _processReturnOnServer(uri.queryParameters);
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, success);
        }
      });
    }
  }

  Future<void> _processReturnOnServer(Map<String, String> params) async {
    try {
      debugPrint('VnpayWebview: Calling processReturn API...');
      final response = await ApiService().processVnpayReturn(params);
      final data = jsonDecode(response.body);
      debugPrint('VnpayWebview: processReturn result: ${data['success']} - ${data['message']}');
    } catch (e) {
      debugPrint('VnpayWebview: processReturn error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E56D9),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitConfirmation(),
        ),
        title: Text(
          widget.title,
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
              child: CircularProgressIndicator(color: Color(0xFF1E56D9)),
            ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hủy thanh toán?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Bạn có chắc muốn hủy giao dịch thanh toán này?',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tiếp tục thanh toán',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E56D9),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false);
            },
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
