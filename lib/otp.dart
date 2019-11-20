import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:base32/base32.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

enum Algorithm {
  sha1, sha256, sha512
}

Algorithm _stringToAlgo(String name) {
  switch(name.toUpperCase()) {
    case 'SHA1':
      return Algorithm.sha1;
    case 'SHA256': 
      return Algorithm.sha256;
    case 'SHA512':
      return Algorithm.sha512;
    default:
      throw Exception('attempted to parse unknown algorithm: $name');
  }
}

enum Type {
  hotp, totp
}

class Otp {
  Otp._({this.type, 
  this.secret, 
  this.issuer = '', 
  this.labelIssuer = '', 
  this.accountName = '', 
  this.counter = 0, 
  this.digits = 6, 
  this.algo = Algorithm.sha1, 
  this.period = 30, 
  this.startTime = 0}) {
    switch(type) {
      case Type.hotp:
        code = ValueNotifier(Otp.hotpCode(secret, counter));
        currentCodeLife = ValueNotifier(0);
        break;
      case Type.totp:
        counter = (((DateTime.now().millisecondsSinceEpoch * 1000) - startTime) / period).floor();
        code = ValueNotifier(Otp.hotpCode(secret, counter, digits: this.digits));
        currentCodeLife = ValueNotifier(period);
        _timer = Timer.periodic(Duration(seconds: 1), (t) {
          currentCodeLife.value--;
          if (currentCodeLife.value == 0) {
            counter++;
            currentCodeLife.value = period;
            code.value = Otp.hotpCode(secret, counter, digits: this.digits);
          }
        });
        break;
    }
  }

  Type type;
  String secret;
  int counter;
  int digits;
  Algorithm algo;
  int period;
  int startTime;
  String issuer;
  String labelIssuer;
  String accountName;
  Timer _timer;
  ValueNotifier<String> code;
  ValueNotifier<int> currentCodeLife;

  // parse a URI and return a running instance of OTP
  static fromUri(String uri) {
    Uri u = Uri.parse(uri);
    if (u.scheme != 'otpauth') {
      throw Exception('uri had scheme ${u.scheme}, not otpauth');
    }
    
    Type type = u.host == 'totp' ? Type.totp : Type.hotp;

    // parse issuer from parameter first, then the prefix as a fallback
    // if neither exists, throw
    // TODO: if no issuer, maybe pop up box to ask user to fill one in
    if (u.queryParameters['issuer'] == null && !u.path.contains(':')) {
      throw Exception('uri is missing issuer, uri: $uri');
    }
    String issuer = u.queryParameters['issuer'] != null ? u.queryParameters['issuer'] : u.path.split(':')[0]; 

    // display the prefix to the user, use the parameter as a fallback. 
    // if neither exists, use empty string. 
    // TODO: throw if none exists?
    String displayedIssuer = u.path.contains(':') ? u.path.split(':')[0] ?? '': u.queryParameters['issuer'] ?? '';
    
    // account name is in the label. if a prefix exists, it is after a :
    // if no prefix, it's the whole path
    String accountName = u.path.contains(':') ? u.path.split(':')[1] : u.path;

    if (u.queryParameters['secret'] == null) {
      throw Exception('uri had no secret parameter, uri: $uri');
    }
    String secret = u.queryParameters['secret'];
    
    Algorithm algo = u.queryParameters['algorithm'] != null ? _stringToAlgo(u.queryParameters['algorithm']) : Algorithm.sha1;
    int digits = u.queryParameters['digits'] != null ? int.parse(u.queryParameters['digits']) : 6;
    int period = u.queryParameters['period'] != null ? int.parse(u.queryParameters['period']) : 30;
    int startTime = 0; // TODO: any documentation on supplying a different starting time?? 
    int counter = 0; // TODO: any documentation on supplying initial htop value??

    if (type == Type.totp) {
      print('creating $period second totp with $digits digits from uri: $uri');
      return Otp.totp(secret, uri: uri, labelIssuer: displayedIssuer, issuer: issuer, accountName: accountName, digits: digits, algo: algo, period: period, startTime: startTime);
    }
    print('creating hotp with $digits digits from uri: $uri');
    return Otp.hotp(secret, counter, uri: uri, labelIssuer: displayedIssuer, issuer: issuer, accountName: accountName, digits: digits, algo: algo);
  }

  static bool validate(String uri) {

  }

