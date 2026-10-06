class Measurement {
  // ============================================================
  // COLIBRI IDENTIFICATION
  // ============================================================

  final String project;
  final String bezug;

  final String physicalSampleOid;
  final String standardSampleOid;

  // ============================================================
  // MEASUREMENT IDENTIFICATION
  // ============================================================

  final String name;
  final DateTime datum;

  final String artikelnummer;
  final String baNr;
  final String benutzer;
  final String lichtart;

  // ============================================================
  // MEASURED ABSOLUTE VALUES
  // ============================================================

  final double l;
  final double a;
  final double b;

  // ============================================================
  // REFERENCE / STANDARD ABSOLUTE VALUES
  // ============================================================

  final double standardL;
  final double standardA;
  final double standardB;

  // ============================================================
  // CALCULATED VALUES
  // ============================================================

  final double deltaL;
  final double deltaA;
  final double deltaB;
  final double deltaE;

  // ============================================================
  // GLOSS
  // ============================================================

  final double? gloss;
  final double? standardGloss;
  final double? deltaGloss;

  // ============================================================
  // REFERENCE TOLERANCES
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
  // INSPECTION RESULT
  // ============================================================

  final String status;

  // ============================================================
  // CONSTRUCTOR
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
      // MEASURED VALUES
      // ==========================================================

      l: _toDouble(json['l']),
      a: _toDouble(json['a']),
      b: _toDouble(json['b']),

      // ==========================================================
      // REFERENCE VALUES
      // ==========================================================

      standardL:
          _toDouble(json['standardL']),

      standardA:
          _toDouble(json['standardA']),

      standardB:
          _toDouble(json['standardB']),

      // ==========================================================
      // CALCULATED VALUES
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
      // GLOSS
      // ==========================================================

      gloss:
          _toNullableDouble(json['gloss']),

      standardGloss:
          _toNullableDouble(json['standardGloss']),

      deltaGloss:
          _toNullableDouble(json['deltaGloss']),

      // ==========================================================
      // TOLERANCES
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
      // INSPECTION RESULT
      // ==========================================================

      status:
          json['status']?.toString() ?? '',
    );
  }

  // ============================================================
  // JSON HELPER FUNCTIONS
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