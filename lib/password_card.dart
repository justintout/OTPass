import 'package:flutter/material.dart';

class PasswordCard extends StatefulWidget {
  PasswordCard({Key key}) : super(key: key);

  @override
  _PasswordCardState createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
       child: Card(
         child: Column(
           children: <Widget>[
            Text('GitHut Account'),
            Text('justintout'),
            Text('**************'),
           ]
         )
       ),
    );
  }
}