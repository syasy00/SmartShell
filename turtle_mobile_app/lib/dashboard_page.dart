import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';

class SmartHubTemperaturePage extends StatefulWidget {
  final String nestName;
  final double temperature;
  final double humidity;
  final bool isDarkMode;

  const SmartHubTemperaturePage({
    super.key,
    required this.nestName,
    required this.temperature,
    required this.humidity,
    required this.isDarkMode,
  });

  @override
  State<SmartHubTemperaturePage> createState() => _SmartHubTemperaturePageState();
}

class _SmartHubTemperaturePageState extends State<SmartHubTemperaturePage> {
  bool isFanOn = false;
  bool isMisterOn = false;

  final List<_DataPoint> dataPoints = [
    _DataPoint(time: "Mon", temp: 29.5, humidity: 60),
    _DataPoint(time: "Tue", temp: 30.0, humidity: 62),
    _DataPoint(time: "Wed", temp: 30.8, humidity: 65),
    _DataPoint(time: "Thu", temp: 31.4, humidity: 67),
    _DataPoint(time: "Fri", temp: 31.8, humidity: 68),
    _DataPoint(time: "Sat", temp: 32.0, humidity: 69),
    _DataPoint(time: "Sun", temp: 32.2, humidity: 70),
  ];

  List<FlSpot> get tempSpots => dataPoints
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), e.value.temp))
      .toList();

  @override
  void initState() {
    super.initState();
    _loadDeviceStates();
  }

  Future<void> _loadDeviceStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFanOn = prefs.getBool('${widget.nestName}_fan') ?? false;
      isMisterOn = prefs.getBool('${widget.nestName}_mister') ?? false;
    });
  }

  Future<void> _saveDeviceState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('${widget.nestName}_$key', value);
  }

  void _toggleFan() {
    setState(() => isFanOn = !isFanOn);
    _saveDeviceState('fan', isFanOn);
  }

  void _toggleMister() {
    setState(() => isMisterOn = !isMisterOn);
    _saveDeviceState('mister', isMisterOn);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final bgColor =
        widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black87),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back to Smart Shells',
                      ),
                      Text(widget.nestName,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                    ],
                  ),
                  Icon(Icons.more_vert,
                      color: widget.isDarkMode
                          ? Colors.white54
                          : Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 10, end: widget.temperature),
                  duration: const Duration(seconds: 1),
                  builder: (context, animatedTemp, child) {
                    return SfRadialGauge(
                      axes: [
                        RadialAxis(
                          minimum: 10,
                          maximum: 40,
                          startAngle: 150,
                          endAngle: 30,
                          showTicks: false,
                          showLabels: true,
                          labelsPosition: ElementsPosition.outside,
                          axisLabelStyle: GaugeTextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          axisLineStyle: AxisLineStyle(
                            thickness: 0.2,
                            thicknessUnit: GaugeSizeUnit.factor,
                            cornerStyle: CornerStyle.bothCurve,
                            gradient: SweepGradient(
                              colors: [Colors.blue, Colors.green, Colors.red],
                              stops: const [0.0, 0.5, 1.0],
                              transform: const GradientRotation(2.5),
                            ),
                          ),
                          ranges: [
                            GaugeRange(
                              startValue: 10,
                              endValue: animatedTemp,
                              color: Colors.redAccent,
                              startWidth: 0.2,
                              endWidth: 0.2,
                              sizeUnit: GaugeSizeUnit.factor,
                            ),
                          ],
                          annotations: [
                            GaugeAnnotation(
                              angle: 90,
                              positionFactor: 0.1,
                              widget: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${animatedTemp.toStringAsFixed(1)}°C",
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Humidity: ${widget.humidity.toStringAsFixed(0)}%",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDarkMode
                                              ? Colors.white60
                                              : Colors.grey)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text("Temperature Trend",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            return index < dataPoints.length
                                ? Text(dataPoints[index].time,
                                    style: TextStyle(
                                        fontSize: 10, color: textColor))
                                : const Text('');
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: tempSpots,
                        isCurved: true,
                        barWidth: 2,
                        color: Colors.redAccent,
                        dotData: FlDotData(show: true),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text("Devices",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleFan,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isFanOn
                              ? Colors.orangeAccent.withOpacity(0.2)
                              : (widget.isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.air,
                                color: isFanOn ? Colors.orange : textColor,
                                size: 28),
                            const SizedBox(height: 8),
                            Text("Fan",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isFanOn ? Colors.orange : textColor)),
                            Text("Connected · 8H 12M",
                                style: TextStyle(
                                    fontSize: 11,
                                    color: widget.isDarkMode
                                        ? Colors.white60
                                        : Colors.grey))
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleMister,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isMisterOn
                              ? Colors.redAccent
                              : (widget.isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.water,
                                color: isMisterOn
                                    ? Colors.white
                                    : Colors.redAccent,
                                size: 28),
                            const SizedBox(height: 8),
                            Text("Mister",
                                style: TextStyle(
                                    color:
                                        isMisterOn ? Colors.white : textColor,
                                    fontWeight: FontWeight.bold)),
                            Text("Connected · 8H 12M",
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isMisterOn
                                        ? Colors.white70
                                        : (widget.isDarkMode
                                            ? Colors.white60
                                            : Colors.grey)))
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _DataPoint {
  final String time;
  final double temp;
  final int humidity;

  _DataPoint({required this.time, required this.temp, required this.humidity});
}
