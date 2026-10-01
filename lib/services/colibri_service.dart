import 'dart:math';

import 'package:odbc_fast/odbc_fast.dart';

import '../models/measurement.dart';
import '../config/database_config.dart';
import '../config/colibri_query.dart';

class ColibriService {
  // ============================================================
  // COLIBRI / SQL SERVER
  // ============================================================

  // ============================================================
  // DATEN LADEN
  // ============================================================

  Future<List<Measurement>> getMeasurements({
    DateTime? fromDate,
  }) async {
    final start = fromDate ?? DateTime(2025, 1, 1);

    final today = DateTime.now();

    // Inclui o dia atual completo.
    final endExclusive = DateTime(
      today.year,
      today.month,
      today.day + 1,
    );

    final startSql = _formatSqlDate(start);
    final endSql = _formatSqlDate(endExclusive);

    final locator = ServiceLocator()
      ..initialize(
        profile: OdbcUsageProfile.balancedFlutter,
      );

    final service = locator.service;

    String? connectionId;

    try {
      print('');
      print('========================================');
      print('COLIBRI - DATEN LADEN');
      print('========================================');
      print('Von: $startSql');
      print('Bis: $endSql');

      // ========================================================
      // ODBC INITIALISIEREN
      // ========================================================

      final initResult = await service.initialize();

      if (initResult.isError()) {
        throw Exception(
          'ODBC_FAST konnte nicht initialisiert werden: '
          '$initResult',
        );
      }

      // ========================================================
      // VERBINDUNG ÖFFNEN
      // ========================================================

      final connectionResult = await service.connect(
        DatabaseConfig.connectionString,
        options: ConnectionOptions(
          loginTimeout: const Duration(seconds: 15),

          // Genügend Puffer für größere Colibri-Abfragen.
          initialResultBufferBytes: 256 * 1024,
          maxResultBufferBytes: 64 * 1024 * 1024,

          queryTimeout: const Duration(seconds: 60),
        ),
      );

      final connection = connectionResult.getOrNull();

      if (connection == null) {
        throw Exception(
          'Verbindung zur Colibri-Datenbank '
          'fehlgeschlagen: $connectionResult',
        );
      }

      connectionId = connection.id;

      print('COLIBRI VERBINDUNG OK');
      print('Connection ID: $connectionId');

      // ========================================================
      // SQL QUERY
      // ========================================================

      final query = ColibriQuery.measurements(
        startSql: startSql,
        endSql: endSql,
      );

      print('COLIBRI QUERY START...');

      // ========================================================
      // QUERY AUSFÜHREN
      // ========================================================

      final queryResult = await service.executeQuery(
        query,
        connectionId: connectionId,
      );

      final measurements = <Measurement>[];

      Object? queryError;

      queryResult.fold(
        (result) {
          print(
            'COLIBRI QUERY OK: '
            '${result.rowCount} Zeilen',
          );

          final rows = result.rowsAsMaps;

          for (final row in rows) {
            measurements.add(
              _mapRowToMeasurement(row),
            );
          }
        },
        (error) {
          queryError = error;
        },
      );

      if (queryError != null) {
        throw Exception(
          'Fehler bei der Colibri-Abfrage: '
          '$queryError',
        );
      }

      // ========================================================
      // ERGEBNIS
      // ========================================================

      print(
        'COLIBRI: '
        '${measurements.length} Messungen geladen',
      );

      if (measurements.isNotEmpty) {
        final newest = measurements.first.datum;
        final oldest = measurements.last.datum;

        print(
          'COLIBRI: von $oldest bis $newest',
        );
      }

      print('========================================');
      print('');

      return measurements;
    } catch (e, stackTrace) {
      print('');
      print('========================================');
      print('COLIBRI FEHLER');
      print('========================================');
      print(e);
      print(stackTrace);
      print('========================================');
      print('');

      rethrow;
    } finally {
      // ========================================================
      // VERBINDUNG SCHLIESSEN
      // ========================================================

      if (connectionId != null) {
        try {
          await service.disconnect(
            connectionId,
          );

          print(
            'COLIBRI VERBINDUNG GESCHLOSSEN',
          );
        } catch (e) {
          print(
            'Fehler beim Schließen '
            'der Colibri-Verbindung: $e',
          );
        }
      }

      locator.shutdown();
    }
  }

  // ============================================================
  // SQL ROW -> MEASUREMENT
  // ============================================================

