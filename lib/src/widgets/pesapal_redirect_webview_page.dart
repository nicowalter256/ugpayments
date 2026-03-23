import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Simple redirect page that loads the given URL inside a WebView.
class PesaPalRedirectWebViewPage extends StatefulWidget {
  final String url;

  const PesaPalRedirectWebViewPage({
    super.key,
    required this.url,
  });

  @override
  State<PesaPalRedirectWebViewPage> createState() =>
      _PesaPalRedirectWebViewPageState();
}

class _PesaPalRedirectWebViewPageState
    extends State<PesaPalRedirectWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorDescription;
  int _progress = 0;
  String? _lastUrl;
  String? _timeoutMessage;
  Timer? _timeoutTimer;
  bool get _hasValidInitialUrl {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    final allowed = host == 'pesapal.com' || host.endsWith('.pesapal.com');
    return allowed && uri.scheme == 'https';
  }

  bool _isAllowedPesapalUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return uri.scheme == 'https' && (host == 'pesapal.com' || host.endsWith('.pesapal.com'));
  }

  @override
  void initState() {
    super.initState();
    final initialAllowed = _hasValidInitialUrl;
    if (!initialAllowed) {
      _isLoading = false;
      _errorDescription = 'Blocked redirect: URL is not on *.pesapal.com';
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _errorDescription = null;
              _timeoutMessage = null;
              _progress = 0;
              _lastUrl = url;
            });
          },
          onPageFinished: (String url) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // This is the key part for debugging: if TLS/network fails, we
            // should see it instead of an endless loading spinner.
            debugPrint('PesaPal redirect webview error: ${error.description}');
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorDescription = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (!_isAllowedPesapalUrl(request.url)) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorDescription =
                      'Blocked navigation to: ${request.url}';
                });
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            if (!mounted) return;
            _lastUrl = change.url;
          },
        ),
      );

    // Restrict third-party cookies to reduce data leakage risks.
    try {
      final cookieManager = WebViewCookieManager();
      final platformCookieManager = cookieManager.platform;
      // This method exists on Android; on other platforms the call will
      // throw and we can safely ignore it.
      (platformCookieManager as dynamic).setAcceptThirdPartyCookies(
        _controller.platform as dynamic,
        false,
      );
    } catch (e) {
      debugPrint('Could not enable third-party cookies: $e');
    }

    if (initialAllowed) {
      _controller.loadRequest(Uri.parse(widget.url));
    }

    _timeoutTimer = Timer(const Duration(seconds: 25), () {
      if (!mounted) return;
      if (_errorDescription == null && _isLoading) {
        setState(() {
          _timeoutMessage =
              'Still loading after 25s. Current URL: ${_lastUrl ?? widget.url} (progress: $_progress%).';
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_errorDescription != null)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.95),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      _errorDescription!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _errorDescription = null;
                          _isLoading = true;
                        });
                        _controller.reload();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorDescription == null && _isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.transparent,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_errorDescription == null && _isLoading && _timeoutMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.92),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_bottom,
                        color: Colors.black54, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      _timeoutMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _timeoutMessage = null;
                          _isLoading = true;
                          _progress = 0;
                        });
                        _controller.reload();
                      },
                      child: const Text('Reload'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

