import 'package:flutter/material.dart';
import '../models/measurement.dart';

class MessungsdetailsPage extends StatelessWidget {
  final dynamic measurement;

  const MessungsdetailsPage({
    super.key,
    required this.measurement,
  });

  // ============================================================
  // BEZUG / REFERENZ
  // ============================================================

  double get bezugL => measurement.standardL.toDouble();
  double get bezugA => measurement.standardA.toDouble();
  double get bezugB => measurement.standardB.toDouble();

  // IMPORTANTE:
  // Os valores do Colibri são TOLERÂNCIAS.
  //
  // Exemplo:
  // Standard a* = -0.22
  // la = 0.30
  // ua = 0.30
  //
  // => limite inferior = -0.22 - 0.30
  // => limite superior = -0.22 + 0.30

  double? get toleranzL => measurement.lowerL?.toDouble();
  double? get toleranzLUpper =>
      measurement.upperL?.toDouble();

  double? get toleranzA => measurement.lowerA?.toDouble();
  double? get toleranzAUpper =>
      measurement.upperA?.toDouble();

  double? get toleranzB => measurement.lowerB?.toDouble();
  double? get toleranzBUpper =>
      measurement.upperB?.toDouble();

  double? get lowerL {
    if (toleranzL == null) return null;
    return bezugL - toleranzL!;
  }

  double? get upperL {
    if (toleranzLUpper == null) return null;
    return bezugL + toleranzLUpper!;
  }

  double? get lowerA {
    if (toleranzA == null) return null;
    return bezugA - toleranzA!;
  }

  double? get upperA {
    if (toleranzAUpper == null) return null;
    return bezugA + toleranzAUpper!;
  }

  double? get lowerB {
    if (toleranzB == null) return null;
    return bezugB - toleranzB!;
  }

  double? get upperB {
    if (toleranzBUpper == null) return null;
    return bezugB + toleranzBUpper!;
  }

  String formatDate(DateTime date) {
    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${twoDigits(date.day)}.'
        '${twoDigits(date.month)}.'
        '${date.year} '
        '${twoDigits(date.hour)}:'
        '${twoDigits(date.minute)}';
  }

  // ============================================================
  // TOLERANZPRÜFUNG
  // ============================================================

  bool isLWithinTolerance() {
    final double value = measurement.l.toDouble();

    if (lowerL == null || upperL == null) {
      return true;
    }

    return value >= lowerL! && value <= upperL!;
  }

  bool isAWithinTolerance() {
    final double value = measurement.a.toDouble();

    if (lowerA == null || upperA == null) {
      return true;
    }

    return value >= lowerA! && value <= upperA!;
  }

  bool isBWithinTolerance() {
    final double value = measurement.b.toDouble();

    if (lowerB == null || upperB == null) {
      return true;
    }

    return value >= lowerB! && value <= upperB!;
  }

  bool isMeasurementWithinTolerance() {
    return isLWithinTolerance() &&
        isAWithinTolerance() &&
        isBWithinTolerance();
  }

  // ============================================================
  // TOLERANZ-DARSTELLUNG
  // ============================================================

  String formatTolerance(
    double standard,
    double? lowerTolerance,
    double? upperTolerance,
  ) {
    if (lowerTolerance == null ||
        upperTolerance == null) {
      return standard.toStringAsFixed(2);
    }

    final bool symmetric =
        (lowerTolerance! - upperTolerance!).abs() < 0.0001;

    if (symmetric) {
      return '${standard.toStringAsFixed(2)} ± '
          '${lowerTolerance!.abs().toStringAsFixed(2)}';
    }

    return '${standard.toStringAsFixed(2)} '
        '(-${lowerTolerance!.toStringAsFixed(2)} / '
        '+${upperTolerance!.toStringAsFixed(2)})';
  }

  String formatRange(
    double? lower,
    double? upper,
  ) {
    if (lower == null || upper == null) {
      return 'Keine Toleranz hinterlegt';
    }

    return '${lower.toStringAsFixed(2)} – '
        '${upper.toStringAsFixed(2)}';
  }

  // ============================================================
  // ALLGEMEINE DETAILZEILE
  // ============================================================

