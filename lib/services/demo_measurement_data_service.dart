import 'dart:math';

import '../models/measurement.dart';

class DemoMeasurementService {
  // ============================================================
  // DEMO-MESSUNGEN LADEN
  // ============================================================

  Future<List<Measurement>> getMeasurements() async {
    final measurements = <Measurement>[];

    final articles = [
      const _DemoArticle(
        artikelnummer: '482731',
        name: 'Cover Panel',
        bezug: 'Standard White A',
        standardSampleOid: 'DEMO-STD-001',
        standardL: 94.20,
        standardA: -0.35,
        standardB: 1.12,
        lowerL: 0.80,
        upperL: 0.80,
        lowerA: 0.40,
        upperA: 0.40,
        lowerB: 0.40,
        upperB: 0.40,
        glossBase: 2.50,
      ),
      const _DemoArticle(
        artikelnummer: '517204',
        name: 'Interior Trim',
        bezug: 'Standard Black A',
        standardSampleOid: 'DEMO-STD-002',
        standardL: 25.40,
        standardA: 0.18,
        standardB: -0.42,
        lowerL: 1.00,
        upperL: 1.00,
        lowerA: 0.50,
        upperA: 0.50,
        lowerB: 0.50,
        upperB: 0.50,
        glossBase: 4.00,
      ),
      const _DemoArticle(
        artikelnummer: '631845',
        name: 'Side Cover',
        bezug: 'Standard Grey A',
        standardSampleOid: 'DEMO-STD-003',
        standardL: 58.70,
        standardA: -0.12,
        standardB: 0.35,
        lowerL: 0.90,
        upperL: 0.90,
        lowerA: 0.45,
        upperA: 0.45,
        lowerB: 0.45,
        upperB: 0.45,
      ),
      const _DemoArticle(
        artikelnummer: '704216',
        name: 'Decorative Insert',
        bezug: 'Standard Silver A',
        standardSampleOid: 'DEMO-STD-004',
        standardL: 72.10,
        standardA: 0.08,
        standardB: 1.45,
        lowerL: 1.20,
        upperL: 1.20,
        lowerA: 0.60,
        upperA: 0.60,
        lowerB: 0.60,
        upperB: 0.60,
        glossBase: 6.50,
      ),
      const _DemoArticle(
        artikelnummer: '825390',
        name: 'Control Housing',
        bezug: 'Standard Anthracite A',
        standardSampleOid: 'DEMO-STD-005',
        standardL: 34.80,
        standardA: 0.22,
        standardB: -0.18,
        lowerL: 0.75,
        upperL: 0.75,
        lowerA: 0.35,
        upperA: 0.35,
        lowerB: 0.35,
        upperB: 0.35,
      ),
      const _DemoArticle(
        artikelnummer: '936142',
        name: 'Upper Console',
        bezug: 'Standard Blue A',
        standardSampleOid: 'DEMO-STD-006',
        standardL: 42.30,
        standardA: -1.15,
        standardB: -4.80,
        lowerL: 1.00,
        upperL: 1.00,
        lowerA: 0.55,
        upperA: 0.55,
        lowerB: 0.70,
        upperB: 0.70,
        glossBase: 3.20,
      ),
    ];

    // Fixed seed = same demo data on every run.
    final random = Random(42);

    final startDate = DateTime(2025, 1, 1);
    final today = DateTime.now();

    final totalDays = today.difference(startDate).inDays;

    if (totalDays < 0) {
      return measurements;
    }

    const measurementCount = 2500;

    for (var i = 0; i < measurementCount; i++) {
      final article = articles[i % articles.length];

      final dayOffset = random.nextInt(totalDays + 1);

      final datum = startDate.add(
        Duration(
          days: dayOffset,
          hours: 6 + random.nextInt(12),
          minutes: random.nextInt(60),
          seconds: random.nextInt(60),
        ),
      );

      // Several measurements belong to the same production order.
      final baGroup = i ~/ 12;

      final baNr =
          (50000 + baGroup).toString();

      // Some production orders deliberately contain more deviations
      // so that NOK analysis and rankings are meaningful.
      final problematicBa =
          baGroup % 11 == 0;

      final spread =
          problematicBa ? 1.45 : 0.65;

      final deltaL = _signedVariation(
        random,
        article.upperL * spread,
      );

      final deltaA = _signedVariation(
        random,
        article.upperA * spread,
      );

      final deltaB = _signedVariation(
        random,
        article.upperB * spread,
      );

      final l =
          article.standardL + deltaL;

      final a =
          article.standardA + deltaA;

      final b =
          article.standardB + deltaB;

      final deltaE = _calculateDeltaE(
        deltaL,
        deltaA,
        deltaB,
      );

      final gloss = article.glossBase == null
          ? null
          : article.glossBase! +
              _signedVariation(
                random,
                0.30,
              );

      final status = _calculateStatus(
        deltaL: deltaL,
        deltaA: deltaA,
        deltaB: deltaB,
        lowerL: article.lowerL,
        upperL: article.upperL,
        lowerA: article.lowerA,
        upperA: article.upperA,
        lowerB: article.lowerB,
        upperB: article.upperB,
      );

      measurements.add(
        Measurement(
          project: '',
          bezug: article.bezug,

          physicalSampleOid:
              'DEMO-SAMPLE-${(i + 1).toString().padLeft(5, '0')}',

          standardSampleOid:
              article.standardSampleOid,

          name: article.name,
          datum: datum,

          artikelnummer:
              article.artikelnummer,

          baNr: baNr,

          benutzer:
              'Demo User ${(i % 4) + 1}',

          lichtart: '',

          l: l,
          a: a,
          b: b,

          standardL:
              article.standardL,

          standardA:
              article.standardA,

          standardB:
              article.standardB,

          deltaL: deltaL,
          deltaA: deltaA,
          deltaB: deltaB,
          deltaE: deltaE,

          gloss: gloss,

          // Mirrors the current Colibri mapping.
          standardGloss: null,
          deltaGloss: null,

          lowerL: article.lowerL,
          upperL: article.upperL,

          lowerA: article.lowerA,
          upperA: article.upperA,

          lowerB: article.lowerB,
          upperB: article.upperB,

          lowerGloss: null,
          upperGloss: null,

          status: status,
        ),
      );
    }

    // Colibri query returns newest measurements first.
    measurements.sort(
      (a, b) =>
          b.datum.compareTo(a.datum),
    );

    return measurements;
  }

