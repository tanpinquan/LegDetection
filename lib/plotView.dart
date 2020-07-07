import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:wikitude_flutter_app/model/timeseries.dart';
import 'package:charts_flutter/flutter.dart' as charts;


class PlotView extends StatefulWidget {
  final String fileName;

  const PlotView({Key key, this.fileName}) : super(key: key);

  @override
  _PlotViewState createState() => _PlotViewState();
}

class _PlotViewState extends State<PlotView> {

  List<TimeSeriesAngle> kneeDataList = [];
  List<TimeSeriesAngle> kneeDataList2 = [];
  List<TimeSeriesAngle> kneeDataList3 = [];

  List<charts.Series<TimeSeriesAngle, double>> seriesList1 = [];
  List<charts.Series<TimeSeriesAngle, double>> seriesList2 = [];
  List<charts.Series<TimeSeriesAngle, double>> seriesList3 = [];

  List<TimeSeriesAngle> upperArmDataList = [];
  List<TimeSeriesAngle> lowerArmDataList = [];
  List<TimeSeriesAngle> upperArmDataList2 = [];
  List<TimeSeriesAngle> lowerArmDataList2 = [];
  List<TimeSeriesAngle> upperArmDataList3 = [];
  List<TimeSeriesAngle> lowerArmDataList3 = [];
  bool _isShoulder = false;

  double _kneeAngleThreshold = 45;
  double _prevAngle = 0;
  double _currAngle = 0;
  List<double> _startTimes = [];
  List<double> _endTimes = [];
  List<double> _angles = [];
  double _averageAngle = 0;
  double averageInterval = 0;
  double _maxAngleKnee = 0;
  double _maxAngleShoulder = 0;
  double _shoulderAngleThreshold = 45;


  File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final bool confirm = await showDeleteDialog('Confirm delete?', 'This cannot be undone');
              if(confirm){
                await file.delete(recursive: false);
                Navigator.of(context).pop();

              }


            },
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          _buildExerciseSummary(),
          _buildChart(seriesList1, 'Rotation about Z'),
          Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(_isShoulder?'Shoulder Angles: ' + _angles.join(", ") :'Knee Angles: ' + _angles.join(", "))
          ),
          _buildChart(seriesList2,' Rotation about X'),
          _buildChart(seriesList3,' Rotation about Y'),

//          _buildChart2(),



        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFileToWrite = directory.path + "/" + widget.fileName;
    file = File(pathOfTheFileToWrite);


    String contents = await file.readAsString();
    List<List<dynamic>> loadedData =CsvToListConverter().convert(contents);
