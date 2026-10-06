import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/project_structure.dart';
import '../models/measurement.dart';

import 'messungen_page.dart';
import 'messungsdetails_page.dart';
import 'frag_ai_page.dart';
import '../widgets/sidebar.dart';


class AnalysePage extends StatefulWidget {
  final List<Measurement> measurements;
  final List<ProjectGroup> projectGroups;

  const AnalysePage({
    super.key,
    required this.measurements,
    required this.projectGroups,
  });

  @override
  State<AnalysePage> createState() => _AnalysePageState();
}

class _AnalysePageState extends State<AnalysePage> {
  // ΔE* does not have its own Colibri tolerance in the current data model.
  // For now, this value remains as a separate limit.
  static const double toleranzDeltaE = 2.0;

  final TextEditingController artikelController =
      TextEditingController();
  final TextEditingController baNrController =
      TextEditingController();
  final TextEditingController benutzerController =
      TextEditingController();
  final TextEditingController vonController =
      TextEditingController();
  final TextEditingController bisController =
      TextEditingController();

  String selectedErgebnis = 'Alle';

  DateTime? startDate;
  DateTime? endDate;
  Measurement? selectedMeasurement;
  final Set<Measurement> selectedMeasurements = <Measurement>{};

  bool showL = true;
  bool showA = true;
  bool showB = true;
  bool showDeltaE = true;
  bool showDeltaL = false;
  bool showDeltaA = false;
  bool showDeltaB = false;

  // Tolerance lines cannot be enabled or disabled independently of the measurement series.
  bool showToleranceL = true;
  bool showToleranceA = true;
  bool showToleranceB = true;
  bool showToleranceDeltaE = false;

  // The analysis starts empty. Results are only displayed after a search.
  bool hasSearched = false;

  List<Measurement> get _measurements {
    return widget.measurements.where((m) => !_isReference(m)).toList();
  }

