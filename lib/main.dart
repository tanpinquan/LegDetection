import 'dart:convert';

import 'package:augmented_reality_plugin_wikitude/startupConfiguration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          cameraResolution: CameraResolution.AUTO
      )


  );
  List<FileSystemEntity> files = new List();


  @override
  void initState() {
    super.initState();
    getFiles();

  }

  void getFiles()async{
    final directory = (await getApplicationDocumentsDirectory()).path;
    print(directory);

    files = Directory("$directory").listSync();  //use your folder name insted of resume.
    print(files);

    print(path.basename(files[0].path));
    print('init');

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> widgetList = [];

    widgetList.addAll([
      ListTile(
          title: Text('Track Exercise'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: (){
            _pushArView(arConfig);
          }
      ),
      Divider(height: 0,),
      Container(height: 50,),
      Divider(height: 0,),
    ]);
    
    files.forEach((file) {
      String fileName = path.basename(file.path);
      widgetList.add(
          ListTile(
            title: Text(fileName),
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlotView(fileName:fileName)),
              );
            },
          )
      );
    });
    
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leg Tacking'),
      ),
      body: ListView(
        children: widgetList
      ),


    );
  }





  Future<WikitudeResponse> _isDeviceSupporting(List<String> features) async {
    return await WikitudePlugin.isDeviceSupporting(features);
  }

  Future<WikitudeResponse> _requestARPermissions(List<String> features) async {
    return await WikitudePlugin.requestARPermissions(features);
  }

  Future<void> _pushArView(Sample sample) async {
    WikitudeResponse supportedResponse = await _isDeviceSupporting(sample.requiredFeatures);

    if(supportedResponse.success) {
      WikitudeResponse permissionsResponse = await _requestARPermissions(
          sample.requiredFeatures);
      if (permissionsResponse.success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ArViewWidget(sample: sample)),
        );
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

}

