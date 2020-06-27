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

  List<TimeSeriesAngle> dataList = [];
  List<charts.Series<TimeSeriesAngle, double>> seriesList = [];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
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
    File file = File(pathOfTheFileToWrite);


    String contents = await file.readAsString();
    List<List<dynamic>> loadedData =CsvToListConverter().convert(contents);
//    print(loadedData);

    for (final data in loadedData){
      dataList.add(TimeSeriesAngle(data[0], data[3]));
    }
    seriesList = [
      charts.Series<TimeSeriesAngle, double>(
        id: 'Angle',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesAngle angle, _) => angle.time,
        measureFn: (TimeSeriesAngle angle, _) => angle.angle,
//        radiusPxFn: (TimeSeriesAngle angle, _) => 1,
        data: dataList,
      )
    ];

    setState(() {

    });

  }

  Widget _buildChart(){
    return charts.LineChart(
        seriesList,
        animate: false,
        defaultRenderer: new charts.LineRendererConfig(includePoints: true),
        behaviors: [charts.PanAndZoomBehavior()],
        primaryMeasureAxis: charts.NumericAxisSpec(
          viewport: charts.NumericExtents(-180,180)
        ),


      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      //dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }
}
