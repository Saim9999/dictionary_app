import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  final List<String> favorites;
  final Function(String) onDelete;

  FavoritesScreen(this.favorites, this.onDelete);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    _preferences = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: Text('Favorite Words'),
      ),
      body: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.favorites.length,
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: Text(widget.favorites[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      widget.onDelete(widget.favorites[index]);
                      Get.back();
                    },
                  ),
                ),
                Divider(),
              ],
            ),
          );
        },
      ),
    );
  }
}
