import 'dart:math';
import 'package:base32/base32.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/fabbottombar.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/otp_card.dart';

import 'otp.dart';

_buildOtpCards(otps, {filter = ''}) {
  List<OtpCard> cards = <OtpCard>[];
  for (Otp otp in otps) {
    if (otp.uri.contains(filter)) {
      switch (otp.type) {
        case Type.hotp:
          cards.add(HotpCard(otp));
          break;
        case Type.totp:
          cards.add(TotpCard(otp));
          break;
      }
    }
  }
  return cards;
}

class OtpPage extends StatefulWidget {
  OtpPage({Key key}) : super(key: key);
  final String title = "OTPs";

  OtpProvider provider = new OtpProvider();
  
  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with SingleTickerProviderStateMixin {
  _OtpPageState() {
    _filter.addListener(() {
      debugPrint('filter: ${_filter.text}');
      setState((){});
    });
  }
  final TextEditingController _filter = TextEditingController();

  AppBar _appBar;
  AnimationController _fabController;

  void _toggleSearchInput(bool show) {
    if (show) {
      setState(() {
        _appBar = AppBar(
          title: TextField(
            autofocus: true,
            controller: _filter,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search OTPs...'
            )
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'Close search',
              icon: const Icon(Icons.clear),
              onPressed: () {
                _toggleSearchInput(false);
              }
            )
          ],
        );
      });
      return;
    }
    setState(() {
      _filter.clear();
      _appBar = AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () {
              // showSearchPage(context, _searchDelegate);
              _toggleSearchInput(true);
            },
          )
        ],
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _appBar = AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () {
              _toggleSearchInput(true);
            },
          )
        ],
      );
      _fabController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500)
      );
    // _searchDelegate = _OtpSearchDelegate(<String>['asdf', 'fdsa'], widget.provider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Container(
                height: 180.0,
                child: Center(
                  child: Column(
                    children: <Widget>[
                      RaisedButton.icon(
                        color: Colors.teal,
                        icon: Icon(Icons.edit),
                        label: Text('Enter a provided key'),
                        onPressed: (){
                          showDialog(
                            context: context,
                            builder: (context) => AddFromDetails(context)
                          ).then((value) {
                            debugPrint('modal close value: $value');
                            Navigator.pop(context);
                          });
                        }
                      ),
                      RaisedButton.icon(
                        color: Colors.teal,
                        icon: Icon(Icons.photo_camera),
                        label: Text('Scan a QR code'),
                        onPressed: (){
                          showDialog(
                            context: context,
                            builder: (context) => AddFromBarcode(context)
                          ).then((value){
                            Navigator.pop(context);
                          });
                        },
                      ),
                      RaisedButton.icon(
                        color: Colors.teal,
                        icon: Icon(Icons.link),
                        label: Text('Enter a specific URI'),
                        onPressed: (){
                          showDialog(
                            context: context,
                            builder: (context) => AddFromUri(context)
                          ).then((value) {
                            debugPrint('modal close value: $value');
                            Navigator.pop(context);
                          });
                        }
                      ),
                      
                    ],
                  )
                ),
              );
            }
          );
        },
        tooltip: 'Add a new OTP provider',
        child: Icon(Icons.add),
        elevation: 2.0,
      ),
      bottomNavigationBar: FABBottomNavigationBar(context, 0),
      body: Center(
        child: ListView(
          children: _buildOtpCards(widget.provider.all(filter: _filter.text))
        )
      ),
    );
  }
}

class AddFromUri extends StatefulWidget {
  AddFromUri(this.context, {Key key}) : super(key: key);
  BuildContext context;
  @override
  _AddFromUriState createState() => _AddFromUriState();
}

class _AddFromUriState extends State<AddFromUri> {
  final _formKey = GlobalKey<FormState>();