  Measurement _mapRowToMeasurement(
    Map<String, dynamic> row,
  ) {
    // ==========================================================
    // GEMESSENE LAB-WERTE
    // ==========================================================

    final l =
        _toDouble(row['L']) ?? 0.0;

    final a =
        _toDouble(row['a']) ?? 0.0;

    final b =
        _toDouble(row['b']) ?? 0.0;

    // ==========================================================
    // STANDARD / BEZUG
    // ==========================================================

    final standardL =
        _toDouble(row['Standard_L']) ?? 0.0;

    final standardA =
        _toDouble(row['Standard_a']) ?? 0.0;

    final standardB =
        _toDouble(row['Standard_b']) ?? 0.0;

    // ==========================================================
    // DELTA
    // ==========================================================

    final deltaL =
        l - standardL;

    final deltaA =
        a - standardA;

    final deltaB =
        b - standardB;

    final deltaE = _calculateDeltaE(
      deltaL,
      deltaA,
      deltaB,
    );

    // ==========================================================
    // TOLERANZEN
    // ==========================================================

    final lowerL =
        _toDouble(row['lL']);

    final upperL =
        _toDouble(row['uL']);

    final lowerA =
        _toDouble(row['la']);

    final upperA =
        _toDouble(row['ua']);

    final lowerB =
        _toDouble(row['lb']);

    final upperB =
        _toDouble(row['ub']);

    final lowerGloss =
        _toDouble(row['lGloss']);

    final upperGloss =
        _toDouble(row['uGloss']);

    // ==========================================================
    // GLANZ
    // ==========================================================

    final gloss =
        _toDouble(row['Gloss']);

    // ==========================================================
    // STATUS
    // ==========================================================

    final status = _calculateStatus(
      deltaL: deltaL,
      deltaA: deltaA,
      deltaB: deltaB,
      lowerL: lowerL,
      upperL: upperL,
      lowerA: lowerA,
      upperA: upperA,
      lowerB: lowerB,
      upperB: upperB,
    );

    // ==========================================================
    // MEASUREMENT
    // ==========================================================

    return Measurement(
      project: '',

      bezug:
          _toStringValue(
        row['Standard_Name'],
      ),

      physicalSampleOid:
          _toStringValue(
        row['Physical_Sample_OID'],
      ),

      standardSampleOid:
          _toStringValue(
        row['Standard_Sample_OID'],
      ),

      name:
          _toStringValue(
        row['Sample_Name'],
      ),

      datum:
          _parseDate(
        row['Sample_CreationDate'],
      ),

      artikelnummer:
          _toStringValue(
        row['Artikelnummer'],
      ),

      baNr:
          _toStringValue(
        row['BA_Nr'],
      ),

      benutzer:
          _toStringValue(
        row['ColibriUser'],
      ),

      lichtart: '',

      l: l,
      a: a,
      b: b,

      standardL: standardL,
      standardA: standardA,
      standardB: standardB,

      deltaL: deltaL,
      deltaA: deltaA,
      deltaB: deltaB,
      deltaE: deltaE,

      gloss: gloss,

      standardGloss: null,
      deltaGloss: null,

      lowerL: lowerL,
      upperL: upperL,

      lowerA: lowerA,
      upperA: upperA,

      lowerB: lowerB,
      upperB: upperB,

      lowerGloss: lowerGloss,
      upperGloss: upperGloss,

      status: status,
    );
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
    // Colibri speichert die untere Toleranz
    // als positiven Betrag.
    //
    // Beispiel:
    // lower = 0.35
    // bedeutet tatsächliche Untergrenze = -0.35

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

  // ============================================================
  // DOUBLE KONVERTIEREN
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final normalized =
        text.replaceAll(',', '.');

    return double.tryParse(
      normalized,
    );
  }

  // ============================================================
  // STRING KONVERTIEREN
  // ============================================================

  String _toStringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // DATUM PARSEN
  // ============================================================

  DateTime _parseDate(
    dynamic value,
  ) {
    if (value is DateTime) {
      return value;
    }

    final text =
        value?.toString().trim() ?? '';

    final parsed =
        DateTime.tryParse(text);

    if (parsed != null) {
      return parsed;
    }

    throw FormatException(
      'Ungültiges Colibri-Datum: "$text"',
    );
  }

  // ============================================================
  // SQL DATUM
  // ============================================================

  String _formatSqlDate(
    DateTime date,
  ) {
    final year =
        date.year
            .toString()
            .padLeft(4, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    return '$year-$month-$day';
  }
}