import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/measurement.dart';
import '../models/project_structure.dart';

import 'messungen_page.dart';
import 'analyse_page.dart';
import 'frag_ai_page.dart';

import '../widgets/sidebar.dart';

import '../services/measurement_data_service.dart';
import '../services/colibri_service.dart';
import '../services/demo_measurement_data_service.dart';

// ================================================================
// DASHBOARD
// ================================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ============================================================
  // DATEN
  // ============================================================

  List<Measurement> measurements = [];
  List<ProjectGroup> projectGroups = [];

  bool loading = true;
  String? error;

  DateTime? selectedMonth;

  final ScrollController _chartScrollController =
      ScrollController();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    print('=== DASHBOARD INITSTATE ===');

    loadMeasurements();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATEN LADEN
  // ============================================================

  Future<void> loadMeasurements() async {
    print(
      '=== DASHBOARD LOAD MEASUREMENTS START ===',
    );

    try {
      final demoService = DemoMeasurementService();

      final loadedMeasurements =
          await demoService.getMeasurements();

      final dataService = MeasurementDataService();

      final loadedProjects =
          dataService.groupMeasurements(
        loadedMeasurements,
      );

      if (!mounted) return;

      print(
        '=== DASHBOARD LOAD MEASUREMENTS SUCCESS: '
        '${loadedMeasurements.length} ===',
      );

      setState(() {
        measurements = loadedMeasurements;
        projectGroups = loadedProjects;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void openMessungen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessungenPage(
          measurements: measurements,
          projectGroups: projectGroups,
        ),
      ),
    );
  }

  void openAnalyse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysePage(
          measurements: measurements,
          projectGroups: projectGroups,
        ),
      ),
    );
  }

  void openFragAI() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FragAIPage(
          measurements: measurements,
        ),
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  void resetMonthFilter() {
    setState(() {
      selectedMonth = null;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: Row(
        children: [
          AppSidebar(
            selectedPage: 'Dashboard',
            onDashboard: () {},
            onMessungen: openMessungen,
            onAnalyse: openAnalyse,
            onFragAI: openFragAI,
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      )
                    : _buildDashboard(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    final total = measurements.length;

    final passedCount =
        measurements.where((m) => m.status == 'OK').length;

    final failedCount =
        measurements.where((m) => m.status == 'NOK').length;

    final uniqueArticles = measurements
        .map((m) => m.artikelnummer.toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;

    final passedPercentage =
        total == 0 ? 0.0 : passedCount / total * 100;

    final failedPercentage =
        total == 0 ? 0.0 : failedCount / total * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        32,
        30,
        32,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          _buildHeader(),

          const SizedBox(height: 30),

          // ======================================================
          // KPI
          // ======================================================

          Row(
            children: [
              Expanded(
                child: buildKpiCard(
                  title: 'Messungen',
                  value: _formatNumber(total),
                  subtitle: _measurementDateRange(),
                  icon: Icons.analytics_outlined,
                  iconColor: const Color(0xFF2563EB),
                  iconBackground: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: buildKpiCard(
                  title: 'Erfüllt',
                  value: _formatNumber(passedCount),
                  subtitle:
                      '${passedPercentage.toStringAsFixed(1)} %',
                  icon: Icons.check_rounded,
                  iconColor: const Color(0xFF10B981),
                  iconBackground: const Color(0xFFDCFCE7),
                  progress: passedPercentage / 100,
                  progressColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: buildKpiCard(
                  title: 'Nicht erfüllt',
                  value: _formatNumber(failedCount),
                  subtitle:
                      '${failedPercentage.toStringAsFixed(1)} %',
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFEF4444),
                  iconBackground: const Color(0xFFFEE2E2),
                  progress: failedPercentage / 100,
                  progressColor: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: buildKpiCard(
                  title: 'Artikel',
                  value: _formatNumber(uniqueArticles),
                  subtitle: 'Verschiedene Artikel',
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  iconBackground: const Color(0xFFF3E8FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // ======================================================
          // CHART + TOP 5
          // ======================================================

          SizedBox(
            height: 430,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: buildChartCard(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: buildTop5Card(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ======================================================
          // RESULT
          // ======================================================

          buildResultCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
  return const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Dashboard',
        style: TextStyle(
          fontSize: 34,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: Color(0xFF0F172A),
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Überblick über alle Messungen und Ergebnisse',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF64748B),
        ),
      ),
    ],
  );
}

  // ============================================================
  // KPI CARD
  // ============================================================

  Widget buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    double? progress,
    Color? progressColor,
  }) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 29,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: progress != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: progressColor ??
                        const Color(0xFF64748B),
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor:
                          const Color(0xFFE2E8F0),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        progressColor ??
                            const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART CARD
  // ============================================================

  Widget buildChartCard() {
    final monthlyData = _buildMonthlyData();

    final peak = monthlyData.isEmpty
        ? 0
        : monthlyData.map((e) => e.value).reduce(max);
    // Reserve room above the highest point for its hover tooltip.
    final maxValue = max(10.0, peak * 1.30);
    final chartWidth = max(1050.0, monthlyData.length * 125.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        24,
        18,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messungen im Zeitverlauf',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedMonth == null
                        ? 'Anzahl der Messungen pro Monat'
                        : 'Ausgewählt: ${_selectedMonthLabel()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: selectedMonth == null
                          ? const Color(0xFF64748B)
                          : const Color(0xFF2563EB),
                      fontWeight: selectedMonth == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (selectedMonth != null) ...[
                _buildResetButton(),
                const SizedBox(width: 10),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${_formatNumber(measurements.length)} gesamt',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ======================================================
          // CHART
          // ======================================================

          Expanded(
            child: monthlyData.isEmpty
                ? const Center(
                    child: Text(
                      'Keine Daten vorhanden.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _chartScrollController,
                    thumbVisibility: true,
                    thickness: 12,
                    trackVisibility: true,
                    interactive: true,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      controller: _chartScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 10),
                          child: LineChart(
                            LineChartData(
                              // Keep the first/last labels and points away
                              // from the clipped edges of the scroll view.
                              minX: -0.40,
                              maxX: monthlyData.length > 1
                                  ? monthlyData.length - 0.60
                                  : 0.40,
                              minY: 0,
                              maxY: maxValue,

                              // GRID
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval:
                                    _chartInterval(maxValue),
                                verticalInterval: 1,
                                getDrawingHorizontalLine:
                                    (value) {
                                  return const FlLine(
                                    color: Color(0xFFE2E8F0),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  );
                                },
                                getDrawingVerticalLine:
                                    (value) {
                                  return const FlLine(
                                    color: Color(0xFFE8EEF6),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  );
                                },
                              ),

                              borderData:
                                  FlBorderData(show: false),

                              // TITLES
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 46,
                                    interval:
                                        _chartInterval(maxValue),
                                    getTitlesWidget:
                                        (value, meta) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Text(
                                          value
                                              .toInt()
                                              .toString(),
                                          textAlign:
                                              TextAlign.right,
                                          style:
                                              const TextStyle(
                                            fontSize: 11,
                                            color:
                                                Color(0xFF64748B),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 34,
                                    interval: 1,
                                    getTitlesWidget:
                                        (value, meta) {
                                      if (value != value.roundToDouble()) {
                                        return const SizedBox.shrink();
                                      }
                                      final index =
                                          value.round();

                                      if (index < 0 ||
                                          index >=
                                              monthlyData.length) {
                                        return const SizedBox();
                                      }

                                      final month =
                                          monthlyData[index];

                                      final isSelected =
                                          selectedMonth != null &&
                                              selectedMonth!.year ==
                                                  month.year &&
                                              selectedMonth!.month ==
                                                  month.month;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          top: 10,
                                        ),
                                        child: Text(
                                          month.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(
                                                    0xFF2563EB,
                                                  )
                                                : const Color(
                                                    0xFF64748B,
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // TOUCH
                              lineTouchData: LineTouchData(
                                enabled: true,
                                handleBuiltInTouches: true,
                                touchCallback:
                                    (event, response) {
                                  if (event is! FlTapUpEvent) return;
                                  final spots =
                                      response?.lineBarSpots;

                                  if (spots == null ||
                                      spots.isEmpty) {
                                    return;
                                  }

                                  final index =
                                      spots.first.x.round();

                                  if (index < 0 ||
                                      index >=
                                          monthlyData.length) {
                                    return;
                                  }

                                  final month =
                                      monthlyData[index];

                                  setState(() {
                                    selectedMonth = DateTime(
                                      month.year,
                                      month.month,
                                    );
                                  });
                                },
                                touchTooltipData:
                                    LineTouchTooltipData(
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  tooltipMargin: 8,
                                  getTooltipItems: (spots) {
                                    return spots
                                        .map((spot) {
                                          final index =
                                              spot.x.round();

                                          if (index < 0 ||
                                              index >=
                                                  monthlyData
                                                      .length) {
                                            return null;
                                          }

                                          final month =
                                              monthlyData[index];

                                          return LineTooltipItem(
                                            '${month.fullLabel}\n'
                                            '${spot.y.toInt()} Messungen\n'
                                            'Klicken für Ergebnis',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          );
                                        })
                                        .whereType<
                                            LineTooltipItem>()
                                        .toList();
                                  },
                                ),
                              ),

                              // LINE
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    monthlyData.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      monthlyData[index]
                                          .value
                                          .toDouble(),
                                    ),
                                  ),
                                  isCurved: true,
                                  curveSmoothness: 0.35,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  color:
                                      const Color(0xFF2563EB),
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (
                                      spot,
                                      percent,
                                      bar,
                                      index,
                                    ) {
                                      final isSelected =
                                          selectedMonth != null &&
                                              index <
                                                  monthlyData
                                                      .length &&
                                              selectedMonth!.year ==
                                                  monthlyData[index]
                                                      .year &&
                                              selectedMonth!
                                                      .month ==
                                                  monthlyData[index]
                                                      .month;

                                      return FlDotCirclePainter(
                                        radius:
                                            isSelected ? 7 : 4,
                                        color: isSelected
                                            ? const Color(
                                                0xFF0F172A,
                                              )
                                            : const Color(
                                                0xFF2563EB,
                                              ),
                                        strokeWidth:
                                            isSelected ? 3 : 0,
                                        strokeColor:
                                            Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient:
                                        const LinearGradient(
                                      begin:
                                          Alignment.topCenter,
                                      end:
                                          Alignment.bottomCenter,
                                      colors: [
                                        Color(0x442563EB),
                                        Color(0x0D2563EB),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 10),

          const Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(width: 7),
              Text(
                'Monat anklicken, um Erfüllt/Nicht erfüllt für diesen Monat anzuzeigen.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTHLY DATA
  // ============================================================

  List<_MonthlyMeasurement> _buildMonthlyData() {
    final Map<String, int> counts = {};

    for (final measurement in measurements) {
      final date = measurement.datum;

      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';

      counts[key] = (counts[key] ?? 0) + 1;
    }

    if (counts.isEmpty) return [];

    // Display every month from the start of the Colibri import,
    // including months that have no measurements yet.
    final first = DateTime(2025, 1);
    final now = DateTime.now();
    final end = DateTime(now.year, now.month);

    final result = <_MonthlyMeasurement>[];
    for (var date = first;
        !date.isAfter(end);
        date = DateTime(date.year, date.month + 1)) {
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      result.add(_MonthlyMeasurement(
        year: date.year,
        month: date.month,
        label: date.month == 1
            ? '${_shortMonth(date.month)} ${date.year}'
            : _shortMonth(date.month),
        fullLabel: '${_fullMonth(date.month)} ${date.year}',
        value: counts[key] ?? 0,
      ));
    }
    return result;
  }

  // ============================================================
  // SELECTED MONTH
  // ============================================================

  String _selectedMonthLabel() {
    if (selectedMonth == null) {
      return '';
    }

    return '${_fullMonth(selectedMonth!.month)} '
        '${selectedMonth!.year}';
  }

  List<Measurement> _selectedMonthMeasurements() {
    if (selectedMonth == null) {
      return measurements;
    }

    return measurements.where((measurement) {
      final date = measurement.datum;

      return date.year == selectedMonth!.year &&
          date.month == selectedMonth!.month;
    }).toList();
  }

  // ============================================================
  // RESULT CARD
  // ============================================================

  Widget buildResultCard() {
    final selectedMeasurements =
        _selectedMonthMeasurements();

    final passed = selectedMeasurements
        .where((m) => m.status == 'OK')
        .length;

    final failed = selectedMeasurements
        .where((m) => m.status == 'NOK')
        .length;

    final total = selectedMeasurements.length;

    final passedPercentage =
        total == 0 ? 0.0 : passed / total * 100;

    final failedPercentage =
        total == 0 ? 0.0 : failed / total * 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        20,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF2563EB),
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedMonth == null
                        ? 'Ergebnis – Gesamt'
                        : 'Ergebnis – ${_selectedMonthLabel()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatNumber(total)} Messungen',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (selectedMonth != null)
                _buildResetButton(),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildLargeResultPanel(
                  label: 'Erfüllt',
                  count: passed,
                  percentage: passedPercentage,
                  color: const Color(0xFF10B981),
                  backgroundColor:
                      const Color(0xFFF0FDF4),
                  progressBackground:
                      const Color(0xFFD1FAE5),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildLargeResultPanel(
                  label: 'Nicht erfüllt',
                  count: failed,
                  percentage: failedPercentage,
                  color: const Color(0xFFEF4444),
                  backgroundColor:
                      const Color(0xFFFEF2F2),
                  progressBackground:
                      const Color(0xFFFEE2E2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LARGE RESULT PANEL
  // ============================================================

  Widget _buildLargeResultPanel({
    required String label,
    required int count,
    required double percentage,
    required Color color,
    required Color backgroundColor,
    required Color progressBackground,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        18,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(count),
                style: const TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(1)} %',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 9,
              backgroundColor: progressBackground,
              valueColor:
                  AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP 5
  // ============================================================

  Widget buildTop5Card() {
    final baStats = <String, _BaFailureStats>{};

    // The same monthly filter used by the Erfüllt/Nicht erfüllt card.
    for (final measurement in _selectedMonthMeasurements()) {
      final ba = measurement.baNr.toString().trim();
      if (ba.isEmpty) continue;

      final stats = baStats.putIfAbsent(
        ba,
        () => _BaFailureStats(ba),
      );
      stats.total++;
      if (measurement.status == 'NOK') stats.nok++;

      final name = measurement.name.toString().trim();
      if (name.isNotEmpty) {
        stats.names[name] = (stats.names[name] ?? 0) + 1;
      }
    }

    // Only BAs with at least one NOK qualify for a worst-BA ranking.
    final ranking = baStats.values.where((stats) => stats.nok > 0).toList()
      ..sort((a, b) {
        final rateOrder = b.failureRate.compareTo(a.failureRate);
        if (rateOrder != 0) return rateOrder;
        final nokOrder = b.nok.compareTo(a.nok);
        if (nokOrder != 0) return nokOrder;
        final totalOrder = b.total.compareTo(a.total);
        if (totalOrder != 0) return totalOrder;
        return a.ba.compareTo(b.ba);
      });
    final top5 = ranking.take(5).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top 5 - nicht erfüllt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Produktionen mit den meisten nicht erfüllten Messungen',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Keine nicht erfüllt-Messungen vorhanden.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: List.generate(top5.length, (index) {
                  final item = top5[index];
                  final percentage = item.failureRate * 100;
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        border: index < top5.length - 1
                            ? const Border(
                                bottom: BorderSide(color: Color(0xFFF1F5F9)),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          _buildRankingBadge(index),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.ba,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Tooltip(
                                  message: item.displayName,
                                  child: Text(
                                    item.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: item.failureRate,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 78,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(1)} %',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                                Text(
                                  '${item.nok} nicht erfüllt',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // RANKING BADGE
  // ============================================================

  Widget _buildRankingBadge(int index) {
    Color background;
    Color foreground;

    switch (index) {
      case 0:
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF475569);
        break;

      case 1:
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF475569);
        break;

      case 2:
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF475569);
        break;

      default:
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF475569);
    }

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  // ============================================================
  // RESET BUTTON
  // ============================================================

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: resetMonthFilter,
      icon: const Icon(
        Icons.filter_alt_off_outlined,
        size: 17,
      ),
      label: const Text(
        'Filter zurücksetzen',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF475569),
        backgroundColor: Colors.white,
        side: const BorderSide(
          color: Color(0xFFCBD5E1),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // CARD STYLE
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFE2E8F0),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _chartInterval(double maxValue) {
    if (maxValue <= 10) {
      return 2;
    }

    if (maxValue <= 50) {
      return 10;
    }

    if (maxValue <= 100) {
      return 20;
    }

    if (maxValue <= 500) {
      return 100;
    }

    if (maxValue <= 1000) {
      return 200;
    }

    return (maxValue / 5).ceilToDouble();
  }

  String _measurementDateRange() {
  if (measurements.isEmpty) {
    return 'Keine Messungen';
  }

  final dates = measurements
      .map((measurement) => measurement.datum)
      .toList()
    ..sort();

  final first = dates.first;
  final last = dates.last;

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  return '${formatDate(first)} – ${formatDate(last)}';
}

  String _formatNumber(int value) {
    final text = value.toString();

    if (text.length <= 3) {
      return text;
    }

    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;

      buffer.write(text[i]);

      if (positionFromEnd > 1 &&
          (positionFromEnd - 1) % 3 == 0) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  String _shortMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];

    return months[month - 1];
  }

  String _fullMonth(int month) {
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];

    return months[month - 1];
  }
}

// ================================================================
// MONTHLY MEASUREMENT MODEL
// ================================================================

class _MonthlyMeasurement {
  final int year;
  final int month;
  final String label;
  final String fullLabel;
  final int value;

  const _MonthlyMeasurement({
    required this.year,
    required this.month,
    required this.label,
    required this.fullLabel,
    required this.value,
  });
}

// Statistics for one BA within the current month selection.
class _BaFailureStats {
  final String ba;
  final Map<String, int> names = {};
  int total = 0;
  int nok = 0;

  _BaFailureStats(this.ba);

  double get failureRate => total == 0 ? 0 : nok / total;

  // The most common nonempty Name associated with this BA in the period.
  String get displayName {
    if (names.isEmpty) return 'Name nicht hinterlegt';
    final sorted = names.entries.toList()
      ..sort((a, b) {
        final countOrder = b.value.compareTo(a.value);
        return countOrder != 0 ? countOrder : a.key.compareTo(b.key);
      });
    return sorted.first.key;
  }
}