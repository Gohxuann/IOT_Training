import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() => runApp(MaterialApp(home: DashboardPage()));

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<FlSpot> tempData = [];
  List<FlSpot> humData = [];
  List<Map<String, dynamic>> readingTable = [];
  double latestTemp = 0;
  double latestHum = 0;
  String relayStatus = '-';
  double tempThreshold = 0;
  double humThreshold = 0;
  int rowsPerPage = 11;
  int currentPage = 0;

  DateTime? lastUpdated;

  final String getDataUrl = 'YOUR_URL_HERE'; // Replace with your actual URL
  final String getThresholdUrl = 'YOUR_URL_HERE';
  final String updateThresholdUrl = 'YOUR_URL_HERE';

  final tempController = TextEditingController();
  final humController = TextEditingController();
  Timer? autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchThreshold();
    autoRefreshTimer =
        Timer.periodic(Duration(seconds: 10), (_) => fetchData());
  }

  @override
  void dispose() {
    autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(getDataUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        tempData = [];
        humData = [];
        readingTable = [];
        for (int i = 0; i < data.length; i++) {
          tempData.add(FlSpot(i.toDouble(), double.parse(data[i]['temp'])));
          humData.add(FlSpot(i.toDouble(), double.parse(data[i]['hum'])));
          String rawTime = data[i]['date'];
          String formattedTime = (rawTime != null && rawTime != '')
              ? DateFormat('MM-dd HH:mm:ss').format(DateTime.parse(rawTime))
              : 'N/A';
          readingTable.add({
            'time': formattedTime,
            'temp': data[i]['temp'],
            'hum': data[i]['hum'],
            'relay': data[i]['relay_status'],
          });
        }
        if (data.isNotEmpty) {
          latestTemp = double.parse(data.last['temp']);
          latestHum = double.parse(data.last['hum']);
          relayStatus = data.last['relay_status'];
        }
        lastUpdated = DateTime.now();
      });
    }
  }

  Future<void> fetchThreshold() async {
    final response = await http.get(Uri.parse(getThresholdUrl));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        tempThreshold = double.parse(jsonData['temp_threshold']);
        humThreshold = double.parse(jsonData['hum_threshold']);
        tempController.text = tempThreshold.toString();
        humController.text = humThreshold.toString();
      });
    }
  }

  Future<void> updateThresholds() async {
    final response = await http.post(
      Uri.parse(updateThresholdUrl),
      body: {
        'temp_threshold': tempController.text,
        'hum_threshold': humController.text,
      },
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thresholds updated successfully')),
      );
      fetchThreshold();
    }
  }

  Widget buildStatusMessage() {
    bool isTempHigh = latestTemp > tempThreshold;
    bool isHumHigh = latestHum > humThreshold;
    if (isTempHigh || isHumHigh) {
      return Text('🚨 ALERT: High Temperature or Humidity detected!',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ));
    } else {
      return Text('✅ SAFE: Values are within normal range',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ));
    }
  }

  Widget buildAlertIcon(String label) {
    return Tooltip(
      message: 'Warning: $label is near or above threshold value.',
      child: Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange.shade700,
        size: 36,
      ),
    );
  }

  Widget buildAnimatedChart(double value, String label, double threshold) {
    Color color;
    String emoji;
    Widget? alertIcon;

    if (value < threshold * 0.8) {
      color = Colors.green;
      emoji = label == 'Temperature' ? '🟢' : '💧';
      alertIcon = null;
    } else if (value < threshold) {
      color = Colors.orange;
      emoji = '⚠️';
      alertIcon = buildAlertIcon(label);
    } else {
      color = Colors.red;
      emoji = '🔥';
      alertIcon = buildAlertIcon(label);
    }

    return Container(
      height: 285,
      width: 285,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value / 100,
            backgroundColor: color.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 14,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: 50),
              ),
              SizedBox(height: 8),
              Text(
                '${value.toStringAsFixed(1)}${label == 'Temperature' ? '°C' : '%'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: color,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    )
                  ],
                ),
              ),
              SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: color.withOpacity(0.8),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRelayToggle() {
    bool isOn = relayStatus.toUpperCase() == 'ON';
    return Focus(
      child: GestureDetector(
        onTap: () {
          setState(() {
            relayStatus = isOn ? 'OFF' : 'ON';
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Relay toggled to ${isOn ? 'OFF' : 'ON'}'),
          ));
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 70,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: isOn ? Colors.green.shade400 : Colors.red.shade400,
            boxShadow: [
              BoxShadow(
                color: isOn ? Colors.green.shade200 : Colors.red.shade200,
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isOn ? 30 : 0,
                right: isOn ? 0 : 30,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              Center(
                child: Text(
                  isOn ? 'ON' : 'OFF',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLiveSensorStatus() {
    return Expanded(
      child: Card(
        elevation: 6,
        shadowColor: Colors.grey.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Live Sensor Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green)),
              Divider(thickness: 2, height: 25),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildAnimatedChart(
                          latestTemp, 'Temperature', tempThreshold),
                      SizedBox(width: 20),
                      buildAnimatedChart(latestHum, 'Humidity', humThreshold),
                    ],
                  ),
                  SizedBox(height: 20),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Relay',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.green)),
                      SizedBox(height: 10),
                      buildRelayToggle(),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 65),
              ElevatedButton.icon(
                onPressed: fetchData,
                icon: Icon(Icons.refresh, size: 28),
                label: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Text('Refresh', style: TextStyle(fontSize: 18)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              SizedBox(height: 20),
              buildStatusMessage(),
              SizedBox(height: 8),
              if (lastUpdated != null)
                Text(
                  'Last updated: ${DateFormat('HH:mm:ss').format(lastUpdated!)}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildChart(
    List<FlSpot> spots,
    String label,
    Color color,
    List<Map<String, dynamic>> tableData,
    bool isTempChart,
  ) {
    double minY = isTempChart ? 0 : 50;
    double maxY = isTempChart ? 50 : 99;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < tableData.length) {
                  String rawTime = tableData[index]['time'];
                  return Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      rawTime,
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.05),
                ],
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: isTempChart ? Colors.green : Colors.blue,
                  strokeColor: Colors.black,
                  strokeWidth: 1,
                );
              },
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            tooltipBorder: BorderSide(color: color),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                int index = spot.x.toInt();
                if (index < tableData.length) {
                  return LineTooltipItem(
                    '${tableData[index]['time']}\n$label: ${spot.y.toStringAsFixed(1)}',
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: isTempChart ? tempThreshold : humThreshold,
            color: Colors.red,
            strokeWidth: 2,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              labelResolver: (_) =>
                  isTempChart ? 'Temperature Threshold' : 'Humidity Threshold',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ]),
      ),
    );
  }

  Widget buildReadingTable() {
    int start = currentPage * rowsPerPage;
    int end = (start + rowsPerPage > readingTable.length)
        ? readingTable.length
        : start + rowsPerPage;
    List<DataRow> rows = readingTable.reversed
        .toList()
        .sublist(start, end)
        .map((r) => DataRow(cells: [
              DataCell(Text(r['time'].toString())),
              DataCell(Text(r['temp'].toString())),
              DataCell(Text(r['hum'].toString())),
              DataCell(Text(r['relay'].toString())),
            ]))
        .toList();

    return Expanded(
      child: Card(
        elevation: 6,
        shadowColor: Colors.grey.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50, Colors.green],
                  ),
                ),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.green),
                  dataRowColor: MaterialStateProperty.resolveWith((states) =>
                      states.contains(MaterialState.selected)
                          ? Colors.green
                          : Colors.white),
                  columns: [
                    DataColumn(
                        label: Row(children: [
                      Icon(Icons.access_time),
                      SizedBox(width: 5),
                      Text('Time')
                    ])),
                    DataColumn(
                        label: Row(children: [
                      Icon(Icons.thermostat),
                      SizedBox(width: 5),
                      Text('Temp (°C)')
                    ])),
                    DataColumn(
                        label: Row(children: [
                      Icon(Icons.water_drop),
                      SizedBox(width: 5),
                      Text('Hum (%)')
                    ])),
                    DataColumn(
                        label: Row(children: [
                      Icon(Icons.electric_bolt),
                      SizedBox(width: 5),
                      Text('Relay')
                    ])),
                  ],
                  rows: rows,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: currentPage > 0
                        ? () => setState(() => currentPage--)
                        : null,
                  ),
                  Text('Page ${currentPage + 1}'),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed:
                        (currentPage + 1) * rowsPerPage < readingTable.length
                            ? () => setState(() => currentPage++)
                            : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildThresholdUpdate() {
    return Card(
      elevation: 6,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Threshold Update',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            Divider(thickness: 2, height: 25),
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _iconText(
                      Icons.warning,
                      'Temperature Threshold',
                      textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green),
                    ), // Bigger subtitle text
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _iconText(
                      Icons.warning_amber,
                      'Humidity Threshold',
                      textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue),
                    ),
                  ),
                  SizedBox(),
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 48,
                      child: _thresholdInput(tempController),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 48,
                      child: _thresholdInput(humController),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8),
                    child: ElevatedButton.icon(
                      onPressed: updateThresholds,
                      icon: Icon(Icons.save),
                      label: Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          SizedBox(width: 6),
          Text(
            text,
            style: textStyle ??
                TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }

  Widget _thresholdInput(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('🌡️ Temperature & Humidity Monitor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.lightGreen,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: fetchData,
              tooltip: 'Refresh Data',
            ),
          ]),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLiveSensorStatus(),
                SizedBox(width: 16),
                buildReadingTable(),
              ],
            ),
            SizedBox(height: 20),
            buildThresholdUpdate(),
            SizedBox(height: 30),
            Text('🔥 Temperature Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              height: 300,
              width: double.infinity,
              child: buildChart(
                  tempData, 'Temperature', Colors.green, readingTable, true),
            ),
            SizedBox(height: 10),
            SizedBox(height: 20),
            Text('💧 Humidity Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              height: 300,
              width: double.infinity,
              child: buildChart(
                  humData, 'Humidity', Colors.blue, readingTable, false),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
