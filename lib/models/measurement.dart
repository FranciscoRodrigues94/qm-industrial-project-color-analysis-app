class Measurement {
  // ============================================================
  // COLIBRI-IDENTIFIKATION
  // ============================================================

  final String project;
  final String bezug;

  final String physicalSampleOid;
  final String standardSampleOid;

  // ============================================================
  // MESSUNGSIDENTIFIKATION
  // ============================================================

  final String name;
  final DateTime datum;

  final String artikelnummer;
  final String baNr;
  final String benutzer;
  final String lichtart;

  // ============================================================
  // GEMESSENE ABSOLUTWERTE
  // ============================================================

  final double l;
  final double a;
  final double b;

  // ============================================================
  // ABSOLUTWERTE DES BEZUGS / STANDARDS
  // ============================================================

  final double standardL;
  final double standardA;
  final double standardB;

  // ============================================================
  // BERECHNETE WERTE
  // ============================================================

  final double deltaL;
  final double deltaA;
  final double deltaB;
  final double deltaE;

  // ============================================================
  // GLANZ
  // ============================================================

  final double? gloss;
  final double? standardGloss;
  final double? deltaGloss;

  // ============================================================
  // TOLERANZEN DES BEZUGS
  // ============================================================

  final double? lowerL;
  final double? upperL;

  final double? lowerA;
  final double? upperA;

  final double? lowerB;
  final double? upperB;

  final double? lowerGloss;
  final double? upperGloss;

  // ============================================================
  // PRÜFERGEBNIS
  // ============================================================

  final String status;

  // ============================================================
  // KONSTRUKTOR
  // ============================================================

  Measurement({
    this.project = '',
    this.bezug = '',
    this.physicalSampleOid = '',
    this.standardSampleOid = '',
    this.name = '',
    DateTime? datum,
    this.artikelnummer = '',
    this.baNr = '',
    this.benutzer = '',
    this.lichtart = '',
    this.l = 0.0,
    this.a = 0.0,
    this.b = 0.0,
    this.standardL = 0.0,
    this.standardA = 0.0,
    this.standardB = 0.0,
    this.deltaL = 0.0,
    this.deltaA = 0.0,
    this.deltaB = 0.0,
    this.deltaE = 0.0,
    this.gloss,
    this.standardGloss,
    this.deltaGloss,
    this.lowerL,
    this.upperL,
    this.lowerA,
    this.upperA,
    this.lowerB,
    this.upperB,
    this.lowerGloss,
    this.upperGloss,
    this.status = '',
  }) : datum = datum ?? DateTime.now();

  // ============================================================
  // JSON → MEASUREMENT
  // ============================================================

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      project: json['project']?.toString() ?? '',
      bezug: json['bezug']?.toString() ?? '',

      physicalSampleOid:
          json['physicalSampleOid']?.toString() ?? '',

      standardSampleOid:
          json['standardSampleOid']?.toString() ?? '',

      name: json['name']?.toString() ?? '',

      datum: _parseDate(json['datum']),

      artikelnummer:
          json['artikelnummer']?.toString() ?? '',

      baNr:
          json['baNr']?.toString() ?? '',

      benutzer:
          json['benutzer']?.toString() ?? '',

      lichtart:
          json['lichtart']?.toString() ?? '',

      // ==========================================================
      // GEMESSENE WERTE
      // ==========================================================

      l: _toDouble(json['l']),
      a: _toDouble(json['a']),
      b: _toDouble(json['b']),

      // ==========================================================
      // BEZUGSWERTE
      // ==========================================================

      standardL:
          _toDouble(json['standardL']),

      standardA:
          _toDouble(json['standardA']),

      standardB:
          _toDouble(json['standardB']),

      // ==========================================================
      // BERECHNETE WERTE
      // ==========================================================

      deltaL:
          _toDouble(json['deltaL']),

      deltaA:
          _toDouble(json['deltaA']),

      deltaB:
          _toDouble(json['deltaB']),

      deltaE:
          _toDouble(json['deltaE']),

      // ==========================================================
      // GLANZ
      // ==========================================================

      gloss:
          _toNullableDouble(json['gloss']),

      standardGloss:
          _toNullableDouble(json['standardGloss']),

      deltaGloss:
          _toNullableDouble(json['deltaGloss']),

      // ==========================================================
      // TOLERANZEN
      // ==========================================================

      lowerL:
          _toNullableDouble(json['lowerL']),

      upperL:
          _toNullableDouble(json['upperL']),

      lowerA:
          _toNullableDouble(json['lowerA']),

      upperA:
          _toNullableDouble(json['upperA']),

      lowerB:
          _toNullableDouble(json['lowerB']),

      upperB:
          _toNullableDouble(json['upperB']),

      lowerGloss:
          _toNullableDouble(json['lowerGloss']),

      upperGloss:
          _toNullableDouble(json['upperGloss']),

      // ==========================================================
      // PRÜFERGEBNIS
      // ==========================================================

      status:
          json['status']?.toString() ?? '',
    );
  }

  // ============================================================
  // HILFSFUNKTIONEN FÜR JSON
  // ============================================================

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(',', '.'),
        ) ??
        0.0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '.'),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value.toString(),
        ) ??
        DateTime.now();
  }
}