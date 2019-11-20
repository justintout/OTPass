import 'package:flutter/material.dart';
import 'fabbottombar.dart';
import 'password_card.dart';

class PasswordPage extends StatefulWidget {
  PasswordPage({Key key}) : super(key: key);
  final String title = 'Passwords';
  @override
  _PasswordPageState createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {

  List<Widget> _buildPasswordCards() {
    return <PasswordCard>[
      PasswordCard()
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add a new password',
        child: Icon(Icons.add),
        elevation: 2.0,
      ),
      bottomNavigationBar: FABBottomNavigationBar(context, 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildPasswordCards()
        )
      )
    );
  }
}