//    print(loadedData);
    _isShoulder = loadedData[0].length == 8;
    print('SHOULDER: $_isShoulder');
    double maxAngle = 0;

    if(_isShoulder){
      for (final data in loadedData){
        if(data.last==0) {
          upperArmDataList.add(TimeSeriesAngle(data[0], data[3]));
          upperArmDataList2.add(TimeSeriesAngle(data[0], data[1]));
          upperArmDataList3.add(TimeSeriesAngle(data[0], data[2]));

          detectShoulderExercise(data);
        }else {
          lowerArmDataList.add(TimeSeriesAngle(data[0], data[3]));
          lowerArmDataList2.add(TimeSeriesAngle(data[0], data[1]));
          lowerArmDataList3.add(TimeSeriesAngle(data[0], data[2]));

        }

      }
      calculateExerciseStats();
//      _averageAngle =  _angles.reduce((a,b) => a + b) / _angles.length;

      seriesList1 = [
        charts.Series<TimeSeriesAngle, double>(
          id: 'Upper Arm',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
          data: upperArmDataList,
        ),
        charts.Series<TimeSeriesAngle, double>(
          id: 'Lower Arm',
          colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
          data: lowerArmDataList,
        )
      ];
      seriesList2 = [
        charts.Series<TimeSeriesAngle, double>(
          id: 'Upper Arm',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
          data: upperArmDataList2,
        ),
        charts.Series<TimeSeriesAngle, double>(
          id: 'Lower Arm',
          colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
          data: lowerArmDataList2,
        )
      ];

      seriesList3 = [
        charts.Series<TimeSeriesAngle, double>(
          id: 'Upper Arm',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
          data: upperArmDataList3,
        ),
        charts.Series<TimeSeriesAngle, double>(
          id: 'Lower Arm',
          colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
          data: lowerArmDataList3,
        )
      ];

    }else {
      for (final data in loadedData) {
        kneeDataList.add(TimeSeriesAngle(data[0], data[3]));
        kneeDataList2.add(TimeSeriesAngle(data[0], data[1]));
        kneeDataList3.add(TimeSeriesAngle(data[0], data[2]));
        detectKneeExercise(data);


      }
      calculateExerciseStats();



      seriesList1 = [
        charts.Series<TimeSeriesAngle, double>(
          id: 'Knee Angle',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
//        radiusPxFn: (TimeSeriesAngle angle, _) => 1,
          data: kneeDataList,
        )
      ];
      seriesList2 = [
        charts.Series<TimeSeriesAngle, double>(
          id: 'Knee Angle X',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
//        radiusPxFn: (TimeSeriesAngle angle, _) => 1,
          data: kneeDataList2,
        ),

      ];
      seriesList3 = [

        charts.Series<TimeSeriesAngle, double>(
          id: 'Knee Angle Y',
          colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
          data: kneeDataList3,
        )
      ];
    }

    setState(() {

    });

  }

  void detectShoulderExercise(List data){
    _currAngle = data[3];
    if(_currAngle>_shoulderAngleThreshold && _prevAngle<_shoulderAngleThreshold){
      _startTimes.add(data[0]);
      print(_startTimes);
    }

    if(_currAngle<_shoulderAngleThreshold && _prevAngle>_shoulderAngleThreshold){
      _endTimes.add(data[0]);
      _angles.add(_maxAngleShoulder);
      _maxAngleShoulder = 0;
      print(_endTimes);
      print(_angles);
    }

    if(_startTimes.length>_endTimes.length && _maxAngleShoulder<_currAngle){
      _maxAngleShoulder = _currAngle;

    }


    _prevAngle = _currAngle;
  }


  void detectKneeExercise(List data){
    _currAngle = data[3];
    if(_currAngle>_kneeAngleThreshold && _prevAngle<_kneeAngleThreshold){
      _startTimes.add(data[0]);
      print(_startTimes);
    }

    if(_currAngle<_kneeAngleThreshold && _prevAngle>_kneeAngleThreshold){
      _endTimes.add(data[0]);
      _angles.add(_maxAngleKnee);
      _maxAngleKnee = 0;
      print(_endTimes);
      print(_angles);
    }

    if(_startTimes.length>_endTimes.length && _maxAngleKnee<_currAngle){
      _maxAngleKnee = _currAngle;

    }


    _prevAngle = _currAngle;
  }

  void calculateExerciseStats(){
    if(_angles.isNotEmpty) {
      _averageAngle = _angles.reduce((a, b) => a + b) / _angles.length;
      averageInterval = (_endTimes.last - _startTimes.first)/_endTimes.length;
      print(averageInterval);
    }
  }

  Widget _buildExerciseSummary(){
//    if(_endTimes.isEmpty){
//      return Container();
//    }
//    double averageInterval = (_endTimes.last - _startTimes.first)/_endTimes.length;

    print(averageInterval);
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Exercise Summary', style: Theme.of(context).textTheme.headline6,),
              Text('Repetitions : ${_angles.length}'),
              Text('Average Interval ${averageInterval.toStringAsFixed(2)}s'),
              Text('Average Angle: ${_averageAngle.toStringAsFixed(2)}°')
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<charts.Series<TimeSeriesAngle, double>> seriesList, String title){
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(thickness: 1, color: Colors.black,),
          Text(title, style: Theme.of(context).textTheme.headline6,),
          Container(
            height: 300,
            child: charts.LineChart(
              seriesList,
              animate: true,
              defaultRenderer: new charts.LineRendererConfig(includePoints: true),
              behaviors: [charts.SeriesLegend(),],
//        behaviors: [charts.SeriesLegend(), charts.PanAndZoomBehavior()],

              primaryMeasureAxis: charts.NumericAxisSpec(
                  tickProviderSpec: new charts.BasicNumericTickProviderSpec(zeroBound: false)
//            viewport: charts.NumericExtents(-180,180)
              ),
              domainAxis: charts.NumericAxisSpec(
                  tickProviderSpec: new charts.BasicNumericTickProviderSpec(zeroBound: false)
//            viewport: charts.NumericExtents(-180,180)
              ),

            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart2(){
    return Container(
      height: 300,
      child: charts.LineChart(
        seriesList2,
        animate: true,
        defaultRenderer: new charts.LineRendererConfig(includePoints: true),
        behaviors: [charts.SeriesLegend()],
//        behaviors: [charts.SeriesLegend(), charts.PanAndZoomBehavior()],

        primaryMeasureAxis: charts.NumericAxisSpec(
            tickProviderSpec: new charts.BasicNumericTickProviderSpec(zeroBound: false)

//            viewport: charts.NumericExtents(-180,180)
        ),

      ),
    );
  }

  Future<bool> showDeleteDialog(String title, String content) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              FlatButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              FlatButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              )
            ],
          );
        }
    );
  }
}
