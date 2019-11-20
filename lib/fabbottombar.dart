import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FABBottomNavigationBarItem {
  FABBottomNavigationBarItem({this.iconData, this.text});
  IconData iconData;
  String text;
}

class FABBottomNavigationBar extends StatefulWidget {
  FABBottomNavigationBar(this.context, this.pageIndex);
  BuildContext context;
  int pageIndex;

  final List<FABBottomNavigationBarItem> items = <FABBottomNavigationBarItem>[
    FABBottomNavigationBarItem(iconData: Icons.timelapse, text: 'OTPs'),
    FABBottomNavigationBarItem(iconData: Icons.security, text: 'Passwords'),
  ];

  @override
  State<StatefulWidget> createState() => FABBottomNavigationBarState();
}

class FABBottomNavigationBarState extends State<FABBottomNavigationBar> {
  
  _updateIndex(int index) {
    if (index == widget.pageIndex) {
      debugPrint('same index, returning');
      return;
    }
    if (index == 0) {
      debugPrint('push to otps');
      Navigator.pushNamedAndRemoveUntil(this.context, '/otps',(Route<dynamic> route) => false);
    }
    if (index == 1) {
      debugPrint('push to passwords');
      Navigator.pushNamedAndRemoveUntil(this.context, '/passwords',(Route<dynamic> route) => false);
    }
    setState(() {
    });
  }

  Widget _buildTabItem({
    FABBottomNavigationBarItem item,
    int index,
    ValueChanged<int> onPressed,
  }) {
    Color color = widget.pageIndex == index ? Colors.amber: Colors.grey[600];
    return Expanded(
      child: SizedBox(
        height: 60.0,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => onPressed(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(item.iconData, color: color, size: 30.0),
                Text(item.text, style: TextStyle(color: color))
              ],
            )
          )
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = List.generate(widget.items.length, (int index) {
      return _buildTabItem(
        item: widget.items[index],
        index: index,
        onPressed: _updateIndex,
      );
    });
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items,
      )
    );
  }
}