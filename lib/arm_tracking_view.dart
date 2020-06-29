import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:wikitude_flutter_app/model/timeseries.dart';
//import 'applicationModelPois.dart';
//import 'poi.dart';

import 'sample.dart';

import 'package:path_provider/path_provider.dart';

import 'package:augmented_reality_plugin_wikitude/architect_widget.dart';
import 'package:augmented_reality_plugin_wikitude/wikitude_plugin.dart';
import 'package:augmented_reality_plugin_wikitude/wikitude_response.dart';
//import 'package:wikitude_flutter_app/poiDetails.dart';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';


class ArmTrackingViewWidget extends StatefulWidget {

  final Sample sample;

  ArmTrackingViewWidget({
    Key key,
    @required this.sample,
  });

  @override
  ArmTrackingViewState createState() => new ArmTrackingViewState(sample);
}


class ArmTrackingViewState extends State<ArmTrackingViewWidget> with WidgetsBindingObserver {
  ArchitectWidget architectWidget;
  String wikitudeTrialLicenseKey = "rRcPFV/GWHOalFjHX9rP9TWGNRKVu8P4FSKvHtps1mo14SexXUmlVAebLNuKKr9OcOFD89RiMH03AY3eJL09d3Pbvb/V+AVYsQiBROkqqAhYe2lDojp++ZAPDx2RM9rJrD+1qYyUUbdUyKzIJXrU09u4tST9NdhER08njP2tMydTYWx0ZWRfX/p90uj/Yn9x/bcRTK6REaUg/GJT6uUKh7KfnXmxAtt0RI9WNjVPQFFjS1WFGtrRI43/VqyS0gnfsjmiov6fyrE+0aGBxJIzBNWupROE+AYw9LFkJ0gRN6KhsqvawIobvSPbVH+OaYanwnIV8q34LyTRujMzvJL+ke0hEfucf6eChYWe3O5kGCRD09oDnBzBLYnZotRjtuDb2eiHksj28kNuHJTlWItLA4A5Xjri7I1FmnCnTYezZfS2EHHazgOwfYAx+RMTSDXkdjrfradWo4kQFlERljYr1fXTh0T9s19r9FJTeao5/4UbUqcAW8mu71LoIQ5i2gJLDEp4d7xBEBaSznQ2TI4DSNW13lGlTXx8Ma47sFk4uxcxNy1S56RC1bPXA/iJGudxQrGMlhrYuwYcbEpKqEAqRB3xCZKV0M/69hlcZTreu3+1LbtYpLBFQ9GGMPC5FMjzVt29UFSVFyChB6PJlfVrpXbyvlq7ZFKWPc77HKIUyVhx5cSuI19pMxoTPiK5FfcuD7NeUJISK2loWzM/Cd5kvjqCZf0mGJ4zs9iwAQrkhpBGr07lwyAKJ0wH4ybZIdFXb69uZHnp9YnibYF6cuq5L+66lNPRicm1ojF46Sc6SkiVeZDfS6J1f2UOL1ymEMi3eH7pc8+AQ5JUn7XJWr8xIcYTlBa4HkJkRV7ire2Daij3cNywrcVv1GuReHLyW+UipWGPKrvY8IONHmkLEuAgdU9WupbmVdt24Cjn2s1n/ecIIKIVm9xgvdd5n4DHXKsOOWY03gp43g/5jgTJdl1PNwaVIvnwC1zMchAL5Ld49im8pcZbYiQC/MQqAdixxpORPZ0i6j0TM86K7P6DgSxmMNP/SG4vDx0m9mxvCIzvyevNl69Rc2yRToAwY1yGHMHyT2LwWr1NDhhW620ALR/u8gycvRhICYmISCwuCEBuSK+2UyKuKHk50gCr+xfLenxYshOJC+3dyGgBKXMkh/T8i0vKIBaKX5LcD0BY+msO4h/vrb4dMB61qzxCuJM8ax6O5tuQc4u5WOi/6XrAIRFTCqLMST8U6JKN689s70FJtvQYm0DpbPfYTOfeA53B5fphfsTMQqXFwKPhVLczCoWftmlLhHb/NcmNmCHnTp/Mm9yObyNsiG3oQ1Wbb1a9eMOcJ5y/Wvpi0RSYGwIfJcIIknvJIwPphZ3AJ3K9x/M89kct/J65XZMAMdnM1FbtLRpgKUVAUIUJ/E6V03QP/ElUHHukYjbXABWs/fJ/6uy9E4aXjbmzJQ6I9VKQ1uUsT2Oh8585HoXp6LLiFxADdRSIllJBtuMCmgfrd06qQ/q9wu8xFzvJYBeIT6xlCbsBXgdm";
  Sample sample;
  String loadPath = "";
  List<dynamic> upperArmTrackingData = [];
  List<dynamic> lowerArmTrackingData = [];

