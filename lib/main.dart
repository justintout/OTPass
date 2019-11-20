import 'package:flutter/material.dart';
import 'otp.dart';
import 'otp_screen.dart';
import 'password_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTPass',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark
      ),
      routes: {
        '/': (context) =>  OtpPage(),
        '/otps': (context) => OtpPage(),
        '/passwords': (context) => PasswordPage(),
      },
    );
  }
}

class OtpProvider {
  static final OtpProvider _otpProvider = OtpProvider._();

  factory OtpProvider() {
    return _otpProvider;
  }

  OtpProvider._() {
    for (String u in uris) {
      _otps.add(Otp.fromUri(u));
    }
  }

  List<Otp> _otps = <Otp>[];
  List<String> uris = [
    'otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example',
    'otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=8&period=5',
    'otpauth://hotp/Somewhere%20Weird:asdf@fdsa.com?secret=JBSWY3DPEHPK3PXP&issuer=Somewhere%20Weird'
  ];

  int get otpCount {
    return this._otps.length;
  }

  List<Otp> all({filter = ''}) {
    List<Otp> out = <Otp>[];
    for (Otp o in _otps)
    if (o.match(filter)) {
      out.add(o);
    }
    return out;
  }

  List<String> allUris({filter = ''}) {
    List<String> uris = <String>[];
    for (String u in this.uris) {
      if (filter != '' && !u.contains(filter)) {
        continue;
      }
      uris.add(u);
    }
    return uris;
  }
}