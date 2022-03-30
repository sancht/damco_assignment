import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cupertino_icons/cupertino_icons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Image Search'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  static const String url = 'https://www.colourlovers.com/api/colors?';

  final TextEditingController _controller = TextEditingController();

  Map colorResults = {};

  Map<String, bool> mapIdToIsLiked = {};

  String lastSearchText = '';

  final ScrollController _scrollController = ScrollController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _read();
    _scrollController.addListener(() {
      if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent && !_loading){
        requestData();
      }
    });
  }

  requestData(){
    setState(() {
      _loading = true;
    });
    http.get(Uri.parse(
        '${url}keywords=${lastSearchText.replaceAll(' ', '+')}&format=json&numResults=20&resultOffset=${(colorResults[lastSearchText] ?? []).length}')).then((http
        .Response res) {
      if (res.statusCode == 200) {
        colorResults[lastSearchText]??=[];
        colorResults[lastSearchText].addAll(jsonDecode(res.body));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.body),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            )
        );
      }
      setState(() {
        _loading = false;
      });
    }, onError: (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong..'),
            duration: Duration(seconds: 2),
          )
      );
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Image Search',
                      hintStyle: TextStyle(
                        color: Colors.grey
                      )
                    ),
                    controller: _controller,
                    maxLength: 10,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                    onPressed: () {
                      if(!_loading) {
                        if (_controller.text.trim().length > 2) {
                          lastSearchText = _controller.text.trim();
                          if (!colorResults.containsKey(lastSearchText)) {
                            requestData();
                          } else {
                            setState(() {});
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Search text Should be at least 3 characters long!'),
                              ));
                        }
                      }
                    },
                    child: const Text('Search')
                ),
              )
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: OrientationBuilder(
                builder: (BuildContext context, Orientation orientation) {
                  return colorResults[_controller.text] != null ? Stack(
                    children: [
                      GridView.count(
                        controller: _scrollController,
                        crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
                        children: List.generate(colorResults[_controller.text].length, (index) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width/(Orientation.portrait == orientation ? 2 : 4),
                            child: Column(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black87),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            '${colorResults[_controller.text][index]['imageUrl']}',
                                          ),
                                          fit: BoxFit.fill
                                        )
                                      ),
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: mapIdToIsLiked[colorResults[_controller.text][index]['id'].toString()] ?? false ? const Icon(CupertinoIcons.heart_solid) : const Icon(
                                            CupertinoIcons.heart
                                          ),
                                        ),
                                      ),
                                    ),
                                    onTap: ()=>() async {
                                      if (!await launch(
                                        colorResults[_controller.text][index]['imageUrl'],
                                        forceSafariVC: false,
                                        forceWebView: false,
                                      )) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch image in browser!')));
                                      }
                                    }(),
                                    onDoubleTap: (){
                                      mapIdToIsLiked[colorResults[_controller.text][index]['id'].toString()] = !(mapIdToIsLiked[colorResults[_controller.text][index]['id'].toString()] ?? false);
                                      setState(() {});
                                      _save(colorResults[_controller.text][index]['id'].toString(), mapIdToIsLiked[colorResults[_controller.text][index]['id'].toString()] ?? false);
                                    },
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black87)
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Column(
                                        children: const [
                                          Text('Title:'),
                                          Text('Hex:'),
                                        ],
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text('${colorResults[_controller.text][index]['title']}'),
                                            Text('${colorResults[_controller.text][index]['hex']}'),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        }),
                      ),
                      if(_loading) Positioned(
                        left: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 80,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    ],
                  ) : Container();
                },
              ),
            ),
          ),
        ],
      )
    );
  }

  late final SharedPreferences prefs;

  _read() async {
    prefs = await SharedPreferences.getInstance();
    prefs.getKeys().forEach((element) {
      mapIdToIsLiked[element] = prefs.getBool(element) ?? false;
    });
  }

  _save(String id, bool value) async {
    prefs.setBool(id, value);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _scrollController.dispose();
  }

}