  Widget detailRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlight
                    ? (value == 'Erfüllt'
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B))
                    : const Color(0xFF0F172A),
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT BADGE
  // ============================================================

  Widget resultBadge() {
    final bool erfuellt = isMeasurementWithinTolerance();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: erfuellt
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        erfuellt ? 'Erfüllt' : 'Nicht erfüllt',
        style: TextStyle(
          color: erfuellt
              ? const Color(0xFF166534)
              : const Color(0xFF991B1B),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  // ============================================================
  // MESSWERTE
  // ============================================================

  Widget measurementValuesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              8,
            ),
            child: Text(
              'Messwerte',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          detailRow(
            'L*',
            measurement.l.toStringAsFixed(2),
          ),
          detailRow(
            'a*',
            measurement.a.toStringAsFixed(2),
          ),
          detailRow(
            'b*',
            measurement.b.toStringAsFixed(2),
          ),
          detailRow(
            'ΔL*',
            measurement.deltaL.toStringAsFixed(2),
          ),
          detailRow(
            'Δa*',
            measurement.deltaA.toStringAsFixed(2),
          ),
          detailRow(
            'Δb*',
            measurement.deltaB.toStringAsFixed(2),
          ),
          detailRow(
            'ΔE*',
            measurement.deltaE.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BEZUG
  // ============================================================

  Widget referenceValuesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              8,
            ),
            child: Text(
              'Bezug',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          detailRow(
            'Name',
            measurement.bezug.toString(),
          ),
          detailRow(
            'L*',
            formatTolerance(
              bezugL,
              toleranzL,
              toleranzLUpper,
            ),
          ),
          detailRow(
            'a*',
            formatTolerance(
              bezugA,
              toleranzA,
              toleranzAUpper,
            ),
          ),
          detailRow(
            'b*',
            formatTolerance(
              bezugB,
              toleranzB,
              toleranzBUpper,
            ),
          ),
          detailRow(
            'L*-Bereich',
            formatRange(
              lowerL,
              upperL,
            ),
          ),
          detailRow(
            'a*-Bereich',
            formatRange(
              lowerA,
              upperA,
            ),
          ),
          detailRow(
            'b*-Bereich',
            formatRange(
              lowerB,
              upperB,
            ),
          ),      
        ],
      ),
    );
  }

  // ============================================================
  // CIELAB GRAFIK
  // ============================================================

  Widget labChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CIELAB Position',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'a* / b* und Helligkeit L* im Verhältnis zum Bezugsbereich',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: LabChartPainter(
                l: measurement.l.toDouble(),
                a: measurement.a.toDouble(),
                b: measurement.b.toDouble(),
                bezugL: bezugL,
                bezugA: bezugA,
                bezugB: bezugB,
                lowerL: lowerL,
                upperL: upperL,
                lowerA: lowerA,
                upperA: upperA,
                lowerB: lowerB,
                upperB: upperB,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LAYOUT
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final DateTime datum = measurement.datum;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF0F172A),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Messungsdetails',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          measurement.artikelnummer.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          measurement.name.toString(),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  resultBadge(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ALLGEMEINE INFORMATIONEN
            // ==================================================

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      8,
                    ),
                    child: Text(
                      'Allgemeine Informationen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  detailRow(
                    'Artikelnummer',
                    measurement.artikelnummer.toString(),
                  ),
                  detailRow(
                    'Name',
                    measurement.name.toString(),
                  ),
                  detailRow(
                    'Datum',
                    formatDate(datum),
                  ),
                  detailRow(
                    'Benutzer',
                    measurement.benutzer.toString(),                
                  ),
                  detailRow(
                    'BA-Nr.',
                    measurement.baNr.toString(),
                  ),
                  detailRow(
                    'Ergebnis',
                    isMeasurementWithinTolerance()
                        ? 'Erfüllt'
                        : 'Nicht erfüllt',
                    highlight: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // MESSWERTE + BEZUG + GRAFIK
            // ==================================================

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1100) {
                  return Column(
                    children: [
                      measurementValuesCard(),
                      const SizedBox(height: 20),
                      referenceValuesCard(),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 520,
                        child: labChartCard(),
                      ),
                    ],
                  );
                }

                return SizedBox(
                  height: 650,
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: measurementValuesCard(),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: referenceValuesCard(),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 6,
                        child: labChartCard(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CIELAB PAINTER
// ================================================================

class LabChartPainter extends CustomPainter {
  final double l;
  final double a;
  final double b;

  final double bezugL;
  final double bezugA;
  final double bezugB;

  final double? lowerL;
  final double? upperL;

  final double? lowerA;
  final double? upperA;

  final double? lowerB;
  final double? upperB;

  LabChartPainter({
    required this.l,
    required this.a,
    required this.b,
    required this.bezugL,
    required this.bezugA,
    required this.bezugB,
    this.lowerL,
    this.upperL,
    this.lowerA,
    this.upperA,
    this.lowerB,
    this.upperB,
  });

  double mapValue(
    double value,
    double min,
    double max,
    double start,
    double end,
  ) {
    if (max == min) {
      return (start + end) / 2;
    }

    return start +
        ((value - min) / (max - min)) *
            (end - start);
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const double leftPadding = 60;
    const double rightPadding = 130;
    const double topPadding = 42;
    const double bottomPadding = 58;

    final double left = leftPadding;
    final double right = size.width - rightPadding;
    final double top = topPadding;
    final double bottom = size.height - bottomPadding;

    final double chartWidth = right - left;
    final double chartHeight = bottom - top;

    // ==========================================================
    // REAL TOLERANCE LIMITS
    // ==========================================================

    final double aLower =
        lowerA ?? (bezugA - 0.5);

    final double aUpper =
        upperA ?? (bezugA + 0.5);

    final double bLower =
        lowerB ?? (bezugB - 0.5);

    final double bUpper =
        upperB ?? (bezugB + 0.5);

    final double lLower =
        lowerL ?? (bezugL - 0.5);

    final double lUpper =
        upperL ?? (bezugL + 0.5);

    // ==========================================================
    // CHART RANGE
    //
    // A caixa verde representa a tolerância.
    // O resto do gráfico é espaço adicional à volta da caixa.
    // ==========================================================

    final double aToleranceRange =
        (aUpper - aLower).abs();

    final double bToleranceRange =
        (bUpper - bLower).abs();

    final double lToleranceRange =
        (lUpper - lLower).abs();

    final double aPadding =
        aToleranceRange > 0
            ? aToleranceRange * 1.5
            : 1.0;

    final double bPadding =
        bToleranceRange > 0
            ? bToleranceRange * 1.5
            : 1.0;

    final double lPadding =
        lToleranceRange > 0
            ? lToleranceRange * 1.5
            : 1.0;

    final double xMin =
        aLower - aPadding;

    final double xMax =
        aUpper + aPadding;

    final double yMin =
        bLower - bPadding;

    final double yMax =
        bUpper + bPadding;

    final double lMin =
        lLower - lPadding;

    final double lMax =
        lUpper + lPadding;

    // ==========================================================
    // PAINTS
    // ==========================================================

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE2E8F0);

    final Paint gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFF1F5F9);

    final Paint axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF94A3B8);

    // ==========================================================
    // TOLERANCE BOX
    // ==========================================================

    final Paint tolerancePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFDCFCE7);

    final Paint toleranceBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF86EFAC);

    // ==========================================================
    // AXIS COLOURS
    // ==========================================================

    final Paint positiveATint = Paint()
      ..color = const Color(0xFFFECACA);

    final Paint negativeATint = Paint()
      ..color = const Color(0xFFDCFCE7);

    final Paint positiveBTint = Paint()
      ..color = const Color(0xFFFEF08A);

    final Paint negativeBTint = Paint()
      ..color = const Color(0xFFBFDBFE);

    // ==========================================================
    // SEPARATE PRÜFUNG
    // ==========================================================

    final bool lInside =
        l >= lLower &&
        l <= lUpper;

    final bool aInside =
        a >= aLower &&
        a <= aUpper;

    final bool bInside =
        b >= bLower &&
        b <= bUpper;

    final bool abInside =
        aInside && bInside;

    // ==========================================================
    // MESSUNGSPUNKT
    // ==========================================================

    final Color abPointColor;

    if (!abInside) {
      abPointColor =
          const Color(0xFFDC2626);
    } else if (!lInside) {
      abPointColor = Colors.white;
    } else {
      abPointColor =
          const Color(0xFF16A34A);
    }

    final Paint measurementPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = abPointColor;

    final Paint measurementBorderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color =
              (!abInside || !lInside)
                  ? const Color(0xFFDC2626)
                  : Colors.white;

    final Paint referencePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF475569);

    final Paint referenceLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF475569);

    // ==========================================================
    // HINTERGRUND
    // ==========================================================

    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFFFCFDFE);

    canvas.drawRect(
      Rect.fromLTRB(
        left,
        top,
        right,
        bottom,
      ),
      backgroundPaint,
    );

    canvas.drawRect(
      Rect.fromLTRB(
        left,
        top,
        right,
        bottom,
      ),
      borderPaint,
    );

    // ==========================================================
    // COLOURED AXIS BANDS
    // ==========================================================

    const double axisColorSize = 12;

    // +b*
    canvas.drawRect(
      Rect.fromLTRB(
        left,
        top - axisColorSize,
        right,
        top,
      ),
      positiveBTint,
    );

    // -b*
    canvas.drawRect(
      Rect.fromLTRB(
        left,
        bottom,
        right,
        bottom + axisColorSize,
      ),
      negativeBTint,
    );

    // -a*
    canvas.drawRect(
      Rect.fromLTRB(
        left - axisColorSize,
        top,
        left,
        bottom,
      ),
      negativeATint,
    );

    // +a*
    canvas.drawRect(
      Rect.fromLTRB(
        right,
        top,
        right + axisColorSize,
        bottom,
      ),
      positiveATint,
    );

    // ==========================================================
    // GRID
    // ==========================================================

    const int gridCount = 5;

    for (int i = 0; i <= gridCount; i++) {
      final double x =
          left +
          (chartWidth / gridCount) * i;

      final double y =
          top +
          (chartHeight / gridCount) * i;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        gridPaint,
      );

      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        gridPaint,
      );
    }

    // ==========================================================
    // BEZUG POSITION
    // ==========================================================

    final double referenceX = mapValue(
      bezugA,
      xMin,
      xMax,
      left,
      right,
    );

    final double referenceY = mapValue(
      bezugB,
      yMin,
      yMax,
      bottom,
      top,
    );

    canvas.drawLine(
      Offset(referenceX, top),
      Offset(referenceX, bottom),
      axisPaint,
    );

    canvas.drawLine(
      Offset(left, referenceY),
      Offset(right, referenceY),
      axisPaint,
    );

    // ==========================================================
    // TOLERANCE BOX
    // ==========================================================

    final double toleranceLeft =
        mapValue(
      aLower,
      xMin,
      xMax,
      left,
      right,
    );

    final double toleranceRight =
        mapValue(
      aUpper,
      xMin,
      xMax,
      left,
      right,
    );

    final double toleranceTop =
        mapValue(
      bUpper,
      yMin,
      yMax,
      bottom,
      top,
    );

    final double toleranceBottom =
        mapValue(
      bLower,
      yMin,
      yMax,
      bottom,
      top,
    );

    final Rect toleranceRect =
        Rect.fromLTRB(
      toleranceLeft,
      toleranceTop,
      toleranceRight,
      toleranceBottom,
    );

    canvas.drawRect(
      toleranceRect,
      tolerancePaint,
    );

    canvas.drawRect(
      toleranceRect,
      toleranceBorderPaint,
    );

    // ==========================================================
    // BEZUG PUNKT
    // ==========================================================

    canvas.drawCircle(
      Offset(
        referenceX,
        referenceY,
      ),
      6,
      referencePaint,
    );

    canvas.drawLine(
      Offset(
        referenceX - 10,
        referenceY,
      ),
      Offset(
        referenceX + 10,
        referenceY,
      ),
      referenceLinePaint,
    );

    canvas.drawLine(
      Offset(
        referenceX,
        referenceY - 10,
      ),
      Offset(
        referenceX,
        referenceY + 10,
      ),
      referenceLinePaint,
    );

    // ==========================================================
    // MESSUNGSPUNKT
    // ==========================================================

    final double measurementX =
        mapValue(
      a,
      xMin,
      xMax,
      left,
      right,
    );

    final double measurementY =
        mapValue(
      b,
      yMin,
      yMax,
      bottom,
      top,
    );

    canvas.drawCircle(
      Offset(
        measurementX,
        measurementY,
      ),
      10,
      measurementPaint,
    );

    canvas.drawCircle(
      Offset(
        measurementX,
        measurementY,
      ),
      10,
      measurementBorderPaint,
    );

    // ==========================================================
    // LABEL MESSUNG
    // ==========================================================

    final String abLabelText;

    if (!abInside) {
      abLabelText = 'Messung';
    } else if (!lInside) {
      abLabelText = 'Messung';
    } else {
      abLabelText = 'Messung';
    }

    final Color abLabelColor;

    if (!abInside) {
      abLabelColor =
          const Color(0xFF991B1B);
    } else if (!lInside) {
      abLabelColor =
          const Color(0xFF475569);
    } else {
      abLabelColor =
          const Color(0xFF166534);
    }

    final TextPainter measurementLabel =
        TextPainter(
      text: TextSpan(
        text: abLabelText,
        style: TextStyle(
          color: abLabelColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double labelX =
        measurementX + 14;

    if (labelX +
            measurementLabel.width >
        right) {
      labelX =
          measurementX -
          measurementLabel.width -
          14;
    }

    double labelY =
        measurementY -
        measurementLabel.height -
        12;

    if (labelY < top) {
      labelY =
          measurementY + 12;
    }

    measurementLabel.paint(
      canvas,
      Offset(
        labelX,
        labelY,
      ),
    );

    // ==========================================================
    // LABEL BEZUG
    // ==========================================================

    final TextPainter bezugLabel =
        TextPainter(
      text: const TextSpan(
        text: 'Bezug',
        style: TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    bezugLabel.paint(
      canvas,
      Offset(
        referenceX + 10,
        referenceY + 10,
      ),
    );

    // ==========================================================
    // AXIS LABELS
    //
    // Mostrar tolerâncias relativas ao Bezug:
    // a*: tolerância inferior / 0 / tolerância superior
    // b*: tolerância inferior / 0 / tolerância superior
    //
    // Os valores absolutos continuam a ser usados internamente
    // para calcular as posições no gráfico.
    // ==========================================================

    const TextStyle axisTextStyle =
        TextStyle(
      color: Color(0xFF64748B),
      fontSize: 11,
    );

    final List<double> xLabels = [
      aLower,
      bezugA,
      aUpper,
    ];

    final List<double> yLabels = [
      bLower,
      bezugB,
      bUpper,
    ];

    // ==========================================================
    // a* TOLERANZ-LABELS
    // ==========================================================

    for (final value in xLabels) {
      final double x =
          mapValue(
        value,
        xMin,
        xMax,
        left,
        right,
      );

      final double displayedValue =
          value - bezugA;

      final String label =
          displayedValue.abs() < 0.0001
              ? '0'
              : '${displayedValue > 0 ? '+' : ''}'
                  '${displayedValue.toStringAsFixed(2)}';

      final TextPainter painter =
          TextPainter(
        text: TextSpan(
          text: label,
          style: axisTextStyle,
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          x - painter.width / 2,
          bottom + 8,
        ),
      );
    }

    // ==========================================================
    // b* TOLERANZ-LABELS
    // ==========================================================

    for (final value in yLabels) {
      final double y =
          mapValue(
        value,
        yMin,
        yMax,
        bottom,
        top,
      );

      final double displayedValue =
          value - bezugB;

      final String label =
          displayedValue.abs() < 0.0001
              ? '0'
              : '${displayedValue > 0 ? '+' : ''}'
                  '${displayedValue.toStringAsFixed(2)}';

      final TextPainter painter =
          TextPainter(
        text: TextSpan(
          text: label,
          style: axisTextStyle,
        ),
        textDirection:
            TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          left -
              painter.width -
              8,
          y -
              painter.height / 2,
        ),
      );
    }

    // ==========================================================
    // ACHSENTITEL
    // ==========================================================

    final TextPainter aTitle =
        TextPainter(
      text: const TextSpan(
        text: 'a*',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    aTitle.paint(
      canvas,
      Offset(
        right - aTitle.width,
        bottom + 30,
      ),
    );

    final TextPainter bTitle =
        TextPainter(
      text: const TextSpan(
        text: 'b*',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    bTitle.paint(
      canvas,
      Offset(
        left -
            bTitle.width -
            8,
        top - 22,
      ),
    );

    // ==========================================================
    // L* / HELLIGKEIT
    // ==========================================================

    final double gaugeLeft =
        right + 28;

    final double gaugeRight =
        gaugeLeft + 24;

    final double gaugeTop =
        top;

    final double gaugeBottom =
        bottom;

    final Paint gaugeBackgroundPaint =
        Paint()
          ..color =
              const Color(0xFFF1F5F9);

    final Paint gaugeBorderPaint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1
          ..color =
              const Color(0xFFE2E8F0);

    final Paint gaugeTolerancePaint =
        Paint()
          ..color =
              const Color(0xFFDCFCE7);

    final Paint gaugeToleranceBorderPaint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color =
              const Color(0xFF86EFAC);

    final Paint gaugeReferencePaint =
        Paint()
          ..color =
              const Color(0xFF475569);

    final Paint gaugeMeasurementPaint =
        Paint()
          ..color = lInside
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626);

    final Rect gaugeRect =
        Rect.fromLTRB(
      gaugeLeft,
      gaugeTop,
      gaugeRight,
      gaugeBottom,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        gaugeRect,
        const Radius.circular(12),
      ),
      gaugeBackgroundPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        gaugeRect,
        const Radius.circular(12),
      ),
      gaugeBorderPaint,
    );

    // ==========================================================
    // L* TOLERANCE
    // ==========================================================

    final double toleranceLTop =
        mapValue(
      lUpper,
      lMin,
      lMax,
      gaugeBottom,
      gaugeTop,
    );

    final double toleranceLBottom =
        mapValue(
      lLower,
      lMin,
      lMax,
      gaugeBottom,
      gaugeTop,
    );

    final Rect lToleranceRect =
        Rect.fromLTRB(
      gaugeLeft + 2,
      toleranceLTop,
      gaugeRight - 2,
      toleranceLBottom,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        lToleranceRect,
        const Radius.circular(8),
      ),
      gaugeTolerancePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        lToleranceRect,
        const Radius.circular(8),
      ),
      gaugeToleranceBorderPaint,
    );

    // ==========================================================
    // BEZUG L*
    // ==========================================================

    final double referenceLPosition =
        mapValue(
      bezugL,
      lMin,
      lMax,
      gaugeBottom,
      gaugeTop,
    );

    canvas.drawLine(
      Offset(
        gaugeLeft - 6,
        referenceLPosition,
      ),
      Offset(
        gaugeRight + 6,
        referenceLPosition,
      ),
      gaugeReferencePaint,
    );

    // ==========================================================
    // MESSUNG L*
    // ==========================================================

    final double measurementLPosition =
        mapValue(
      l.clamp(
        lMin,
        lMax,
      ),
      lMin,
      lMax,
      gaugeBottom,
      gaugeTop,
    );

    final Offset measurementLOffset =
        Offset(
      gaugeLeft +
          ((gaugeRight -
                  gaugeLeft) /
              2),
      measurementLPosition,
    );

    canvas.drawCircle(
      measurementLOffset,
      8,
      gaugeMeasurementPaint,
    );

    canvas.drawCircle(
      measurementLOffset,
      8,
      measurementBorderPaint,
    );

    // ==========================================================
    // L* TITEL
    // ==========================================================

    final TextPainter lTitle =
        TextPainter(
      text: const TextSpan(
        text: 'L*',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    lTitle.paint(
      canvas,
      Offset(
        gaugeLeft,
        top - 24,
      ),
    );

    final TextPainter helligkeitTitle =
        TextPainter(
      text: const TextSpan(
        text: 'Helligkeit',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    helligkeitTitle.paint(
      canvas,
      Offset(
        gaugeLeft +
            lTitle.width +
            6,
        top - 24,
      ),
    );

    // ==========================================================
    // L* TOLERANZ-SKALA
    //
    // Mostrar apenas:
    // tolerância superior / 0 / tolerância inferior
    //
    // lMin e lMax continuam a ser usados apenas internamente
    // para posicionar corretamente a medição.
    // ==========================================================

    final double lUpperTolerance =
        lUpper - bezugL;

    final double lLowerTolerance =
        lLower - bezugL;

    final TextPainter lToleranceTopLabel =
        TextPainter(
      text: TextSpan(
        text:
            '+${lUpperTolerance.abs().toStringAsFixed(2)}',
        style: const TextStyle(
          color: Color(0xFF166534),
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    lToleranceTopLabel.paint(
      canvas,
      Offset(
        gaugeRight + 10,
        toleranceLTop - 7,
      ),
    );

    final TextPainter lReferenceLabel =
        TextPainter(
      text: const TextSpan(
        text: '0',
        style: TextStyle(
          color: Color(0xFF475569),
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    lReferenceLabel.paint(
      canvas,
      Offset(
        gaugeRight + 10,
        referenceLPosition - 7,
      ),
    );

    final TextPainter lToleranceBottomLabel =
        TextPainter(
      text: TextSpan(
        text:
            '-${lLowerTolerance.abs().toStringAsFixed(2)}',
        style: const TextStyle(
          color: Color(0xFF166534),
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    lToleranceBottomLabel.paint(
      canvas,
      Offset(
        gaugeRight + 10,
        toleranceLBottom - 7,
      ),
    );

    // ==========================================================
    // LEGEND
    // ==========================================================

    final double legendY =
        size.height - 18;

    final Paint greenLegend =
        Paint()
          ..color =
              const Color(0xFF16A34A);

    final Paint redLegend =
        Paint()
          ..color =
              const Color(0xFFDC2626);

    final Paint greyLegend =
        Paint()
          ..color =
              const Color(0xFF475569);

    final Paint whiteLegend =
        Paint()
          ..color = Colors.white;

    final Paint whiteLegendBorder =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1
          ..color =
              const Color(0xFFDC2626);

    canvas.drawCircle(
      Offset(
        left + 6,
        legendY,
      ),
      5,
      greenLegend,
    );

    final TextPainter measurementLegend =
        TextPainter(
      text: TextSpan(
        text: 'Messung i.O.',
        style: axisTextStyle,
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    measurementLegend.paint(
      canvas,
      Offset(
        left + 16,
        legendY - 7,
      ),
    );

    canvas.drawCircle(
      Offset(
        left + 116,
        legendY,
      ),
      5,
      redLegend,
    );

    final TextPainter notOkLegend =
        TextPainter(
      text: TextSpan(
        text: 'Messung n.i.O.',
        style: axisTextStyle,
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    notOkLegend.paint(
      canvas,
      Offset(
        left + 126,
        legendY - 7,
      ),
    );

    canvas.drawCircle(
      Offset(
        left + 230,
        legendY,
      ),
      5,
      whiteLegend,
    );

    canvas.drawCircle(
      Offset(
        left + 230,
        legendY,
      ),
      5,
      whiteLegendBorder,
    );

    final TextPainter whiteLegendText =
        TextPainter(
      text: TextSpan(
        text:
            'Farbe oder Helligkeit n.i.O',
        style: axisTextStyle,
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    whiteLegendText.paint(
      canvas,
      Offset(
        left + 240,
        legendY - 7,
      ),
    );

    canvas.drawCircle(
      Offset(
        left + 390,
        legendY,
      ),
      5,
      greyLegend,
    );

    final TextPainter referenceLegend =
        TextPainter(
      text: TextSpan(
        text: 'Bezug',
        style: axisTextStyle,
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    referenceLegend.paint(
      canvas,
      Offset(
        left + 400,
        legendY - 7,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant LabChartPainter oldDelegate,
  ) {
    return oldDelegate.l != l ||
        oldDelegate.a != a ||
        oldDelegate.b != b ||
        oldDelegate.bezugL != bezugL ||
        oldDelegate.bezugA != bezugA ||
        oldDelegate.bezugB != bezugB ||
        oldDelegate.lowerL != lowerL ||
        oldDelegate.upperL != upperL ||
        oldDelegate.lowerA != lowerA ||
        oldDelegate.upperA != upperA ||
        oldDelegate.lowerB != lowerB ||
        oldDelegate.upperB != upperB;
  }
}