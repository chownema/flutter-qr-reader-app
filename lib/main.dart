import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

// QR SCANNER application base
// 1.) demonstrate use of QR code scanning [X]
// 2.) added bloc to keep list of scanned strings
// 3.) display list scanned strings
// 4.) add and remove from list of scanned strings

/**
 * IMPLEMENTATION NOTES V1
 * 
 * 2 Views
 * View Camera
 * Selects list to add to as a *drop down below the camera*
 * Has camera feed on top
 * Has dropdown and List check button => onClick goes to list view of items that has been scanned
 * 
 * View List
 * List of Lists
 * on click of list shows a list of the list clicked
 * 
 * Start view list
 * Bottom menu to go to List or Camera
 */

/**
 * IMPLEMENTATION NOTES V2
 * List view can be seen via slide up, like google podcasts
 * 
 * Lists view shows a parent list of lists
 * on click will bring up the slide up view of the jobs
 */
bool isFirstOpen = true;

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR SCANNER',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'QR SCANNER'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SharedPreferences localStorage;

  String _currentScanned = '';
  int _viewIndex = 0;
  
  List<List<String>> cachedList = [];
  List<List<String>> _scanned = [[]];
  var _currentScannedIndex = 0;

  void _addScanned(code) {
    if(_scanned.length > 0 && _scanned[_currentScannedIndex] != null) {
        if (_scanned[_currentScannedIndex].where((scan) => code == scan).length < 1) {
          _scanned[_currentScannedIndex].add(code);
          localStorage.setString('SCANNED_LIST', jsonEncode(_scanned));
        }
    } else {
      _currentScannedIndex = _scanned.length - 1;
      _scanned.add([code]);
      localStorage.setString('SCANNED_LIST', jsonEncode(_scanned));
    }
  }

  void _removeScanned(code) {
    setState(() {
      if(_scanned.length > 0 && _scanned[_currentScannedIndex] != null) {
        _scanned[_currentScannedIndex].removeWhere((scan) => scan == code);
        localStorage.setString('SCANNED_LIST', jsonEncode(_scanned));
      }
    });
  }

  void _onViewSelect(index) {
    setState(() {
      _viewIndex = index;
    });
  }

  void _setCodeScanned(code) {
    setState(() {
    _currentScanned = code;
    });
  }

  @override
  Widget build(BuildContext context) {
  Future<SharedPreferences> sharedPrefFuture = SharedPreferences.getInstance();
  sharedPrefFuture.then((pref) {
    localStorage = pref;

    List<dynamic> jsonScannedList = pref.getString('SCANNED_LIST') != null && pref.getString('SCANNED_LIST').isNotEmpty ? jsonDecode(pref.getString('SCANNED_LIST')) : null;
    cachedList = cast2DListDynamicTo2DListString(jsonScannedList);

    print('Loaded cachedList');
    print(cachedList);
  });

    return FutureBuilder(
      future: sharedPrefFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        print('isFirstOpen');
        print(isFirstOpen);

        print('snapshot.connectionState');
        print(snapshot.connectionState == ConnectionState.done);

        if(isFirstOpen && cachedList != null && cachedList.length > 0 && cachedList[_currentScannedIndex] is List<String>) {
          if (cachedList != null && cachedList.length > 0 && cachedList[_currentScannedIndex] is List<String>) {
            _scanned = [];
            _scanned.addAll(cachedList);
          } else {
            _scanned = [[]];
          }
        }
        if (snapshot.connectionState == ConnectionState.done) {
          isFirstOpen = false;
        }

        print('combinedLists');
        print(_scanned);

        List<String> renderList = _scanned[_currentScannedIndex];

        return Scaffold(
          body: [
            // Detail view

            // List view
            ListView(
              children: 
                getItemWidget(renderList), 
                    // QrImage(
                    //   data: 'Thank you chihiro',
                    //   version: QrVersions.auto,
                    //   size: 320,
                    //   gapless: false,
                    // ),
            ),
            // Camera Scanner
            Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                  new SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 2,
                        child: new QrCamera(
                          onError: (context, error) {
                            var strErr = error.toString();
                            print(strErr);
                          },
                          qrCodeCallback: (code) {
                            _setCodeScanned(code);
                            _addScanned(code);
                          },
                        ),
                ),
                new Text('Current Scanned:' + _currentScanned)
              ],
            ),
          ),
          ][_viewIndex], // Switch View here on reload
              bottomNavigationBar: BottomNavigationBar(
                onTap: _onViewSelect,
                currentIndex: _viewIndex,
                items: [
                  BottomNavigationBarItem(
                    icon: new Icon(Icons.home),
                    title: new Text('Parent List'),
                  ),
                  BottomNavigationBarItem(
                    icon: new Icon(Icons.scanner),
                    title: new Text('Scan')
                  )
                ]
              ),
        );
      });
  }

  List<Widget> getItemWidget(List list) {
    List<Widget> itemList = [];

    list.forEach((item) { 
      itemList.add(new Slidable(
        actionPane: SlidableDrawerActionPane(),
        actionExtentRatio: 0.25,
        child: Container(
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigoAccent,
              child: Text(''),
              foregroundColor: Colors.white,
            ),
            title: Text(item),
            subtitle: Text('Slide for more options'),
            onTap: () => launch(item)
          )
        ),
        actions: <Widget>[
          IconSlideAction(
        caption: 'Archive',
        color: Colors.blue,
        icon: Icons.archive,
      ),
      IconSlideAction(
        caption: 'Share',
        color: Colors.indigo,
        icon: Icons.share,
        onTap: () => Share.share(item),
      ),
    ],
    secondaryActions: <Widget>[
      IconSlideAction(
        caption: 'More',
        color: Colors.black45,
        icon: Icons.more_horiz,
      ),
      IconSlideAction(
        caption: 'Delete',
        color: Colors.red,
        icon: Icons.delete,
        onTap: () => _removeScanned(item)
        ,
      )
      ],
      ));
    });
    return itemList;
  }

  // Helper
  cast2DListDynamicTo2DListString(dynamicList) {
    List<List<String>> newList = [];
    if (dynamicList != null && dynamicList.length > 0) {
      dynamicList.forEach((jsonList) { 
        List<String> convertList = [];
        jsonList.forEach((json) {
          convertList.add(json);
        });

        newList.add(convertList);
      });
    } else {
      newList.add([]);
    }
    return newList;
  }

}