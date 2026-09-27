import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class LineChartWidget extends StatefulWidget {
  final List<double> monthlyData;
  final Duration startDelay;
  final bool shouldAnimate;
  final Color lineColor;

  const LineChartWidget({
    super.key,
    required this.monthlyData,
    this.startDelay = Duration.zero,
    this.shouldAnimate = true,
    required this.lineColor
  });

   @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lineRevealController;
  bool _hasStarted = false;

  void _startAnimationIfNeeded() {
    if (_hasStarted || !widget.shouldAnimate) {
      return;
    }

    _hasStarted = true;
    if (widget.startDelay == Duration.zero) {
      _lineRevealController.forward();
    } else {
      Future.delayed(widget.startDelay, () {
        if (mounted) {
          _lineRevealController.forward();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _lineRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _startAnimationIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LineChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shouldAnimate && widget.shouldAnimate) {
      _startAnimationIfNeeded();
    }
  }

  @override
  void dispose() {
    _lineRevealController.dispose();
    super.dispose();
  }

  List<FlSpot> _buildVisibleSpots(double progress) {
    if (widget.monthlyData.isEmpty) {
      return const <FlSpot>[];
    }

    if (widget.monthlyData.length == 1) {
      return [FlSpot(0, widget.monthlyData.first)];
    }

    final lastIndex = widget.monthlyData.length - 1;
    final currentX = progress.clamp(0.0, 1.0) * lastIndex;
    final fullIndex = currentX.floor();
    final spots = <FlSpot>[];

    for (var i = 0; i <= fullIndex && i < widget.monthlyData.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.monthlyData[i]));
    }

    if (fullIndex < lastIndex) {
      final leftY = widget.monthlyData[fullIndex];
      final rightY = widget.monthlyData[fullIndex + 1];
      final t = currentX - fullIndex;
      final interpolatedY = leftY + ((rightY - leftY) * t);
      spots.add(FlSpot(currentX, interpolatedY));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final maxDataY = widget.monthlyData.isEmpty
        ? 0.0
        : widget.monthlyData.reduce(math.max);
    // Keep maxY above minY so fl_chart can render even when data is empty or all zeros.
    final maxYValue = math.max(1.0, maxDataY);
    final yAxisStep = maxYValue / 4;

    return Opacity(
      opacity: _hasStarted ? 1.0 : 0.0,
      child: Center(
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: SizedBox(
          height: 150,
          child: AnimatedBuilder(
            animation: _lineRevealController,
            builder: (context, _) => LineChart(
              LineChartData(
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: maxYValue,
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 1,
                      minIncluded: true,
                      maxIncluded: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Jan','Feb','Mar','Apr','May','Jun',
                          'Jul','Aug','Sep','Oct','Nov','Dec'
                        ];

                        // Only label whole-number month ticks to avoid duplicate labels.
                        if ((value - value.roundToDouble()).abs() > 0.001) {
                          return const SizedBox.shrink();
                        }

                        final index = value.round();
                        if (index >= 0 && index < months.length) {
                          return Text(months[index], style: const TextStyle(fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: yAxisStep,
                      minIncluded: true,
                      maxIncluded: true,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.black),
                    bottom: BorderSide(color: Colors.black),
                    top: BorderSide(color: Colors.transparent),
                    right: BorderSide(color: Colors.transparent),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildVisibleSpots(_lineRevealController.value),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    preventCurveOvershootingThreshold: 0.01,
                    color: widget.lineColor,
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}