  // ============================================================
  // DEMO-WERTE
  // ============================================================

  double _signedVariation(
    Random random,
    double maximum,
  ) {
    return (
      random.nextDouble() * 2 - 1
    ) *
        maximum;
  }

  // ============================================================
  // DELTA E
  // ============================================================

  double _calculateDeltaE(
    double deltaL,
    double deltaA,
    double deltaB,
  ) {
    return sqrt(
      pow(deltaL, 2) +
          pow(deltaA, 2) +
          pow(deltaB, 2),
    );
  }

  // ============================================================
  // STATUS OK / NOK
  // ============================================================

  String _calculateStatus({
    required double deltaL,
    required double deltaA,
    required double deltaB,
    required double? lowerL,
    required double? upperL,
    required double? lowerA,
    required double? upperA,
    required double? lowerB,
    required double? upperB,
  }) {
    final lOk = _withinLimits(
      deltaL,
      lowerL,
      upperL,
    );

    final aOk = _withinLimits(
      deltaA,
      lowerA,
      upperA,
    );

    final bOk = _withinLimits(
      deltaB,
      lowerB,
      upperB,
    );

    if (lOk && aOk && bOk) {
      return 'OK';
    }

    return 'NOK';
  }

  // ============================================================
  // TOLERANZPRÜFUNG
  // ============================================================

  bool _withinLimits(
    double value,
    double? lower,
    double? upper,
  ) {
    // Lower tolerances are stored as positive magnitudes.
    // Example: 0.35 means an actual lower limit of -0.35.

    if (lower != null &&
        value < -lower) {
      return false;
    }

    if (upper != null &&
        value > upper) {
      return false;
    }

    return true;
  }
}

// ================================================================
// DEMO ARTICLE / STANDARD
// ================================================================

class _DemoArticle {
  final String artikelnummer;
  final String name;

  final String bezug;
  final String standardSampleOid;

  final double standardL;
  final double standardA;
  final double standardB;

  final double lowerL;
  final double upperL;

  final double lowerA;
  final double upperA;

  final double lowerB;
  final double upperB;

  final double? glossBase;

  const _DemoArticle({
    required this.artikelnummer,
    required this.name,
    required this.bezug,
    required this.standardSampleOid,
    required this.standardL,
    required this.standardA,
    required this.standardB,
    required this.lowerL,
    required this.upperL,
    required this.lowerA,
    required this.upperA,
    required this.lowerB,
    required this.upperB,
    this.glossBase,
  });
}