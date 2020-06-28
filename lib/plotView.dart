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
  List<charts.Series<TimeSeriesAngle, double>> seriesList = [];
  List<TimeSeriesAngle> upperArmDataList = [];
  List<TimeSeriesAngle> lowerArmDataList = [];
  bool _isShoulder = false;

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
      body: _buildChart(),
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

    if(_isShoulder){
      for (final data in loadedData){
        if(data.last==0) {
          upperArmDataList.add(TimeSeriesAngle(data[0], data[3]));
        }else {
          lowerArmDataList.add(TimeSeriesAngle(data[0], data[3]));
        }

      }
      seriesList = [
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
      }
      seriesList = [
        charts.Series<TimeSeriesAngle, double>(
          id: 'Knee Angle',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (TimeSeriesAngle angle, _) => angle.time,
          measureFn: (TimeSeriesAngle angle, _) => angle.angle,
//        radiusPxFn: (TimeSeriesAngle angle, _) => 1,
          data: kneeDataList,
        )
      ];
    }

    setState(() {

    });

  }

  Widget _buildChart(){
    return charts.LineChart(
        seriesList,
        animate: false,
        defaultRenderer: new charts.LineRendererConfig(includePoints: true),
        behaviors: [charts.PanAndZoomBehavior(), charts.SeriesLegend()],
        primaryMeasureAxis: charts.NumericAxisSpec(
          viewport: charts.NumericExtents(-180,180)
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
