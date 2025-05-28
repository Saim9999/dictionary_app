import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

import 'favourate_screen.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  String _searchTerm = '';
  List<String> _meanings = [];
  String _translation = '';
  final Set<String> _favorites = {};
  FlutterTts flutterTts = FlutterTts();
  late SharedPreferences _preferences;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    final favorites = _preferences.getStringList('favorites') ?? [];
    setState(() {
      _favorites.addAll(favorites);
    });
  }

  void _speakWord(String word) {
    flutterTts.speak(word);
  }

  // void addToFavorites(String item) {
  //   if (!_favorites.contains(item)) {
  //     setState(() {
  //       _favorites.add(item);
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Added to favorites'),
  //       ),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('$item is already in favorites'),
  //       ),
  //     );
  //   }
  // }

  // void removeFromFavorites(String item) {
  //   setState(() {
  //     _favorites.remove(item);
  //   });
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Removed from favorites'),
  //     ),
  //   );
  // }

  void addToFavorites(String item) {
    if (!_favorites.contains(item)) {
      setState(() {
        _favorites.add(item);
      });
      _preferences.setStringList('favorites', _favorites.toList());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to favorites'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$item is already in favorites'),
        ),
      );
    }
  }

  void removeFromFavorites(String item) {
    setState(() {
      _favorites.remove(item);
    });
    _preferences.setStringList('favorites', _favorites.toList());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed from favorites'),
      ),
    );
  }

  void removeFromFavoritesScreen(String item) {
    setState(() {
      _favorites.remove(item);
    });
  }

  bool isFavorite(String item) {
    return _favorites.contains(item);
  }

  void navigateToFavoritesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesScreen(
          _favorites.toList(),
          removeFromFavoritesScreen,
        ),
      ),
    );
  }

  Future<void> _fetchDefinition(String term) async {
    final response = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en_US/$term'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        final meanings = data[0]['meanings'];
        List<String> meaningsList = [];
        for (var meaning in meanings) {
          final partOfSpeech = meaning['partOfSpeech'];
          final definition = meaning['definitions'][0]['definition'];
          meaningsList.add('$partOfSpeech: $definition');
        }
        setState(() {
          _meanings = meaningsList;
          _translation = '';
          _isLoading = true;
        });
        _translateToUrdu(term);
      } else {
        Fluttertoast.showToast(
          msg: 'Definition not found',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to fetch definition',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _translateToUrdu(String text) async {
    try {
      final translator = GoogleTranslator();

      final translation = await translator.translate(
        text,
        from: 'en',
        to: 'ur',
      );

      setState(() {
        _translation = translation.toString();
      });
    } catch (e) {
      setState(() {
        _translation = 'Failed to translate';
      });
    }
  }

  // Function to check internet connectivity
  Future<bool> checkInternetConnectivity() async {
    return await InternetConnectionChecker().hasConnection;
  }

// Function to display the "No Internet" dialog box
  void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Internet!'),
          content: Text('Please connect to your internet.'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 215, 139, 25)),
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _meanings.toString())).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('URL copied to clipboard'),
      ));
    });
  }

  Future<void> _sharedefinition() async {
    if (_meanings.isNotEmpty) {
      Share.share(_meanings.toString());
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('No QR/BarCode scanned yet.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text("Dictionary"),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: InkWell(
                  onTap: navigateToFavoritesScreen,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
                child: Container(
                  height: 20,
                  child: Center(
                      child: Text(
                    _searchTerm.toUpperCase(),
                    style: TextStyle(fontSize: 18),
                  )),
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(2, 2),
                        )
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20))),
                ),
                preferredSize: Size.fromHeight(20)),
            expandedHeight: 210.h,
            backgroundColor: Colors.orangeAccent,
            elevation: 0,
            pinned: true,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1,
              titlePadding: EdgeInsets.only(bottom: 20, left: 10, right: 15),
              title: Container(
                  height: 130.h,
                  child: Column(
                    children: [
                      TextField(
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(),
                          labelText: 'Enter a word',
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors
                                    .black), // Border color when the field is focused
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchTerm = value;
                          });
                        },
                      ),
                      TextButton(
                        onPressed: () async {
                          bool isConnected = await checkInternetConnectivity();
                          if (isConnected) {
                            setState(() {
                              _isLoading = true;
                            });
                            FocusScope.of(context).unfocus();
                            _fetchDefinition(_searchTerm);
                          } else {
                            showNoInternetDialog(context);
                          }
                        },
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text(
                                'Search',
                                style: TextStyle(color: Colors.black),
                              ),
                      ),
                    ],
                  )),
              centerTitle: false,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Card(
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (_meanings.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _speakWord(_searchTerm);
                              },
                              child: CircleAvatar(
                                  backgroundColor: Colors.orangeAccent,
                                  child: Icon(
                                    Icons.volume_up,
                                    color: Colors.white,
                                  )),
                            ),
                          if (_meanings.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                _searchTerm,
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                          if (_meanings.isNotEmpty)
                            CircleAvatar(
                              backgroundColor: Colors.orangeAccent,
                              child: IconButton(
                                icon: isFavorite(_searchTerm)
                                    ? Icon(
                                        Icons.favorite,
                                        color: Colors.white,
                                      )
                                    : Icon(
                                        Icons.favorite_border,
                                        color: Colors.white,
                                      ),
                                onPressed: () {
                                  if (isFavorite(_searchTerm)) {
                                    removeFromFavorites(_searchTerm);
                                  } else {
                                    addToFavorites(_searchTerm);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                      if (_translation.isNotEmpty)
                        Text(
                          '$_translation',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      SizedBox(height: 10.0),
                    ],
                  ),
                ),
                Card(
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 20.0),
                      if (_meanings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            children: _meanings
                                .map((meaning) => Text(
                                      meaning,
                                      style: TextStyle(fontSize: 18.0),
                                    ))
                                .toList(),
                          ),
                        ),
                      SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_meanings.isNotEmpty)
                            CircleAvatar(
                              backgroundColor: Colors.orangeAccent,
                              child: IconButton(
                                onPressed: _copyUrl,
                                icon: Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (_meanings.isNotEmpty)
                            CircleAvatar(
                              backgroundColor: Colors.orangeAccent,
                              child: IconButton(
                                onPressed: _sharedefinition,
                                icon: Icon(Icons.share, color: Colors.white),
                              ),
                            ),
                          if (_meanings.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _speakWord(_meanings.toString());
                              },
                              onDoubleTap: () {
                                flutterTts.pause();
                              },
                              child: CircleAvatar(
                                  backgroundColor: Colors.orangeAccent,
                                  child: Icon(Icons.volume_up,
                                      color: Colors.white)),
                            ),
                        ],
                      ),
                      SizedBox(height: 10.0),
                    ],
                  ),
                ),
               
              ],
            ),
          ),
        ],
      ),
    );
  }
}
