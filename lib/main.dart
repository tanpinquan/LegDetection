import 'dart:convert';
import 'dart:math';

import 'package:augmented_reality_plugin_wikitude/startupConfiguration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wikitude_flutter_app/arm_tracking_view.dart';
import 'package:wikitude_flutter_app/plotView.dart';
//import 'package:wikitude_flutter_app/customUrl.dart';

import 'arview.dart';
import 'category.dart';
import 'custom_expansion_tile.dart';
import 'sample.dart';

import 'package:augmented_reality_plugin_wikitude/wikitude_plugin.dart';
import 'package:augmented_reality_plugin_wikitude/wikitude_sdk_build_information.dart';
import 'package:augmented_reality_plugin_wikitude/wikitude_response.dart';

import 'package:path_provider/path_provider.dart';
//import 'package:path/path.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

void main() => runApp(MyApp());

Future<String> _loadSamplesJson() async{
  return await rootBundle.loadString('samples/samples.json');
}

Future _loadSamples() async{
  String samplesJson =  await _loadSamplesJson();
  print(samplesJson);
  List<dynamic> categoriesFromJson = json.decode(samplesJson);
  List<Category> categories = new List();

  for(int i = 0; i < categoriesFromJson.length; i++) {
    categories.add(new Category.fromJson(categoriesFromJson[i]));
  }
  return categories;
}

//Future _loadJSInfo() async{
//  print('load');
//  String samplesJson =  await rootBundle.loadString('samples/js_info.json');
//  print(samplesJson);
//  Map<String, dynamic> infoFromJson = json.decode(samplesJson);
////  print(infoFromJson);
//  Sample sample = Sample.fromJson(infoFromJson);
//  print(sample.name);
//
//
//  return sample;
//}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Color(0xffffb300)
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
//        primaryColor: Color(0xffffb300),
//        primaryColorDark: Color(0xfffb8c00),
//        accentColor: Color(0xffffb300)
      ),
      home: MainMenu()
    );
  }
}

class MainMenu extends StatefulWidget {
  @override
  MyAppState createState() => new MyAppState();
}



class MyAppState extends State<MainMenu> {
  Sample arConfig = Sample(
      name: 'Track Leg',
      requiredExtensions: ["data_transfer"],
      requiredFeatures: ["image_tracking"],
      path: "01_ImageTracking_2_DifferentTargets/index.html",
      startupConfiguration: StartupConfiguration(
        cameraPosition: CameraPosition.FRONT,
        cameraResolution: CameraResolution.FULL_HD_1920x1080,
        cameraFocusMode: CameraFocusMode.CONTINUOUS
      )


  );
  List<FileSystemEntity> files = new List();
  List<String> stringList = [];

  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = "";
  String lastError = "";
  String lastStatus = "";
  String _currentLocaleId = "";
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();


