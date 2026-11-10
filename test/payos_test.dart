import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PayOS signature test', () {
    const checksumKey = '4eca21db9a5f86a5689eb95f6db1a47f26ca041a231d9971d19133f322e2879a';
    const rawData = 'amount=10000&cancelUrl=https://example.com/cancel&description=Test PayOS&orderCode=1794268880&returnUrl=https://example.com/success';
    final hmac = Hmac(sha256, utf8.encode(checksumKey));
    final digest = hmac.convert(utf8.encode(rawData));
    
    expect(digest.toString(), 'b97fdad6ff276bad37056f82feb96ef0759330dbe723aafeac10a4d22b63c37e');
  });
}