  List<String> get artikelOptions {
    final values = _measurements
        .map((m) => m.artikelnummer.toString())
        .where((v) => v.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Alle', ...values];
  }

  List<String> get baNrOptions {
    final values = _measurements
        .map((m) => m.baNr.toString())
        .where((v) => v.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Alle', ...values];
  }

  List<String> get benutzerOptions {
    final values = _measurements
        .map((m) => m.benutzer.toString())
        .where((v) => v.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Alle', ...values];
  }

  DateTime get dataMinDate {
    if (_measurements.isEmpty) {
      return DateTime(2025, 1, 1);
    }
    return _measurements
        .map((m) => m.datum)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime get dataMaxDate {
    if (_measurements.isEmpty) {
      return DateTime(2026, 9, 8);
    }
    return _measurements
        .map((m) => m.datum)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  void initState() {
    super.initState();

    // Date filters remain empty on startup.
    // From/To are only set when the user enters a date.
    startDate = null;
    endDate = null;
    vonController.clear();
    bisController.clear();

    if (_measurements.isNotEmpty) {
      selectedMeasurement = _measurements.first;
    }
  }

  @override
  void dispose() {
    artikelController.dispose();
    baNrController.dispose();
    benutzerController.dispose();
    vonController.dispose();
    bisController.dispose();
    super.dispose();
  }

  bool _isReference(dynamic m) {
    final artikel = m.artikelnummer.toString().trim();
    final bezug = m.bezug.toString().trim();
    final baNr = m.baNr.toString().trim();
    final benutzer = m.benutzer.toString().trim();

    if (artikel == 'Schwarz RR' && baNr.isEmpty && benutzer.isEmpty) {
      return true;
    }

    return artikel.isNotEmpty &&
        artikel == bezug &&
        baNr.isEmpty &&
        benutzer.isEmpty;
  }

  List<Measurement> get displayedMeasurements {
    if (!hasSearched) {
      return const <Measurement>[];
    }
    return filteredMeasurements;
  }

  List<Measurement> get filteredMeasurements {
    final result = _measurements.where((m) {
      final artikel = m.artikelnummer.toString();
      final baNr = m.baNr.toString();
      final benutzer = m.benutzer.toString();
      final status = m.status.toString().trim().toLowerCase();
      final date = m.datum;

      final artikelSearch =
          artikelController.text.trim().toLowerCase();
      final baNrSearch =
          baNrController.text.trim().toLowerCase();
      final benutzerSearch =
          benutzerController.text.trim().toLowerCase();

      final artikelMatch =
          artikelSearch.isEmpty ||
          artikel.toLowerCase().contains(artikelSearch);
      final baNrMatch =
          baNrSearch.isEmpty ||
          baNr.toLowerCase().contains(baNrSearch);
      final benutzerMatch =
          benutzerSearch.isEmpty ||
          benutzer.toLowerCase().contains(benutzerSearch);
      final ergebnisMatch =
          selectedErgebnis == 'Alle' ||
          (selectedErgebnis == 'erfüllt' && status == 'ok') ||
          (selectedErgebnis == 'nicht erfüllt' && status == 'nok');
      final startMatch =
          startDate == null || !date.isBefore(_dateOnly(startDate!));
      final endMatch =
          endDate == null || !date.isAfter(_endOfDay(endDate!));

      return artikelMatch &&
          baNrMatch &&
          benutzerMatch &&
          ergebnisMatch &&
          startMatch &&
          endMatch;
    }).toList();

    result.sort((a, b) => (b.datum).compareTo(a.datum));
    return result;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  String formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  String formatDateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  String number(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

  void resetFilters() {
    setState(() {
      artikelController.clear();
      baNrController.clear();
      benutzerController.clear();
      selectedErgebnis = 'Alle';

      startDate = null;
      endDate = null;
      vonController.clear();
      bisController.clear();

      selectedMeasurement = null;
      selectedMeasurements.clear();
      hasSearched = false;
    });
  }

  DateTime? _parseGermanDate(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    final match =
        RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$')
            .firstMatch(text);

    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);

    if (day == null || month == null || year == null) {
      return null;
    }

    final parsed = DateTime(year, month, day);

    if (parsed.year != year ||
        parsed.month != month ||
        parsed.day != day) {
      return null;
    }

    return parsed;
  }

  bool _applyDateInputs() {
    final vonText = vonController.text.trim();
    final bisText = bisController.text.trim();

    final parsedStart =
        vonText.isEmpty ? null : _parseGermanDate(vonText);
    final parsedEnd =
        bisText.isEmpty ? null : _parseGermanDate(bisText);

    if (vonText.isNotEmpty && parsedStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte Datum "Von" im Format TT.MM.JJJJ eingeben.',
          ),
        ),
      );
      return false;
    }

    if (bisText.isNotEmpty && parsedEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte Datum "Bis" im Format TT.MM.JJJJ eingeben.',
          ),
        ),
      );
      return false;
    }

    if (parsedStart != null &&
        parsedEnd != null &&
        parsedStart.isAfter(parsedEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '"Von" darf nicht nach "Bis" liegen.',
          ),
        ),
      );
      return false;
    }

    startDate = parsedStart;
    endDate = parsedEnd;
    return true;
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _filterTextField({
    required String label,
    required TextEditingController controller,
    double width = 220,
    String? hintText,
    bool clearOnTap = false,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onTap: clearOnTap
            ? () {
                controller.clear();
              }
            : null,
        onChanged: (_) {
          setState(() {
            hasSearched = false;
            selectedMeasurements.clear();
            selectedMeasurement = null;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
        ),
      ),
    );
  }

  Widget _statistics(List<Measurement> data) {
    if (data.isEmpty) return const SizedBox();

    double avgL = 0;
    double avgA = 0;
    double avgB = 0;
    double avgDeltaE = 0;

    for (final m in data) {
      avgL += m.l.toDouble();
      avgA += m.a.toDouble();
      avgB += m.b.toDouble();
      avgDeltaE += m.deltaE.toDouble();
    }

    avgL /= data.length;
    avgA /= data.length;
    avgB /= data.length;
    avgDeltaE /= data.length;

    final ok = data
        .where((m) => m.status.toString().trim().toUpperCase() == 'OK')
        .length;
    final notOk = data.length - ok;

    return Row(
      children: [
        _statCard('Messungen', '${data.length}'),
        const SizedBox(width: 10),
        _statCard('i.O.', '$ok'),
        const SizedBox(width: 10),
        _statCard('n.i.O.', '$notOk'),
        const SizedBox(width: 10),
        _statCard('Ø L*', number(avgL)),
        const SizedBox(width: 10),
        _statCard('Ø a*', number(avgA)),
        const SizedBox(width: 10),
        _statCard('Ø b*', number(avgB)),
        const SizedBox(width: 10),
        _statCard('Ø ΔE*', number(avgDeltaE)),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem({
    required String label,
    required Color color,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: (_) => onTap(),
            visualDensity: VisualDensity.compact,
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toleranceLegend({
    required String label,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: (_) => onTap(),
            visualDensity: VisualDensity.compact,
          ),
          Container(
            width: 17,
            height: 2,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFB45309),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _toleranceSpots(
    List<Measurement> data,
    double? Function(Measurement) value,
  ) {
    final spots = <FlSpot>[];

    for (int index = 0; index < data.length; index++) {
      final tolerance = value(data[index]);

      if (tolerance != null && tolerance.isFinite) {
        spots.add(
          FlSpot(
            index.toDouble(),
            tolerance,
          ),
        );
      }
    }

    return spots;
  }

  List<FlSpot> _spots(List<Measurement> data, double Function(dynamic) value) {
    // Keep the chart responsive with large datasets.
    // For large selections we sample the data while preserving the first/last point.
    if (data.length <= 120) {
      return List.generate(
        data.length,
        (index) => FlSpot(index.toDouble(), value(data[index])),
      );
    }

    const maxPoints = 120;
    final step = (data.length - 1) / (maxPoints - 1);

    return List.generate(maxPoints, (index) {
      final sourceIndex = (index * step).round();
      return FlSpot(
        sourceIndex.toDouble(),
        value(data[sourceIndex]),
      );
    });
  }

  Widget _chart(List<Measurement> data) {
    if (data.isEmpty) {
      return _emptyBox(
        hasSearched
            ? 'Keine Messungen für diese Auswahl gefunden.'
            : 'Filter auswählen und „Daten aktualisieren“ ausführen.',
      );
    }

    final chartData = (selectedMeasurements.isEmpty
            ? List<Measurement>.from(data)
            : data.where((m) => selectedMeasurements.contains(m)).toList())
        ..sort(
          (a, b) =>
              (a.datum).compareTo(b.datum),
        );

    final bars = <LineChartBarData>[];

    void addSeries({
      required bool visible,
      required Color color,
      required double Function(Measurement) value,
    }) {
      if (!visible) return;

      bars.add(
        LineChartBarData(
          spots: _spots(
            chartData,
            (m) => value(m as Measurement),
          ),
          isCurved: chartData.length <= 80,
          barWidth: 2.2,
          color: color,
          dotData: FlDotData(show: chartData.length <= 80),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    void addToleranceSeries({
      required bool visible,
      required double? Function(Measurement) lowerValue,
      required double? Function(Measurement) upperValue,
    }) {
      if (!visible) return;

      final lowerSpots =
          _toleranceSpots(chartData, lowerValue);
      final upperSpots =
          _toleranceSpots(chartData, upperValue);

      if (lowerSpots.isNotEmpty) {
        bars.add(
          LineChartBarData(
            spots: lowerSpots,
            isCurved: false,
            barWidth: 1.5,
            color: const Color(0xFFB45309),
            dashArray: [6, 5],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }

      if (upperSpots.isNotEmpty) {
        bars.add(
          LineChartBarData(
            spots: upperSpots,
            isCurved: false,
            barWidth: 1.5,
            color: const Color(0xFFB45309),
            dashArray: [6, 5],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    // The measurement series are displayed as deviations from the corresponding reference.
    // Therefore, 0 always means "exactly on reference".
    addSeries(
      visible: showL,
      color: const Color(0xFF2563EB),
      value: (m) => m.deltaL.toDouble(),
    );
    addSeries(
      visible: showA,
      color: const Color(0xFFDC2626),
      value: (m) => m.deltaA.toDouble(),
    );
    addSeries(
      visible: showB,
      color: const Color(0xFF0F766E),
      value: (m) => m.deltaB.toDouble(),
    );
    addSeries(
      visible: showDeltaE,
      color: const Color(0xFF334155),
      value: (m) => m.deltaE.toDouble(),
    );

    // Colibri stores lL/uL, la/ua and lb/ub as tolerance offsets.
    // Lower limit = -lower, upper limit = +upper.
    addToleranceSeries(
      visible: showToleranceL,
      lowerValue: (m) =>
        m.lowerL == null ? null : -m.lowerL!.toDouble(),
      upperValue: (m) => m.upperL?.toDouble(),
    );

    addToleranceSeries(
      visible: showToleranceA,
      lowerValue: (m) =>
        m.lowerA == null ? null : -m.lowerA!.toDouble(),
      upperValue: (m) => m.upperA?.toDouble(),
    );

    addToleranceSeries(
      visible: showToleranceB,
      lowerValue: (m) =>
        m.lowerB == null ? null : -m.lowerB!.toDouble(),
      upperValue: (m) => m.upperB?.toDouble(),
    );

    if (showToleranceDeltaE) {
      bars.add(
        LineChartBarData(
          spots: List.generate(
            chartData.length,
            (index) => FlSpot(
              index.toDouble(),
              toleranzDeltaE,
            ),
          ),
          isCurved: false,
          barWidth: 1.5,
          color: const Color(0xFFB45309),
          dashArray: [6, 5],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    void includeValue(double value) {
      if (!value.isFinite) return;
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    for (final m in chartData) {
      if (showL) includeValue(m.deltaL.toDouble());
      if (showA) includeValue(m.deltaA.toDouble());
      if (showB) includeValue(m.deltaB.toDouble());
      if (showDeltaE) includeValue(m.deltaE.toDouble());

      if (showToleranceL) {
        if (m.lowerL != null) includeValue(-m.lowerL!.toDouble());
        if (m.upperL != null) includeValue(m.upperL!.toDouble());
      }

      if (showToleranceA) {
        if (m.lowerA != null) includeValue(-m.lowerA!.toDouble());
        if (m.upperA != null) includeValue(m.upperA!.toDouble());
      }

      if (showToleranceB) {
        if (m.lowerB != null) includeValue(-m.lowerB!.toDouble());
        if (m.upperB != null) includeValue(m.upperB!.toDouble());
      }

      if (showToleranceDeltaE) {
        includeValue(toleranzDeltaE);
      }
    }

    // 0 represents the reference and should always remain visible.
    includeValue(0);

    if (!minY.isFinite || !maxY.isFinite) {
      minY = -1;
      maxY = 1;
    }

    var range = maxY - minY;
    if (range < 0.2) range = 0.2;

    minY -= range * .12;
    maxY += range * .12;

    final maxX =
        chartData.length > 1 ? (chartData.length - 1).toDouble() : 1.0;

    String relativeAxisValue(double value) {
      if (value.abs() < 0.0005) {
        return '0';
      }

      final decimals = value.abs() < 10 ? 2 : 1;
      final formatted =
          value.abs().toStringAsFixed(decimals).replaceAll('.', ',');

      return value > 0 ? '+$formatted' : '-$formatted';
    }

    final selectedLabTolerances = [
      showToleranceL,
      showToleranceA,
      showToleranceB,
    ].where((selected) => selected).length;

    double? zoneLower;
    double? zoneUpper;

    if (selectedLabTolerances == 1) {
      final lowerValues = <double>[];
      final upperValues = <double>[];

      for (final m in chartData) {
        if (showToleranceL) {
          if (m.lowerL != null) lowerValues.add(-m.lowerL!.toDouble());
          if (m.upperL != null) upperValues.add(m.upperL!.toDouble());
        } else if (showToleranceA) {
          if (m.lowerA != null) lowerValues.add(-m.lowerA!.toDouble());
          if (m.upperA != null) upperValues.add(m.upperA!.toDouble());
        } else if (showToleranceB) {
          if (m.lowerB != null) lowerValues.add(-m.lowerB!.toDouble());
          if (m.upperB != null) upperValues.add(m.upperB!.toDouble());
        }
      }

      if (lowerValues.isNotEmpty && upperValues.isNotEmpty) {
        zoneLower = lowerValues.reduce((a, b) => a > b ? a : b);
        zoneUpper = upperValues.reduce((a, b) => a < b ? a : b);
      }
    }

    final toleranceZones = <HorizontalRangeAnnotation>[];

    // Dynamic Y-axis:
    // The scale is based on the currently visible measurement series AND
    // the actual Colibri tolerances of the respective standard.
    // There is no fixed value such as ±0.50 here.
    double niceAxisInterval(double span) {
      if (!span.isFinite || span <= 0) return 0.1;

      final roughStep = span / 6;
      final magnitude =
          math.pow(10, (math.log(roughStep) / math.ln10).floor()).toDouble();
      final normalized = roughStep / magnitude;

      double niceNormalized;
      if (normalized <= 1) {
        niceNormalized = 1;
      } else if (normalized <= 2) {
        niceNormalized = 2;
      } else if (normalized <= 2.5) {
        niceNormalized = 2.5;
      } else if (normalized <= 5) {
        niceNormalized = 5;
      } else {
        niceNormalized = 10;
      }

      return niceNormalized * magnitude;
    }

    final axisInterval = niceAxisInterval(maxY - minY);

    // Additional axis labels exactly at the active
    // Colibri tolerance limits. These limits may vary depending on the standard
    // and the selected measurement series.
    final activeToleranceLabels = <double>{};

    for (final m in chartData) {
      if (showToleranceL) {
        if (m.lowerL != null) {
          activeToleranceLabels.add(-m.lowerL!.toDouble());
        }
        if (m.upperL != null) {
          activeToleranceLabels.add(m.upperL!.toDouble());
        }
      }

      if (showToleranceA) {
        if (m.lowerA != null) {
          activeToleranceLabels.add(-m.lowerA!.toDouble());
        }
        if (m.upperA != null) {
          activeToleranceLabels.add(m.upperA!.toDouble());
        }
      }

      if (showToleranceB) {
        if (m.lowerB != null) {
          activeToleranceLabels.add(-m.lowerB!.toDouble());
        }
        if (m.upperB != null) {
          activeToleranceLabels.add(m.upperB!.toDouble());
        }
      }

      if (showToleranceDeltaE) {
        activeToleranceLabels.add(toleranzDeltaE);
      }
    }

    if (zoneLower != null && zoneUpper != null && zoneLower <= zoneUpper) {
      if (minY < zoneLower) {
        toleranceZones.add(
          HorizontalRangeAnnotation(
            y1: minY,
            y2: zoneLower,
            color: const Color(0xFFFEE2E2).withValues(alpha: 0.55),
          ),
        );
      }

      toleranceZones.add(
        HorizontalRangeAnnotation(
          y1: zoneLower,
          y2: zoneUpper,
          color: const Color(0xFFDCFCE7).withValues(alpha: 0.55),
        ),
      );

      if (maxY > zoneUpper) {
        toleranceZones.add(
          HorizontalRangeAnnotation(
            y1: zoneUpper,
            y2: maxY,
            color: const Color(0xFFFEE2E2).withValues(alpha: 0.55),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                lineBarsData: bars,
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: toleranceZones,
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0,
                      color: const Color(0xFF94A3B8),
                      strokeWidth: 1,
                      dashArray: [4, 5],
                    ),
                  ],
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  verticalInterval: chartData.length > 12
                      ? (chartData.length / 6).ceilToDouble()
                      : 1,
                  horizontalInterval: axisInterval,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (_) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Color(0xFFCBD5E1)),
                    bottom: BorderSide(color: Color(0xFFCBD5E1)),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Abweichung',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: axisInterval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          relativeAxisValue(value),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Datum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: chartData.length > 8
                          ? (chartData.length / 6).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();

                        if (index < 0 || index >= chartData.length) {
                          return const SizedBox();
                        }

                        final date = chartData[index].datum;

                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${date.day.toString().padLeft(2, '0')}.'
                            '${date.month.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final index = spot.x.round();

                        if (index < 0 || index >= chartData.length) {
                          return null;
                        }

                        final m = chartData[index];
                        final labels = <String>[];

                        if (showL) {
                          labels.add(
                            'ΔL*: ${number(m.deltaL.toDouble())}',
                          );
                        }
                        if (showA) {
                          labels.add(
                            'Δa*: ${number(m.deltaA.toDouble())}',
                          );
                        }
                        if (showB) {
                          labels.add(
                            'Δb*: ${number(m.deltaB.toDouble())}',
                          );
                        }
                        if (showDeltaE) {
                          labels.add(
                            'ΔE*: ${number(m.deltaE.toDouble())}',
                          );
                        }

                        return LineTooltipItem(
                          '${formatDateTime(m.datum)}\n'
                          '${m.artikelnummer}\n'
                          'BA-Nr.: ${m.baNr}\n'
                          '${labels.join('\n')}\n'
                          'Ergebnis: ${m.status.toString().trim().toUpperCase() == 'OK' ? 'Erfüllt' : m.status.toString().trim().toUpperCase() == 'NOK' ? 'Nicht erfüllt' : m.status}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).whereType<LineTooltipItem>().toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _legendPanel(),
        ],
      ),
    );
  }

  Widget _legendPanel() {
    return SizedBox(
      width: 150,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),

            _legendItem(
              label: 'L*',
              color: const Color(0xFF2563EB),
              checked: showL,
              onTap: () {
                setState(() {
                  showL = !showL;
                  showToleranceL = showL;
                });
              },
            ),
            _legendItem(
              label: 'a*',
              color: const Color(0xFFDC2626),
              checked: showA,
              onTap: () {
                setState(() {
                  showA = !showA;
                  showToleranceA = showA;
                });
              },
            ),
            _legendItem(
              label: 'b*',
              color: const Color(0xFF0F766E),
              checked: showB,
              onTap: () {
                setState(() {
                  showB = !showB;
                  showToleranceB = showB;
                });
              },
            ),
            _legendItem(
              label: 'ΔE*',
              color: const Color(0xFF334155),
              checked: showDeltaE,
              onTap: () => setState(() => showDeltaE = !showDeltaE),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toleranzlinien',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            _toleranceLegend(
              label: 'L* Toleranz',
              checked: showToleranceL,
              onTap: () => setState(
                () => showToleranceL = !showToleranceL,
              ),
            ),
            _toleranceLegend(
              label: 'a* Toleranz',
              checked: showToleranceA,
              onTap: () => setState(
                () => showToleranceA = !showToleranceA,
              ),
            ),
            _toleranceLegend(
              label: 'b* Toleranz',
              checked: showToleranceB,
              onTap: () => setState(
                () => showToleranceB = !showToleranceB,
              ),
            ),
            _toleranceLegend(
              label: 'ΔE* Toleranz',
              checked: showToleranceDeltaE,
              onTap: () => setState(
                () => showToleranceDeltaE = !showToleranceDeltaE,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                '0 = Bezug\nGrün = i.O.\nRot = n.i.O.\nOrange = Colibri-Toleranz',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _measurementTable(List<Measurement> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
  child: Row(
    children: [
      const Text(
        'Messungen (gefiltert)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    ],
  ),
),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (selectedMeasurements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 7, 14, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${selectedMeasurements.length} ausgewählt – Diagramm zeigt nur diese Messungen',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF155AA8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 300,
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'Keine Messungen für diese Filter gefunden.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 42,
                              child: Checkbox(
                                value: data.isNotEmpty &&
                                    data.every(
                                      (m) => selectedMeasurements.contains(m),
                                    ),
                                onChanged: data.isEmpty
                                    ? null
                                    : (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedMeasurements.addAll(data);
                                            selectedMeasurement = data.first;
                                          } else {
                                            selectedMeasurements.removeAll(data);
                                            selectedMeasurement = null;
                                          }
                                        });
                                      },
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(
                              width: 92,
                              child: Text(
                                'Datum',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 90,
                              child: Text(
                                'BA-Nr.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'L*',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'a*',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'b*',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 75,
                              child: Text(
                                'ΔE*',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'Glanz',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 110,
                              child: Text(
                                'Benutzer',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              final m = data[index];
                              final selected =
                                  selectedMeasurements.contains(m);

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      selectedMeasurements.remove(m);
                                    } else {
                                      selectedMeasurements.add(m);
                                    }
                                    selectedMeasurement = m;
                                  });
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFEFF6FF)
                                        : index.isEven
                                            ? Colors.white
                                            : const Color(0xFFFAFBFC),
                                    border: const Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 42,
                                        child: Checkbox(
                                          value: selected,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                selectedMeasurements.add(m);
                                              } else {
                                                selectedMeasurements.remove(m);
                                              }
                                              selectedMeasurement = m;
                                            });
                                          },
                                          visualDensity:
                                              VisualDensity.compact,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 92,
                                        child: Text(
                                          formatDate(m.datum),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          m.baNr.toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 65,
                                        child: Text(
                                          number(m.l.toDouble()),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 65,
                                        child: Text(
                                          number(m.a.toDouble()),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 65,
                                        child: Text(
                                          number(m.b.toDouble()),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 75,
                                        child: Text(
                                          number(m.deltaE.toDouble()),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 65,
                                        child: Text(
                                          '-',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          m.benutzer.toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Text(
              hasSearched
                  ? '${data.length} Messungen'
                  : 'Keine Messungen angezeigt – Suche ausführen',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsPanel(dynamic m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details der ausgewählten Messung',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${selectedMeasurements.length} Messung(en) ausgewählt',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('Datum', formatDateTime(m.datum as DateTime)),
          _detailRow('Artikelnummer', m.artikelnummer.toString()),
          _detailRow('BA-Nr.', m.baNr.toString()),
          _detailRow('L*', number(m.l.toDouble())),
          _detailRow('a*', number(m.a.toDouble())),
          _detailRow('b*', number(m.b.toDouble())),
          _detailRow('ΔE*', number(m.deltaE.toDouble())),
          _detailRow(
            'Glanz',
            '-',
          ),
          _detailRow('Benutzer', m.benutzer.toString()),
          _detailRow(
            'Ergebnis',
            m.status.toString().trim().toUpperCase() == 'OK'
                ? 'Erfüllt'
                : m.status.toString().trim().toUpperCase() == 'NOK'
                    ? 'Nicht erfüllt'
                    : m.status.toString(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessungsdetailsPage(
                      measurement: m,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 17),
              label: const Text('Details anzeigen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDCE8F7),
                foregroundColor: const Color(0xFF164E80),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _header(List<Measurement> data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trends analysieren',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Entwicklung einer Farbeigenschaft über die Zeit',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _filterTextField(
                  label: 'Artikelnummer',
                  controller: artikelController,
                ),
                _filterTextField(
                  label: 'BA-Nr.',
                  controller: baNrController,
                ),
                _filterTextField(
                  label: 'Von',
                  controller: vonController,
                  width: 150,
                  hintText: 'TT.MM.JJJJ',
                  clearOnTap: true,
                ),
                _filterTextField(
                  label: 'Bis',
                  controller: bisController,
                  width: 150,
                  hintText: 'TT.MM.JJJJ',
                  clearOnTap: true,
                ),
                _filterTextField(
                  label: 'Benutzer',
                  controller: benutzerController,
                ),
                _filterDropdown(
                  label: 'Ergebnis',
                  value: selectedErgebnis,
                  items: const ['Alle', 'erfüllt', 'nicht erfüllt'],
                  onChanged: (v) {
                    setState(() {
                      selectedErgebnis = v ?? 'Alle';
                      hasSearched = false;
                      selectedMeasurements.clear();
                      selectedMeasurement = null;
                    });
                  },
                ),
                
                ElevatedButton.icon(
                  onPressed: () {
                    if (!_applyDateInputs()) {
                      return;
                    }
                
                    final results = filteredMeasurements;
                
                    setState(() {
                      hasSearched = true;
                      selectedMeasurements.clear();
                      selectedMeasurement =
                          results.isNotEmpty ? results.first : null;
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Suchen / aktualisieren'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155AA8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: resetFilters,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Zurücksetzen'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearched
                ? '${data.length} Messungen'
                : 'Keine Suche ausgeführt',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = displayedMeasurements;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AppSidebar(
            selectedPage: 'Analyse',
            onDashboard: () {
              Navigator.popUntil(
                context,
                (route) => route.isFirst,
              );
            },
            onMessungen: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessungenPage(
                    measurements: widget.measurements,
                    projectGroups: widget.projectGroups,
                  ),
                ),
              );
            },
            onFragAI: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FragAIPage(
                    measurements: widget.measurements,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Column(
              children: [
                _header(data),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farbwerte im Zeitverlauf',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 450,
                          child: _chart(data),
                        ),
                        const SizedBox(height: 16),
                        _statistics(data),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 1050;

                            if (narrow) {
                              return Column(
                                children: [
                                  _measurementTable(data),
                                  const SizedBox(height: 14),
                                  selectedMeasurement == null
                                      ? _emptyBox(
                                          'Messung auswählen, um Details zu sehen.',
                                        )
                                      : _detailsPanel(selectedMeasurement),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _measurementTable(data),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 3,
                                  child: selectedMeasurement == null
                                      ? _emptyBox(
                                          'Messung auswählen, um Details zu sehen.',
                                        )
                                      : _detailsPanel(selectedMeasurement),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