  @override
  void initState() {
    super.initState();
    getFiles();
    initSpeechState();

  }


  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  void getFiles()async{
    final directory = (await getApplicationDocumentsDirectory()).path;
    print(directory);

    files = Directory("$directory").listSync();  //use your folder name insted of resume.

    files.sort((a, b) => a.path.compareTo(b.path));

    print(files);


//    print(path.basename(files[0].path));
    print('init');

    setState(() {

    });
  }

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale.localeId;
    }

    if (!mounted) return;
    print(_currentLocaleId);
    setState(() {
      _hasSpeech = hasSpeech;
    });
    startListening();

  }


  Widget _buildSpeechDisplay(){
    if(speech.isNotListening){
      return Container(
          width: double.infinity,
          height: 50,
          child: RaisedButton(
            color: Colors.green,
            child: Text('Enable voice control',style: Theme.of(context).textTheme.headline6,),
            onPressed: startListening,
          )
      );

    }


    String string;

    if(speech.isNotListening){
      string = 'Voice Recognition Disabled';
    }
    else if(stringList.isEmpty){
      string = 'Say something...';
    }else if(stringList.length<3){
      string = stringList.last.toLowerCase();
    }else{
      string = stringList.sublist(stringList.length-3).join(" ");
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 0),
      color: Colors.grey,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
            RaisedButton(
              color: Colors.red,
              child: Text('Stop Listening'),
              onPressed: cancelListening,
            ),
            Expanded(child: Center(child: Text(string, style: Theme.of(context).textTheme.headline6,))),

        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    List<Widget> widgetList = [];

    widgetList.addAll([
      ListTile(
          title: Text('Right Knee Flexion'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: (){
            _pushArView(arConfig, true);
          }
      ),
      ListTile(
          title: Text('Left Knee Flexion'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: (){
            _pushArView(arConfig, false);
          }
      ),
      ListTile(
          title: Text('Right Shoulder Flexion'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: (){
            _pushArmTrackingView(arConfig, true);
          }
      ),
      ListTile(
          title: Text('Left Shoulder Flexion'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: (){
            _pushArmTrackingView(arConfig, false);
          }
      ),
      Divider(height: 0,),
      Container(height: 50,),
      ListTile(
        title: Text('View Past Exercise Data', style: Theme.of(context).textTheme.subtitle2,),
        dense: true,
      ),
      Divider(height: 0,),
    ]);
    
    files.forEach((file) {
      String fileName = path.basename(file.path);
      widgetList.add(
          ListTile(
            title: Text(fileName),
            onTap: (){
              cancelListening();

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlotView(fileName:fileName)),
              ).then((value){
                getFiles();
//                startListening();
              });;
            },
          )
      );
    });
    
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Tacking'),
      ),
      body: ListView(
        children: widgetList
      ),
      bottomNavigationBar: _buildSpeechDisplay()


    );
  }





  Future<WikitudeResponse> _isDeviceSupporting(List<String> features) async {
    return await WikitudePlugin.isDeviceSupporting(features);
  }

  Future<WikitudeResponse> _requestARPermissions(List<String> features) async {
    return await WikitudePlugin.requestARPermissions(features);
  }

  Future<void> _pushArView(Sample sample, bool rightLeg) async {
    WikitudeResponse supportedResponse = await _isDeviceSupporting(sample.requiredFeatures);

    if(supportedResponse.success) {
      WikitudeResponse permissionsResponse = await _requestARPermissions(
          sample.requiredFeatures);
      if (permissionsResponse.success) {
        cancelListening();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ArViewWidget(sample: sample, rightLeg: rightLeg,)),
        ).then((value){
          getFiles();
          startListening();
        });
      } else {
        _showPermissionError(permissionsResponse.message);
      }
    }else{
      _showNotSupportedError(supportedResponse.message);
    }
  }

  Future<void> _pushArmTrackingView(Sample sample, bool rightSide) async {
    WikitudeResponse supportedResponse = await _isDeviceSupporting(sample.requiredFeatures);

    if(supportedResponse.success) {
      WikitudeResponse permissionsResponse = await _requestARPermissions(
          sample.requiredFeatures);
      if (permissionsResponse.success) {
        cancelListening();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ArmTrackingViewWidget(sample: sample, rightSide: rightSide,)),
        ).then((value){
          getFiles();
          startListening();
        });
      } else {
        _showPermissionError(permissionsResponse.message);
      }
    }else{
      _showNotSupportedError(supportedResponse.message);
    }
  }


  void _showPermissionError(String message) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Permissions required"),
            content: Text(message),
            actions: <Widget>[
              FlatButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: const Text('Open settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  WikitudePlugin.openAppSettings();
                },
              )
            ],
          );
        }
    );
  }


  void _showNotSupportedError(String message) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Device not supported"),
            content: Text(message),
            actions: <Widget>[
              FlatButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),

            ],
          );
        }
    );
  }



  void startListening() {
    lastWords = "";
    lastError = "";
    stringList = [];
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 60),
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        partialResults: true);
    print('listening');
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = "${result.recognizedWords} - ${result.finalResult}";
    });
    stringList = result.recognizedWords.split(' ');


    print(stringList);
//    print(result.alternates);
    if(stringList.length>1){
      if(stringList[stringList.length-3].toLowerCase().contains('right') && stringList[stringList.length-2].toLowerCase().contains('knee') && stringList.last.contains('flexion')){
        _pushArView(arConfig, true);
      }else if(stringList[stringList.length-3].toLowerCase().contains('left') && stringList[stringList.length-2].toLowerCase().contains('knee') && stringList.last.contains('flexion')){
        _pushArView(arConfig, false);
      }else if(stringList[stringList.length-3].toLowerCase().contains('right') && stringList[stringList.length-2].toLowerCase().contains('shoulder') && stringList.last.contains('flexion')){
        _pushArmTrackingView(arConfig, true);

      }
    }

//    if(stringList.last.toLowerCase().contains('knee')){
//      _pushArView(arConfig);
//    }else if(stringList.last.toLowerCase().contains('shoulder')){
//      _pushArmTrackingView(arConfig);
//    }

  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    //print("sound level $level: $minSoundLevel - $maxSoundLevel ");
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    print("Received error status: $error, listening: ${speech.isListening}");
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  void statusListener(String status) {
    print(
        "Received listener status: $status, listening: ${speech.isListening}");
    setState(() {
      lastStatus = "$status";
    });
  }
}

