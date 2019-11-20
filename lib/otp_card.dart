import 'package:flutter/material.dart';
import 'otp.dart';

class TotpCard extends OtpCard {
  TotpCard(otp, {Key key}) : super(otp, key: key);

  @override
  _TotpCardState createState() => _TotpCardState();
}

class _TotpCardState extends _OtpCardState with SingleTickerProviderStateMixin  {
  // animation for progress indicator
  AnimationController _controller;
  Animation _animation;
  var _animationControllerStatusListener;
  var _animationListener; 

  @override 
  void initState() {
    super.initState();
    _otp = widget.otp;
    debugPrint('building card from uri: ${_otp.uri}');
    _label = '${_otp.issuer} (${_otp.accountName})';
    _code = _styleCode(_otp.code.value);

    // replace the code listener already attached by super
    _otp.code.removeListener(super._codeListener);
    _codeListener = () {
      if (!this.mounted) {
        return;
      }
      setState((){
        _code = _styleCode(_otp.code.value);
        if (!_controller.isDismissed) {
          _controller.duration = Duration(seconds: _otp.currentCodeLife.value);
          _controller.reset();
          _controller.forward();
          _animation = Tween(begin: (_otp.currentCodeLife.value / _otp.period), end: 0.0).animate(_controller);
            // ..addListener(_animationListener);
        }
      });
    };
    _otp.code.addListener(_codeListener);

    _animationControllerStatusListener  = (AnimationStatus status) {
      // if (status == AnimationStatus.dismissed) {
      //   _controller.removeStatusListener(_animationControllerStatusListener);
      // }
    };
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _otp.currentCodeLife.value),
    );
    _controller.addStatusListener(_animationControllerStatusListener);
    _animationListener = () {
      if (!this.mounted) {
        return;
      }
      setState((){
      });
    };
    _animation = Tween(begin: _otp.currentCodeLife.value / _otp.period, end: 0.0).animate(_controller)
      ..addListener(_animationListener);
    _controller.forward();
  }

  @override
  void dispose() {
    _otp.code.removeListener(_codeListener);
    _animation.removeListener(_animationListener);
    _controller.removeStatusListener(_animationControllerStatusListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Card(
        elevation: 2.0,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                child: Column(
                  children: <Widget>[
                    Text(_code, style: TextStyle(fontSize: 30.0),),
                    Text(_label),
                  ],
                )
              ),
              CircularProgressIndicator(
                value: _animation.value,
                valueColor: ColorTween(begin: Colors.grey, end: Colors.amber).animate(_animation),
              )
            ],
          )
        )
      )
    );
  }
}

class HotpCard extends OtpCard {
  HotpCard(otp, {Key key}) : super(otp, key: key);

  @override
  _HotpCardState createState() => _HotpCardState();
}

class _HotpCardState extends _OtpCardState {
  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Card(
        elevation: 2.0,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                child: Column(
                  children: <Widget>[
                    Text(_code, style: TextStyle(fontSize: 30.0),),
                    Text(_label),
                  ],
                )
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  _otp.requestCode();
                },
                iconSize: 30.0,
                color: Colors.amber,
              )
            ],
          )
        )
      )
    );
  }
}


class OtpCard extends StatefulWidget {
  OtpCard(this.otp, {Key key}) : super(key: key);

  Otp otp;

  @override
  _OtpCardState createState() => _OtpCardState();
}

class _OtpCardState extends State<OtpCard> {
  Otp _otp;

  String _code; 
  String _label = '';

  var _codeListener;

  String _styleCode(String code) {
    return code.splitMapJoin(new RegExp(r'.{3}'), 
      onMatch: (m) => '${m.group(0)} ',
      onNonMatch: (m) => m
    );
  }

  @override 
  void initState() {
    super.initState();
    _otp = widget.otp;
    _label = '${_otp.issuer} (${_otp.accountName})';
    _code = _styleCode(_otp.code.value);
    _codeListener = () {
      setState((){
        _code = _styleCode(_otp.code.value);
      });
    };
    _otp.code.addListener(_codeListener);
  }

  @override
  void dispose() {
    _otp.code.removeListener(_codeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Card(
        elevation: 2.0,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                child: Column(
                  children: <Widget>[
                    Text(_code, style: TextStyle(fontSize: 30.0),),
                    Text(_label),
                  ],
                )
              ),
            ],
          )
        )
      )
    );
  }
}