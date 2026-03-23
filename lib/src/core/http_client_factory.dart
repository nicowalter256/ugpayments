import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'payment_config.dart';
import 'payment_exception.dart';

/// Creates an [HttpClient] for calling upstream payment gateways.
///
/// Security:
/// - If PesaPal TLS pinning is configured (PEM certificates), only those
///   certificates are trusted by the created [HttpClient].
/// - In production, pinning is required for PesaPal to fail closed.
class HttpClientFactory {
  static const String _pinnedCertsPemKey = 'pesapal_pinned_certs_pem';

  static HttpClient createForConfig(PaymentConfig config) {
    final pinsRaw = config.additionalConfig?[_pinnedCertsPemKey];
    final pinsPem = pinsRaw is List ? pinsRaw.cast<String>() : null;

    final needsPinning = config.environment == 'production' && config.isPesaPal;

    if (pinsPem == null || pinsPem.isEmpty) {
      if (needsPinning) {
        throw PaymentException(
          'TLS pinning is required for PesaPal in production. ' +
              'Provide `additionalConfig["$_pinnedCertsPemKey"]` as a non-empty '
              'list of PEM certificate strings.',
          code: 'TLS_PINNING_REQUIRED',
        );
      }
      return HttpClient();
    }

    final securityContext = SecurityContext(withTrustedRoots: false);

    final derCerts = pinsPem
        .map((pem) => _pemToDerBytes(pem))
        .where((der) => der.isNotEmpty)
        .toList(growable: false);

    if (derCerts.isEmpty) {
      throw PaymentException(
        'TLS pinning configuration contained no usable certificates.',
        code: 'TLS_PINNING_INVALID',
      );
    }

    // Dart's API loads trusted roots one cert at a time.
    for (final der in derCerts) {
      securityContext.setTrustedCertificatesBytes(der);
    }

    return HttpClient(context: securityContext);
  }

  static Uint8List _pemToDerBytes(String pem) {
    final normalized = pem.replaceAll('\r', '').trim();

    // If it's PEM, extract base64 between header/footer.
    if (normalized.contains('-----BEGIN')) {
      final lines = normalized.split('\n');
      final base64Str = lines
          .where((line) => !line.startsWith('-----'))
          .join();
      return Uint8List.fromList(base64.decode(base64Str));
    }

    // Otherwise treat it as base64 DER.
    return Uint8List.fromList(base64.decode(normalized));
  }
}

