import 'package:flutter/services.dart' show rootBundle;

import '../models/measurement.dart';
import '../models/project_structure.dart';

class MeasurementDataService {
  
  // ============================================================
  // MESSUNGEN LADEN
  // ============================================================

  Future<List<Measurement>> loadMeasurements() async {
    final csvString = await rootBundle.loadString(
      'assets/QS_FakeDaten_mit_Bezug.csv',
    );

    final rows = parseCsv(csvString);

    if (rows.isEmpty) {
      throw Exception('CSV ist leer.');
    }

    final headers = rows.first
        .map((e) => e.toString().trim())
        .toList();

    final columnIndex = <String, int>{};

    for (int i = 0; i < headers.length; i++) {
      columnIndex[headers[i]] = i;
    }

    String value(List<String> row, String column) {
      final index = columnIndex[column];

      if (index == null || index >= row.length) {
        return '';
      }

      return row[index].trim();
    }

    final loadedMeasurements = <Measurement>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      if (row.isEmpty) {
        continue;
      }

      final bezugValue = value(row, 'Bezug');
      final datumValue = value(row, 'Datum');

      if (bezugValue == 'Bezug') {
        continue;
      }

      if (datumValue.isEmpty) {
        continue;
      }

      loadedMeasurements.add(
        Measurement(
          bezug: bezugValue,
          artikelnummer: value(
            row,
            'Artikelnummer',
          ),
          name: value(
            row,
            'Name_Suche',
          ),
          datum: parseGermanDate(
            datumValue,
          ),
          status: value(
            row,
            'erfüllt',
          ),
          benutzer: value(
            row,
            'Benutzer',
          ),
          lichtart: value(
            row,
            'Lichtart',
          ),
          baNr: value(
            row,
            'BA-Nr.',
          ),
          l: parseGermanNumber(
            value(row, 'L*'),
          ),
          a: parseGermanNumber(
            value(row, 'a*'),
          ),
          b: parseGermanNumber(
            value(row, 'b*'),
          ),
          deltaL: parseGermanNumber(
            value(
              row,
              'ΔL* ±1,5',
            ),
          ),
          deltaA: parseGermanNumber(
            value(
              row,
              'Δa* ±0,40',
            ),
          ),
          deltaB: parseGermanNumber(
            value(
              row,
              'Δb* ±0,40',
            ),
          ),
          deltaE: parseGermanNumber(
            value(
              row,
              'ΔE*',
            ),
          ),
        ),
      );
    }

    return loadedMeasurements;
  }

  // ============================================================
  // PROJEKT- UND BEZUG-STRUKTUR
  // ============================================================

  List<ProjectGroup> groupMeasurements(
    List<Measurement> measurements,
  ) {
    final Map<String, Map<String, List<Measurement>>>
        grouped = {};

    for (final measurement in measurements) {
      final projectName =
          measurement.project.trim().isEmpty
              ? 'Ohne Projekt'
              : measurement.project.trim();

      final bezugName =
          measurement.bezug.trim().isEmpty
              ? 'Ohne Bezug'
              : measurement.bezug.trim();

      grouped.putIfAbsent(
        projectName,
        () => {},
      );

      grouped[projectName]!.putIfAbsent(
        bezugName,
        () => [],
      );

      grouped[projectName]![bezugName]!.add(
        measurement,
      );
    }

    final projects = <ProjectGroup>[];

    for (final projectEntry in grouped.entries) {
      final bezuege = <BezugGroup>[];

      for (final bezugEntry
          in projectEntry.value.entries) {
        final measurementsForBezug =
            bezugEntry.value;

        String standardSampleOid = '';

        for (final measurement
            in measurementsForBezug) {
          if (measurement
              .standardSampleOid
              .isNotEmpty) {
            standardSampleOid =
                measurement.standardSampleOid;

            break;
          }
        }

        bezuege.add(
          BezugGroup(
            name: bezugEntry.key,
            standardSampleOid:
                standardSampleOid,
            measurements:
                List.unmodifiable(
              measurementsForBezug,
            ),
          ),
        );
      }

      projects.add(
        ProjectGroup(
          name: projectEntry.key,
          bezuege:
              List.unmodifiable(
            bezuege,
          ),
        ),
      );
    }

    projects.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return projects;
  }

  // ============================================================
  // CSV PARSEN
  // ============================================================

  List<List<String>> parseCsv(
    String input,
  ) {
    final lines = input.split(
      RegExp(r'\r?\n'),
    );

    return lines
        .where(
          (line) =>
              line.trim().isNotEmpty,
        )
        .map(
          (line) {
            return line
                .split(',')
                .map(
                  (value) =>
                      value.trim(),
                )
                .toList();
          },
        )
        .toList();
  }

  // ============================================================
  // DATUM PARSEN
  // ============================================================

  DateTime parseGermanDate(
    String value,
  ) {
    final parts = value.split(' ');

    if (parts.length < 2) {
      throw FormatException(
        'Ungültiges Datum: $value',
      );
    }

    final dateParts =
        parts[0].split('.');

    if (dateParts.length != 3) {
      throw FormatException(
        'Ungültiges Datum: $value',
      );
    }

    final day = int.parse(
      dateParts[0],
    );

    final month = int.parse(
      dateParts[1],
    );

    final year = int.parse(
      dateParts[2],
    );

    final timeParts =
        parts[1].split(':');

    final hour =
        timeParts.isNotEmpty
            ? int.parse(
                timeParts[0],
              )
            : 0;

    final minute =
        timeParts.length > 1
            ? int.parse(
                timeParts[1],
              )
            : 0;

    final second =
        timeParts.length > 2
            ? int.parse(
                timeParts[2],
              )
            : 0;

    return DateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
  }

  // ============================================================
  // DEUTSCHE ZAHLEN PARSEN
  // ============================================================

  double parseGermanNumber(
    String value,
  ) {
    if (value.isEmpty) {
      return 0.0;
    }

    final cleaned = value
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(
          cleaned,
        ) ??
        0.0;
  }
}