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
  List<TimeSeriesAngle> upperArmDataList = [];
  List<TimeSeriesAngle> lowerArmDataList = [];
  bool _isShoulder = false;

  double _angleThreshold = -45;
  double _prevAngle = 0;
  double _currAngle = 0;
  List<double> _startTimes = [];
  List<double> _endTimes = [];
  List<double> _angles = [];


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
      body: Column(
        children: <Widget>[
          _buildChart(),

          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Knee Angles: ' + _angles.join(", "))
          )

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
    print(_isShoulder);
    double maxAngle = 0;

    if(_isShoulder){
      for (final data in loadedData){
        if(data.last==0) {
          upperArmDataList.add(TimeSeriesAngle(data[0], data[3]));
        }else {
          lowerArmDataList.add(TimeSeriesAngle(data[0], data[3]));
        }

      }
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
    }else {
      for (final data in loadedData) {
        kneeDataList.add(TimeSeriesAngle(data[0], data[3]));
        kneeDataList2.add(TimeSeriesAngle(data[0], data[1]));
        kneeDataList3.add(TimeSeriesAngle(data[0], data[2]));

        _currAngle = data[3];
        if(_currAngle<_angleThreshold && _prevAngle>_angleThreshold){
          _startTimes.add(data[0]);
          print(_startTimes);
        }

        if(_currAngle>_angleThreshold && _prevAngle<_angleThreshold){
          _endTimes.add(data[0]);
          _angles.add(maxAngle);
          maxAngle = 0;
          print(_endTimes);
          print(_angles);
        }

        if(_startTimes.length>_endTimes.length && maxAngle>_currAngle){
          maxAngle = _currAngle;

        }


        _prevAngle = _currAngle;


      }
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

  Widget _buildChart(){
    return Container(
      height: 300,
      child: charts.LineChart(
        seriesList1,
        animate: true,
        defaultRenderer: new charts.LineRendererConfig(includePoints: true),
        behaviors: [charts.SeriesLegend(), charts.PanAndZoomBehavior()],
        primaryMeasureAxis: charts.NumericAxisSpec(

            viewport: charts.NumericExtents(-180,180)
        ),

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
        behaviors: [charts.SeriesLegend(), charts.PanAndZoomBehavior()],
        primaryMeasureAxis: charts.NumericAxisSpec(

            viewport: charts.NumericExtents(-180,180)
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