  static Otp totp(String secret, {uri = '', issuer = '', labelIssuer = '', accountName = '', digits = 6, algo = Algorithm.sha1, period = 30, startTime = 0}) {
    return Otp._(type: Type.totp, secret: secret, digits: digits, issuer: issuer, labelIssuer: labelIssuer, accountName: accountName, algo: algo, period: period, startTime: startTime);
  }

  static Otp hotp(String secret, int counter, {uri = '', issuer = '', labelIssuer = '', accountName = '', digits = 6, algo = Algorithm.sha1}) {
    return Otp._(type: Type.hotp, secret: secret,  counter: counter, issuer: issuer, labelIssuer: labelIssuer, accountName: accountName, digits: digits, algo: algo);
  }

  // generate a totp code
  static String totpCode(String secret, int time, {int digits: 6, int period: 30, int initial: 0, algo: Algorithm.sha1}) {
    int counter = ((time - initial) / period).floor();
    return _code(secret, counter, digits: digits);
  }
  
  // generate an hotp code
  static String hotpCode(String secret, int counter, {int digits: 6, algo: Algorithm.sha1}) {
    return _code(secret, counter, digits: digits);
  }

  requestCode() {
    if (type == Type.totp) {
      debugPrint('code requested by totp? ignoring...');
      return;
    }
    counter++;
    code.value = _code(this.secret, this.counter, digits: this.digits, algo: this.algo);
    _updateStoredUri();
  }

  bool match(String filter) {
    if (filter == '') {
      return true;
    }
    if (labelIssuer.toLowerCase().contains(filter.toLowerCase())) {
      return true;
    }
    if (issuer.toLowerCase().contains(filter.toLowerCase())) {
      return true;
    }
    if (accountName.toLowerCase().contains(filter.toLowerCase())) {
      return true;
    }
    return false;
  }

  get uri {
    return _buildUri(type: type, labelIssuer: labelIssuer, accountName: accountName, secret: secret, issuer: issuer, algo: algo, digits: digits, period: period, counter: counter);
  }

  _updateStoredUri() {
    debugPrint('update the uri in the database, new uri: $uri');
  }
}

String _buildUri({@required Type type, labelIssuer = '', @required String accountName, @required String secret, @required String issuer, algo = Algorithm.sha1, digits = 6, period = 30, int counter}) {
  String sAlgo = 'SHA1';
  if (algo == Algorithm.sha256) sAlgo = 'SHA256';
  if (algo == Algorithm.sha512) sAlgo = 'SHA512';
  String sDigits = digits.toString();
  String sPeriod = period.toString();
  String sCounter = counter.toString();
  String sIssuer = Uri.encodeComponent(issuer);
  if (labelIssuer == '') labelIssuer = sIssuer;
  String label = '$labelIssuer:$accountName';
  if (type == Type.totp) {
    return 'otpauth://totp/$label?secret=$secret&issuer=$sIssuer&digits=$sDigits&algorithm=$sAlgo&period=$sPeriod';
  }
  return 'otpauth://hotp/$label?secret=$secret&issuer=$sIssuer&digits=$sDigits&algorithm=$sAlgo&counter=$sCounter';
}

// https://tools.ietf.org/html/rfc4226#section-5.3
String _code(String secret, int counter, {digits = 6, algo = Algorithm.sha1}) {
  if (digits < 6) {
    throw Exception('length must be at least 6');
  }

  // step 1: generate 20-byte HMAC-SHA-1 called HS 
  Uint8List k = base32.decode(secret);

  Hmac hmac = Hmac(sha1, k);
  if (algo != Algorithm.sha1) {
    switch (algo) {
      case Algorithm.sha256:
        hmac = Hmac(sha256, k);
        break;
      case Algorithm.sha512:
        hmac = Hmac(sha512, k);
        break;
    }
  }
  Uint8List c = Uint8List(8)..buffer.asUint8List()[0] = counter;

  var hs = hmac.convert(c).bytes;
  assert(hs.length == 20);

  // step 2: generate 4-byte dynamic truncation
  //    let offsetbits be the lowest 4 bits of the string
  var offset = hs[hs.length - 1] & 0xf;
  var snum = hs[offset] & 0x7f << 24 
    | (hs[offset+1] & 0xff) << 16
    | (hs[offset+2] & 0xff) << 8
    | (hs[offset+3] & 0xff); 
  // step 3: compute the htop value
  int d = snum % pow(10, digits);

  return d.toString().padLeft(digits, '0');
}
