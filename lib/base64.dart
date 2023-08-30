import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  final imageSrc = 'https://picsum.photos/250?image=9';
  var downloadPath = '';
  var downloadProgress = 0.0;
  Uint8List _imageBytesDecoded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                flex: 5,
                child: Row(children: [
                  // Display image from network
                  Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Text('Image from Network'),
                          Image.network(imageSrc),
                        ],
                      )),
                  Expanded(
                    flex: 1,
                    child: Container(
                      child: Column(
                        children: [
                          Text('Image from File storage'),
                          downloadPath == ''
                              // Display a different image while downloadPath is empty
                              // downloadPath will contain an image file path on successful image download
                              ? Icon(Icons.image)
                              : Image.file(File(downloadPath)),
                        ],
                      ),
                    ),
                  ),
                ])),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  ElevatedButton(
                    // Download displayed image from imageSrc
                    onPressed: () {
                      downloadFile().catchError((onError) {
                        debugPrint('Error downloading: $onError');
                      }).then((imagePath) {
                        debugPrint('Download successful, path: $imagePath');
                        displayDownloadImage(imagePath);
                        // convert downloaded image file to memory and then base64
                        // to simulate the base64 downloaded from the database
                        base64encode(imagePath);
                      });
                    },
                    child: Text('Download'),
                  ),
                  ElevatedButton(
                    // Delete downloaded image
                    onPressed: () {
                      deleteFile().catchError((onError) {
                        debugPrint('Error deleting: $onError');
                      }).then((value) {
                        debugPrint('Delete successful');
                      });
                    },
                    child: Text('Clear'),
                  )
                ],
              ),
            ),
            LinearProgressIndicator(
              value: downloadProgress,
            ),
            Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Text('Image from base64'),
                    Center(
                      child: _imageBytesDecoded != null
                          ? Image.memory(_imageBytesDecoded)
                          // Display a temporary image while _imageBytesDecoded is null
                          : Icon(Icons.image),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  displayDownloadImage(String path) {
    setState(() {
      downloadPath = path;
    });
  }

  // Convert downloaded image file to memory and then base64
  // to simulate the base64 downloaded from the database
  base64encode(String imagePath) async {
    var imageBytes = File(imagePath).readAsBytesSync();
    debugPrint('imageBytes: $imageBytes');
    // This simulates the base64 downloaded from the database
    var encodedImage = base64.encode(imageBytes);
    debugPrint('base64: $encodedImage');
    setState(() {
      _imageBytesDecoded = base64.decode(encodedImage);
      debugPrint('imageBytes: $_imageBytesDecoded');
    });
  }

  Future deleteFile() async {
    final dir = await getApplicationDocumentsDirectory();
    var file = File('${dir.path}/image.jpg');
    await file.delete();
    setState(() {
      // Clear downloadPath and _imageBytesDecoded on file deletion
      downloadPath = '';
      _imageBytesDecoded = null;
    });
  }

  Future downloadFile() async {
    Dio dio = Dio();
    var dir = await getApplicationDocumentsDirectory();
    var imageDownloadPath = '${dir.path}/image.jpg';
    await dio.download(imageSrc, imageDownloadPath,
        onReceiveProgress: (received, total) {
      var progress = (received / total) * 100;
      debugPrint('Rec: $received , Total: $total, $progress%');
      setState(() {
        downloadProgress = received.toDouble() / total.toDouble();
      });
    });
    // downloadFile function returns path where image has been downloaded
    return imageDownloadPath;
  }
}