  String _issuer = 'SOMEONE IDK';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to code list',
          icon: Icon(Icons.arrow_back),
          onPressed: () { 
            Navigator.pop(context);
          },
        ),
        title: Text('Add new OTP from URI'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            tooltip: 'More information',
            onPressed: () {
              debugPrint('pop help page for uri form');
            }
          )
        ],
      ),
      body: Builder(
          builder: (context) => Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'otpauth://totp/justintout.com:justin?secret=ASDFFDSA1234&issuer=justintout.com',
                    labelText: 'OTP URI',
                    icon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    if (value.isEmpty) return 'Enter the URI here';
                    Uri u;
                    try {
                      u = Uri.parse(value);
                      if (u.scheme != 'otpauth') return 'Only otpauth:// scheme is supported';
                      if (u.path == '') return 'URI missing label after otpauth://type/';
                      if (u.host != 'totp' && u.host != 'hotp') return '\'${u.host}\' is not a supported OTP type';
                      if (u.queryParameters['secret'] == null) return 'The \'secret\' parameter is missing';
                      if (u.queryParameters['issuer'] == null || !u.host.contains(':')) return 'The \'issuer\' parameter is missing';
                    } catch (e) {
                      return 'Check the otpauth:// URI format';
                    }
                    return null;
                  },
                ),
                RaisedButton(
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      Scaffold.of(context).showSnackBar(SnackBar(content: Text('saved new key for $_issuer')));
                    }
                  },
                  child: Text('Add'),
                )
              ],
            ),
          ),
      ),
    );
  }
}

class AddFromDetails extends StatefulWidget {
  AddFromDetails(this.context, {Key key}) : super(key: key);
  BuildContext context;
  @override
  _AddFromDetailsState createState() => _AddFromDetailsState();
}

class _AddFromDetailsState extends State<AddFromDetails> {
  final _formKey = GlobalKey<FormState>();

  String _issuer = 'SOMEONE IDK';
  Type _selectedType = Type.totp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to code list',
          icon: Icon(Icons.arrow_back),
          onPressed: () { 
            Navigator.pop(context);
          },
        ),
        title: Text('Add account details'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            tooltip: 'More information',
            onPressed: () {
              debugPrint('pop help page for detail form');
            }
          )
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(20.0),
        child: Builder(
            builder: (context) => Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Account name',
                    ),
                    validator: (value) {
                      if (value.isEmpty) return 'Enter this account name';
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Issuer'
                    ),
                    validator: (value) {
                      if (value.isEmpty) return 'Enter this account issuer';
                      return null;
                    }
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        DropdownButton(
                          elevation: 2,
                          items: <DropdownMenuItem>[
                            DropdownMenuItem(
                              child: Text('Time based (TOTP)'),
                              value: Type.totp
                            ),
                            DropdownMenuItem(
                              child: Text('Counter based (HOTP)'),
                              value: Type.hotp,
                            )
                          ],
                          value: _selectedType,
                          onChanged: (value) {
                            debugPrint('selected type: $value');
                            setState((){
                            _selectedType = value;
                            });
                          },
                        ),
                        RaisedButton(
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              
                              Scaffold.of(context).showSnackBar(SnackBar(content: Text('saved new key for $_issuer')));
                            }
                          },
                          child: Text('Add'),
                        )
                      ]
                    ),
                  )
                ],
              ),
            ),
        ),
      ),
    );
  }
}

class AddFromBarcode extends StatefulWidget {
  AddFromBarcode(this.context, {Key key}) : super(key: key);
  BuildContext context;
  @override
  _AddFromBarcodeState createState() => _AddFromBarcodeState();
}

class _AddFromBarcodeState extends State<AddFromBarcode> {

  String _barcode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
         leading: IconButton(
          tooltip: 'Back to code list',
          icon: Icon(Icons.arrow_back),
          onPressed: () { 
            Navigator.pop(context);
          },
        ),
        title: Text('Scan barcode'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            tooltip: 'More information',
            onPressed: () {
              debugPrint('pop help page for barcode form');
            }
          )
        ],
       ),
       body: Container(
         child: Center(
           child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6.0),
                child: new MaterialButton(
                  onPressed: scan,
                  child: Text("Scan"),
                ),
              ),
              Text(_barcode)
            ],
           ),
         )
       ) 
    );
  }
  scan() {
    debugPrint('scannn me daddy');
    return 'asdf1234';
  }
  // Future scan() async {
  // try {
  //     String barcode = await BarcodeScanner.scan();
  //     setState(() => this._barcode = barcode);
  //   } on PlatformException catch (e) {
  //     if (e.code == BarcodeScanner.CameraAccessDenied) {
  //       setState(() {
  //         this._barcode = 'The user did not grant the camera permission!';
  //       });
  //     } else {
  //       setState(() => this._barcode = 'Unknown error: $e');
  //     }
  //   } on FormatException{
  //     setState(() => this._barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
  //   } catch (e) {
  //     setState(() => this._barcode = 'Unknown error: $e');
  //   }
  // }
}