  String trackedJoint = "";
  String displayStringUpper = "Upper Arm Angle:";
  String displayStringLower = "Lower Arm Angle:";

  List<List<dynamic>> angleList = [];
  List<TimeSeriesAngle> dataListUpper = [];
  List<TimeSeriesAngle> dataListLower = [];

  List<charts.Series<TimeSeriesAngle, double>> seriesList = [];

  DateTime startTime;

  ArmTrackingViewState(Sample sample) {
    this.sample = sample;
    if(sample.path.contains("http://") || sample.path.contains("https://")) {
      loadPath = sample.path;
    } else {
      loadPath = "samples/" + sample.path;
    }
  }

  bool _isRecording = false;

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
    WidgetsBinding.instance.addObserver(this);
    print("init");

    architectWidget = new ArchitectWidget(
      onArchitectWidgetCreated: onArchitectWidgetCreated,
      licenseKey: wikitudeTrialLicenseKey,
      startupConfiguration: sample.startupConfiguration,
      features: sample.requiredFeatures,
    );

    Wakelock.enable();
    initSpeechState();
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
    _hasSpeech = hasSpeech;
    startListening();

  }


  @override
  void dispose() {
    if (this.architectWidget != null) {
      this.architectWidget.pause();
      this.architectWidget.destroy();
    }
    WidgetsBinding.instance.removeObserver(this);

    Wakelock.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (this.architectWidget != null) {
          this.architectWidget.pause();
        }
        break;
      case AppLifecycleState.resumed:
        if (this.architectWidget != null) {
          this.architectWidget.resume();
        }
        break;

      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Arm Exercise Tracking')),
      body: Stack(
        children: <Widget>[
          Container(
              decoration: BoxDecoration(color: Colors.black),
              child: architectWidget
          ),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                      flex: 2,
                      child: _displayText()
                  ),
                  Expanded(
                      flex: 1,
                      child: _buildToggleRecordingButton()
                  ),

                ],
              ),
              _buildChart()
            ],
          ),



        ],
      ),
    );
  }

  Widget _buildChart(){
    return Container(
      color: Colors.white60,
      height: 100,
      child: charts.LineChart(
          seriesList,
          animate: false,
          defaultRenderer: new charts.LineRendererConfig(includePoints: true)

        // Optionally pass in a [DateTimeFactory] used by the chart. The factory
        // should create the same type of [DateTime] as the data provided. If none
        // specified, the default creates local date time.
        //dateTimeFactory: const charts.LocalDateTimeFactory(),
      ),
    );
  }

  Widget _displayText(){
//    if(upperArmTrackingData.isEmpty){
//      return Container();
//    }

    return Container(
        color: Colors.white60,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(displayStringUpper, style: Theme.of(context).textTheme.headline5.copyWith(color: Colors.blue), ),
                Text(displayStringLower, style: Theme.of(context).textTheme.headline5.copyWith(color: Colors.green),),

              ],
            ),
          ],
        )
    );
  }

  Widget _buildToggleRecordingButton(){
    return FlatButton(
        color: _isRecording ? Colors.red : Colors.green,
        textColor: Colors.white,
        child: Text(_isRecording?'Stop Rec':'Start Rec'),
        onPressed: _toggleRecording

    );
  }

  void _toggleRecording()async{

    _isRecording = !_isRecording;

    if(_isRecording){
      print('Recording Start');
    }else {
//            print(angleList);
      print('Recording Stop');
      String fileName = 'Shoulder ' + DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

      String csv = const ListToCsvConverter().convert(angleList);
      final directory = await getApplicationDocumentsDirectory();
      final pathOfTheFileToWrite = '${directory.path}/$fileName.csv';
      File file = File(pathOfTheFileToWrite);
      file.writeAsString(csv);

//      print(csv);

    }
    setState(() {

    });
  }



  void updateDisplayUpper(){

    displayStringUpper = 'Upper Arm Angle:  ${upperArmTrackingData[2]}';

    double timeElapsed;
    if(dataListUpper.isEmpty && dataListLower.isEmpty){
      startTime = DateTime.now();
      timeElapsed = 0;
    }else {
      Duration duration = DateTime.now().difference(startTime);
      timeElapsed = duration.inMilliseconds/1000;
    }
    dataListUpper.add(TimeSeriesAngle(timeElapsed, upperArmTrackingData[2]));

    if(_isRecording){
      angleList.add(upperArmTrackingData);
      angleList.last.insert(0, timeElapsed);
      angleList.last.add(0);

    }

    seriesList = [
      charts.Series<TimeSeriesAngle, double>(
        id: 'Upper',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesAngle angle, _) => angle.time,
        measureFn: (TimeSeriesAngle angle, _) => angle.angle,
        data: dataListUpper,
      ),
      charts.Series<TimeSeriesAngle, double>(
        id: 'Lower',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (TimeSeriesAngle angle, _) => angle.time,
        measureFn: (TimeSeriesAngle angle, _) => angle.angle,
        data: dataListLower,
      )
    ];

    setState(() {

    });
  }

  void updateDisplayLower(){

    displayStringLower = 'Lower Arm Angle:  ${lowerArmTrackingData[2]}';

    double timeElapsed;
    if(dataListUpper.isEmpty && dataListLower.isEmpty){
      startTime = DateTime.now();
      timeElapsed = 0;
    }else {
      Duration duration = DateTime.now().difference(startTime);
      timeElapsed = duration.inMilliseconds/1000;
    }
    dataListLower.add(TimeSeriesAngle(timeElapsed, lowerArmTrackingData[2]));

    if(_isRecording){
      angleList.add(lowerArmTrackingData);
      angleList.last.insert(0, timeElapsed);
      angleList.last.add(1);

    }

    seriesList = [
      charts.Series<TimeSeriesAngle, double>(
        id: 'Upper',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesAngle angle, _) => angle.time,
        measureFn: (TimeSeriesAngle angle, _) => angle.angle,
        data: dataListUpper,
      ),
      charts.Series<TimeSeriesAngle, double>(
        id: 'Lower',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (TimeSeriesAngle angle, _) => angle.time,
        measureFn: (TimeSeriesAngle angle, _) => angle.angle,
        data: dataListLower,
      )
    ];

    setState(() {

    });
  }



  Future<void> onArchitectWidgetCreated() async {
    this.architectWidget.load(loadPath, onLoadSuccess, onLoadFailed);
    this.architectWidget.resume();


    if(sample.requiredExtensions != null && (sample.requiredExtensions.contains("screenshot") ||
        sample.requiredExtensions.contains("save_load_instant_target") ||
        sample.requiredExtensions.contains("native_detail")||
        sample.requiredExtensions.contains("data_transfer"))) {
      this.architectWidget.setJSONObjectReceivedCallback(onJSONObjectReceived);
    }
  }

  Future<void> onJSONObjectReceived(Map<String, dynamic> jsonObject) async {
    if(jsonObject["action"] != null){
      switch(jsonObject["action"]) {
        case "get_data":
          trackedJoint = jsonObject["name"];
          if(trackedJoint == 'image_upper_arm'){
            upperArmTrackingData = List<dynamic>.from(jsonObject["data"]);
            updateDisplayUpper();
          }else if(trackedJoint == 'image_lower_arm'){
            lowerArmTrackingData = List<dynamic>.from(jsonObject["data"]);
            updateDisplayLower();

          }



          break;

      }
    }
  }

  Future<void> captureScreen() async {
    WikitudeResponse captureScreenResponse = await this.architectWidget.captureScreen(true, "");
    if(captureScreenResponse.success) {
      showSingleButtonDialog("Success", "Image saved in: " + captureScreenResponse.message, "OK");
    } else {
      if(captureScreenResponse.message.contains("permission")) {
        showDialogOpenAppSettings("Error", captureScreenResponse.message);
      }
      else {
        showSingleButtonDialog("Error", captureScreenResponse.message, "Ok");
      }
    }
  }

  void showSingleButtonDialog(String title, String content, final String buttonText) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              FlatButton(
                child: Text(buttonText),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    );
  }

  void showDialogOpenAppSettings(String title, String content) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
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

  Future<void> onLoadSuccess() async {

  }

  Future<void> onLoadFailed(String error) async {
    showSingleButtonDialog("Failed to load Architect World", error, "Ok");
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

  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 1200),
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        partialResults: true);
    print('listening');
//    setState(() {});
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
    List<String> stringList = result.recognizedWords.split(' ');

    print(stringList);
    if(stringList.length>0){
      if(stringList.last.toLowerCase().contains('start') &&  !_isRecording){
        _toggleRecording();
      }else if(stringList.last.toLowerCase().contains('stop') &&  _isRecording){
        _toggleRecording();

      }else if(stringList.last.toLowerCase().contains('back')){
//        cancelListening();
        Navigator.of(context).pop();

      }
    }



  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    //print("sound level $level: $minSoundLevel - $maxSoundLevel ");
    setState(() {
      this.level = level;
    });
  }
}


