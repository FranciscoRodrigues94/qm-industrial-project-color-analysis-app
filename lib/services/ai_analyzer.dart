import 'dart:math' as math;
import '../models/measurement.dart';

class QSAnalysisResult {

  final String answer;

  const QSAnalysisResult(this.answer);

}

class _QSIntent {

  final String type;

  final String? dimension;

  final List<String> baNrs;

  final String? artikelnummer;

  final int? year;

  const _QSIntent(

    this.type, {

    this.dimension,

    this.baNrs = const [],

    this.artikelnummer,

    this.year,

  });

}

class QSAnalyzer {

  final List<Measurement> measurements;

  QSAnalyzer(this.measurements);

  QSAnalysisResult analyze(String question) {

    final q = _normalize(question);

    if (q.isEmpty) {

      return const QSAnalysisResult(

        'Bitte gib eine Frage ein.',

      );

    }

    final intent = _detectIntent(q);

    switch (intent.type) {

      case 'explore':

        return _explorativeAnalyse(intent.year);

      case 'ba_compare':

        return _baVergleich(

          intent.baNrs,

          intent.dimension,

          intent.year,

        );

      case 'ba_development':

        return _baEntwicklung(

          intent.baNrs.first,

          intent.dimension,

          intent.year,

        );

      case 'ba_dimension':

        return _baDimensionAnalyse(

          intent.baNrs.first,

          intent.dimension!,

          intent.year,

        );

      case 'ba_why':
        return _baWhyAnalyse(

        intent.baNrs.first,

        intent.year,
        );

      case 'ba_status':

        return _baDeepAnalyse(

          intent.baNrs.first,

          intent.year,

        );

      case 'ba_general':

        return _baDeepAnalyse(

          intent.baNrs.first,

          intent.year,

        );

      case 'article_specific':

        return _artikelDetailAnalyse(

          intent.artikelnummer!,

          intent.year,

        );

      case 'global_dimension_development':

        return _globaleDimensionEntwicklung(

          intent.dimension!,

          intent.year,

        );

      case 'article_dimension':

        return _artikelNachMessgroesse(

          intent.dimension!,

          intent.year,

        );

      case 'article_rate':

        return _artikelMitHoechsterFehlerquote(

          intent.year,

        );

      case 'article_deviations':

        return _artikelMitMeistenAbweichungen(

          intent.year,

        );

      case 'dimension_most':

        return _messgroesseMitMeistenAbweichungen(

          intent.year,

        );

      case 'tolerance':

        return _messungenAusserhalbToleranz(

          intent.year,

        );

      case 'general':

        return _allgemeineStatistik(

          intent.year,

        );

      default:

        return const QSAnalysisResult(

          'Ich konnte die Frage noch nicht eindeutig verstehen.\n\n'

          'Zum Beispiel:\n'

          '• Wie hoch ist die Fehlerquote insgesamt?\n'

          '• Was ist bei BA x nicht in Ordnung?\n'

          '• Welche Messgröße hat die meisten Abweichungen?\n'

          '• Vergleiche BA x mit BA y.\n'

          '• Wie hat sich BA x entwickelt?\n'

          '• Was fällt dir in den Messdaten auf?',

        );

    }

  }

  // ================================================================

  // INTENTION

  // ================================================================

  _QSIntent _detectIntent(String q) {

    final baNrs = _extractMultipleBaNrs(q);

    final dimension = _detectDimension(q);

    final year = _detectYear(q);

    final artikelnummer = _extractArtikelnummer(q);

    final asksCount = _hasAny(q, [

      'wie viele',

      'wieviel',

      'wieviele',

      'anzahl',

      'zahl',

      'count',

      'wie oft',

    ]);

    final asksStatus = _hasAny(q, [

      'nio',

      'n.i.o',

      'nicht ok',

      'nicht okay',

      'nicht in ordnung',

      'nicht erfuellt',

      'nicht erfüllt',

      'fehler',

      'fehlerhaft',

      'schlecht',

      'abweich',

      'problem',

      'probleme',

      'auffaellig',

      'auffällig',

      'kritisch',

      'ausserhalb',

      'außerhalb',

    ]);

    final asksComparison = _hasAny(q, [

      'vergleich',

      'vergleiche',

      'gegenueber',

      'gegenüber',

      'unterschied',

      'unterschiede',

      'besser',

      'schlechter',

    ]);

    final asksDevelopment = _hasAny(q, [

      'entwicklung',

      'entwicklungen',

      'entwickelt',

      'verlauf',

      'trend',

      'trends',

      'zeit',

      'zeitraum',

      'monate',

      'monatlich',

    ]);

    final isArticle = _hasAny(q, [

      'artikel',

      'produkt',

      'produkte',

      'teil',

      'teile',

      'bauteil',

      'bauteile',

    ]);

    final asksForRate = _hasAny(q, [

      'fehlerquote',

      'fehler rate',

      'fehleranteil',

      'fehler prozent',

      'fehlerprozentsatz',

      'prozent fehler',

      'anteil fehler',

      'rate',

      'quote',

    ]);

    final asksForMost = _hasAny(q, [

      'meisten',

      'meiste',

      'am meisten',

      'höchste',

      'hoechste',

      'stärkste',

      'staerkste',

      'häufigste',

      'haeufigste',

      'häufigsten',

      'haeufigsten',

      'auffälligste',

      'auffaelligste',

      'schlimmste',

      'schlechteste',

      'größten',

      'groessten',

    ]);

    final asksTolerance = _hasAny(q, [

      'toleranz',

      'toleranzen',

      'grenzwert',

      'grenzwerte',

      'ausserhalb',

      'außerhalb',

      'nicht innerhalb',

    ]);

    final asksMeasurements = _hasAny(q, [

      'messung',

      'messungen',

      'messwert',

      'messwerte',

      'ergebnis',

      'ergebnisse',

      'prüfung',

      'pruefung',

      'werte',

      'wert',

    ]);

    // Questions like "Was fällt dir auf?" are exploratory.

    final isExplorative = _hasAny(q, [

      'was faellt dir auf',

      'was faellt dir in den messdaten auf',

      'was fällt dir auf',

      'was fällt dir in den messdaten auf',

      'was wuerdest du dir ansehen',

      'was wuerdest du dir genauer ansehen',

      'was würdest du dir ansehen',

      'was würdest du dir genauer ansehen',

      'worauf sollte ich achten',

      'worauf muss ich achten',

      'etwas auffaellig',

      'etwas auffällig',

      'groessten probleme',

      'größten probleme',

      'groessten qualitaetsauffaelligkeiten',

      'größten qualitätsauffälligkeiten',

      'qualitaetsauffaelligkeiten',

      'qualitätsauffälligkeiten',

      'wo liegen die probleme',

      'was ist kritisch',

      'welcher bereich sieht am kritischsten aus',

      'genauer untersuchen',

    ]);

    if (isExplorative && baNrs.isEmpty && artikelnummer == null) {

      return _QSIntent(

        'explore',

        year: year,

      );

    }

    // Comparison of multiple BAs.
    //
    // In addition to "BA 1001 and BA 1002", natural forms
    // such as "1001 or 1002" are also recognized.

    final comparisonBaNrs = _extractComparisonBaNrs(q);

    if (comparisonBaNrs.length >= 2 &&

        (asksComparison || asksDevelopment)) {

      return _QSIntent(

        'ba_compare',

        baNrs: comparisonBaNrs,

        dimension: dimension,

        year: year,

      );

    }

    // Single BA + why question.
    // These questions should explain why the BA is classified as n.i.O.
    // without inventing an unsupported process cause.
    final asksWhy = _hasAny(q, [
      'warum',
      'wieso',
      'weshalb',
      'woran liegt',
      'warum ist',
      'warum wurde',
    ]);

    if (baNrs.length == 1 && asksWhy) {

      return _QSIntent(

        'ba_why',

        baNrs: baNrs,

        year: year,
      );

    }

    // Single BA + Development

    if (baNrs.length == 1 && asksDevelopment) {

      return _QSIntent(

        'ba_development',

        baNrs: baNrs,

        dimension: dimension,

        year: year,

      );

    }

    // Single BA + specific measurement parameter

    if (baNrs.length == 1 && dimension != null) {

      return _QSIntent(

        'ba_dimension',

        baNrs: baNrs,

        dimension: dimension,

        year: year,

      );

    }

    // Single BA.

    if (baNrs.length == 1) {

      if (asksStatus ||

          asksCount ||

          asksTolerance ||

          asksMeasurements ||

          asksForRate ||

          asksDevelopment) {

        return _QSIntent(

          'ba_status',

          baNrs: baNrs,

          year: year,

        );

      }

      return _QSIntent(

        'ba_general',

        baNrs: baNrs,

        year: year,

      );

    }

    // Specific article: a question about this exact article should
    // never be redirected tp a general top-5 ranking.
    if (artikelnummer != null) {
      return _QSIntent(
        'article_specific',
        artikelnummer: artikelnummer,
        dimension: dimension,
        year: year,
      );
    }

    // Global trend of a measurement parameter over time, e.g.
    // "Wie entwickelt sich ΔL* über die Zeit?"
    if (dimension != null && asksDevelopment && baNrs.isEmpty) {
      return _QSIntent(
        'global_dimension_development',
        dimension: dimension,
        year: year,
      );
    }

    if (isArticle && dimension != null) {

      return _QSIntent(

        'article_dimension',

        dimension: dimension,

        year: year,

      );

    }

    if (isArticle && asksForRate) {

      return _QSIntent(

        'article_rate',

        year: year,

      );

    }

    if (isArticle &&

        (asksForMost || asksStatus)) {

      return _QSIntent(

        'article_deviations',

        year: year,

      );

    }

    // Without dimension: "Welche Messgröße hat die meisten Abweichungen?"

    if (dimension == null &&

        (asksForMost || asksStatus) &&

        _hasAny(q, [

          'messgroesse',

          'messgröße',

          'messgroessen',

          'messgrößen',

          'messwert',

          'messwerte',

          'parameter',

        ])) {

      return _QSIntent(

        'dimension_most',

        year: year,

      );

    }

    // "Welche Toleranz wird am häufigsten überschritten?"

    // or "Wo haben wir die größten Toleranzprobleme?"

    if (dimension == null &&

        asksTolerance &&

        (asksForMost || asksStatus)) {

      return _QSIntent(

        'tolerance',

        year: year,

      );

    }

    // With dimension, but without article/BA:

    // "Wo gibt es Probleme bei L*?"

    if (dimension != null &&

        (asksStatus ||

            asksForMost ||

            asksTolerance)) {

      return _QSIntent(

        'article_dimension',

        dimension: dimension,

        year: year,

      );

    }

    if (asksMeasurements && asksTolerance) {

      return _QSIntent(

        'tolerance',

        year: year,

      );

    }

    if (asksForRate &&

        _hasAny(q, [

          'insgesamt',

          'gesamt',

          'gesamt',

          'overall',

          'allgemein',

        ])) {

      return _QSIntent(

        'general',

        year: year,

      );

    }

    if (_isGeneralStatisticsQuestion(q)) {

      return _QSIntent(

        'general',

        year: year,

      );

    }

    // "Wie hoch ist die Fehlerquote?"

    if (asksForRate && baNrs.isEmpty && !isArticle) {

      return _QSIntent(

        'general',

        year: year,

      );

    }

    return const _QSIntent('unknown');

  }

  // ================================================================

  // ENTITY / FILTER

  // ================================================================

  List<String> _extractComparisonBaNrs(String q) {
    final result = <String>[];

    // Collect all explicitly written BA numbers first.
    result.addAll(_extractMultipleBaNrs(q));

    // Also accepts a second BA written after a comparison connector.
    final connectorPattern = RegExp(
      r'(?:und|oder|vs\.?|versus|mit|gegen)\s*'
      r'(?:ba[\s-]*(?:nr\.?|nummer)?[\s:#-]*)?'
      r'([0-9]{3,})\b',
      caseSensitive: false,
    );

    for (final match in connectorPattern.allMatches(q)) {
      final value = match.group(1);

      if (value != null && !result.contains(value)) {
        result.add(value);
      }
    }

    // Fallback for comparisons where both BA numbers are written as numbers.
    if (result.length < 2) {
      final fallback = RegExp(
        r'\b([0-9]{3,})\b\s*'
        r'(?:und|oder|vs\.?|versus|gegen|mit)\s*'
        r'(?:ba[\s-]*(?:nr\.?|nummer)?[\s:#-]*)?'
        r'([0-9]{3,})\b',
        caseSensitive: false,
      ).firstMatch(q);

      if (fallback != null) {
        final first = fallback.group(1);
        final second = fallback.group(2);

        if (first != null && !result.contains(first)) {
          result.add(first);
        }

        if (second != null && !result.contains(second)) {
          result.add(second);
        }
      }
    }

    return result;
  }

  List<String> _extractMultipleBaNrs(String q) {
    final result = <String>[];

    final patterns = [
      RegExp(
        r'\bba[\s-]*nr\.?[\s:#-]*([0-9]{3,})\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\bba[\s-]*nummer[\s:#-]*([0-9]{3,})\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\bba[\s:#-]+([0-9]{3,})\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(q)) {
        final value = match.group(1);

        if (value != null && !result.contains(value)) {
          result.add(value);
        }
      }
    }

    // Also accepts a second BA after a connector without repeating "BA".
    if (result.length == 1) {
      final first = result.first;
      final firstIndex = q.indexOf(first);

      if (firstIndex >= 0) {
        final afterFirst = q.substring(firstIndex + first.length);

        final secondMatch = RegExp(
          r'(?:und|oder|vs\.?|versus|mit|gegen)\s*'
          r'(?:ba[\s-]*(?:nr\.?|nummer)?[\s:#-]*)?'
          r'([0-9]{3,})\b',
          caseSensitive: false,
        ).firstMatch(afterFirst);

        if (secondMatch != null) {
          final second = secondMatch.group(1);

          if (second != null && !result.contains(second)) {
            result.add(second);
          }
        }
      }
    }

    return result;
  }

  String? _extractArtikelnummer(String q) {
  final patterns = [
    RegExp(
      r'\bartikel(?:nummer|nr)?[\s:#-]+([a-z0-9]{6})\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\bprodukt(?:nummer|nr)?[\s:#-]+([a-z0-9]{6})\b',
      caseSensitive: false,
    ),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(q);

    if (match != null) {
      return match.group(1);
    }
  }

  return null;
}

  int? _detectYear(String q) {

    if (_hasAny(q, [

      'letztes jahr',

      'letzten jahr',

      'voriges jahr',

      'vorjahr',

    ])) {

      return DateTime.now().year - 1;

    }

    if (_hasAny(q, [

      'dieses jahr',

      'diesjahr',

      'heuer',

      'aktuelles jahr',

    ])) {

      return DateTime.now().year;

    }

    final match = RegExp(r'\b(20\d{2})\b').firstMatch(q);

    if (match != null) {

      return int.tryParse(match.group(1)!);

    }

    return null;

  }

  String? _detectDimension(String q) {

    if (_hasAny(q, [

      'delta e',
      'deltae',
      'delta-e',
      'de*',
      'de ',
      'd e',
      'δe',
      'Δe',
      'Δe*',

    ])) {

      return 'ΔE*';

    }

    if (_hasAny(q, [

      'l*',
      'l wert',
      'l-wert',
      'lwert',
      'delta l',
      'deltal',
      'delta-l',
      'dl',
      'helligkeit',
      'helligkeitswert',

    ])) {

      return 'L*';

    }

    if (_hasAny(q, [

      'a*',
      'a wert',
      'a-wert',
      'awert',
      'delta a',
      'deltaa',
      'delta-a',
      'da',

    ])) {

      return 'a*';

    }

    if (_hasAny(q, [

      'b*',
      'b wert',
      'b-wert',
      'bwert',
      'delta b',
      'deltab',
      'delta-b',
      'db',

    ])) {

      return 'b*';

    }

    return null;

  }

  bool _isGeneralStatisticsQuestion(String q) {

    return q.contains('wie viele messungen') ||

        q.contains('wieviel messungen') ||

        q.contains('anzahl messungen') ||

        q.contains('messungen insgesamt') ||

        q.contains('gesamtzahl') ||

        q.contains('wie viele sind erfuellt') ||

        q.contains('wie viele sind nicht erfuellt') ||

        q.contains('wie viele messungen sind erfuellt') ||

        q.contains('wie viele messungen sind nicht erfuellt') ||

        q.contains('aktueller stand') ||

        q.contains('aktuellen stand');

  }

  bool _hasAny(String text, List<String> words) {

    for (final word in words) {

      if (text.contains(word)) {

        return true;

      }

    }

    return false;

  }

  // ================================================================
  // STATUS / COLIBRI TOLERANCES
  // ================================================================

  /// Uses the status already calculated by ColibriService as the source of truth.
  /// Legacy German values are accepted as a fallback for older test data.
  bool _isNok(Measurement measurement) {
    final status = _normalize(measurement.status);
    return status == 'nok' ||
        status == 'nio' ||
        status == 'n.i.o' ||
        status == 'nicht erfuellt' ||
        status == 'nicht in ordnung';
  }

  bool _isOk(Measurement measurement) {
    final status = _normalize(measurement.status);
    return status == 'ok' ||
        status == 'io' ||
        status == 'i.o' ||
        status == 'erfuellt' ||
        status == 'in ordnung';
  }

  /// Colibri lower limits are positive magnitudes: lower=1.50 means -1.50.
  bool _isOutsideLimits(
    double value,
    double? lower,
    double? upper,
  ) {
    if (lower != null && value < -lower) return true;
    if (upper != null && value > upper) return true;
    return false;
  }

  String _normalize(String text) {

    return text

        .toLowerCase()

        .trim()

        .replaceAll('ä', 'ae')

        .replaceAll('ö', 'oe')

        .replaceAll('ü', 'ue')

        .replaceAll('ß', 'ss')

        .replaceAll(RegExp(r'\s+'), ' ');

  }

  // ================================================================

  // EXPLORATIVE ANALYSE

  // ================================================================

  QSAnalysisResult _explorativeAnalyse(int? year) {
    final data = _filterByYear(year);

    if (data.isEmpty) {
      return QSAnalysisResult(
        'Ich habe keine passenden Messdaten gefunden'
        '${year != null ? ' ($year)' : ''}.',
      );
    }

    final total = data.length;
    final nichtErfuellt = data.where(_isNok).length;
    final fehlerquote = nichtErfuellt / total * 100;

    int l = 0;
    int a = 0;
    int b = 0;

    for (final m in data) {
      if (_isOutsideLimits(m.deltaL, m.lowerL, m.upperL)) l++;
      if (_isOutsideLimits(m.deltaA, m.lowerA, m.upperA)) a++;
      if (_isOutsideLimits(m.deltaB, m.lowerB, m.upperB)) b++;
    }

    final dimensions = <String, int>{
      'L*': l,
      'a*': a,
      'b*': b,
    };

    final sortedDimensions = dimensions.entries.toList()
      ..sort((x, y) => y.value.compareTo(x.value));

    // All measurements remain part of the global statistics.
    // Empty article numbers are excluded only from the article ranking.
    final artikelFehler = <String, int>{};
    final artikelTotal = <String, int>{};
    int ohneArtikelnummer = 0;

    for (final m in data) {
      final artikelnummer = m.artikelnummer.trim();

      if (artikelnummer.isEmpty) {
        ohneArtikelnummer++;
        continue;
      }

      artikelTotal[artikelnummer] = (artikelTotal[artikelnummer] ?? 0) + 1;

      if (_isNok(m)) {
        artikelFehler[artikelnummer] =
            (artikelFehler[artikelnummer] ?? 0) + 1;
      }
    }

    final artikel = artikelTotal.keys.toList()
      ..sort(
        (x, y) =>
            (artikelFehler[y] ?? 0).compareTo(artikelFehler[x] ?? 0),
      );

    final auffaelligsterArtikel =
        artikel.isNotEmpty ? artikel.first : null;

    final buffer = StringBuffer();

    buffer.writeln('Analyse der Messdaten');

    if (year != null) {
      buffer.writeln('Zeitraum: $year');
    }

    buffer.writeln();
    buffer.writeln('Ich habe $total Messungen ausgewertet.');
    buffer.writeln(
      'Davon sind $nichtErfuellt n.i.O. '
      '(${fehlerquote.toStringAsFixed(1)} %).',
    );

    buffer.writeln();
    buffer.writeln('Was auffällt:');

    if (sortedDimensions.first.value > 0) {
      buffer.writeln(
        '• ${sortedDimensions.first.key} verursacht mit '
        '${sortedDimensions.first.value} '
        'Toleranzüberschreitungen die meisten Auffälligkeiten.',
      );
    } else {
      buffer.writeln(
        '• Bei L*, a* und b* wurden keine '
        'Toleranzüberschreitungen festgestellt.',
      );
    }

    if (auffaelligsterArtikel != null) {
      final articleErrors =
          artikelFehler[auffaelligsterArtikel] ?? 0;
      final articleTotal =
          artikelTotal[auffaelligsterArtikel] ?? 0;

      final articleRate = articleTotal > 0
          ? articleErrors / articleTotal * 100
          : 0.0;

      buffer.writeln(
        '• Unter den Messungen mit hinterlegter Artikelnummer entfallen '
        'die meisten n.i.O.-Messungen auf Artikel '
        '$auffaelligsterArtikel: $articleErrors von $articleTotal '
        '(${articleRate.toStringAsFixed(1)} %).',
      );
    }

    if (ohneArtikelnummer > 0) {
      buffer.writeln(
        '• Bei $ohneArtikelnummer Messungen ist keine '
        'Artikelnummer hinterlegt.',
      );
    }

    buffer.writeln();
    buffer.writeln(
      'Die wichtigsten Punkte für eine weitere Prüfung '
      'sind daher ${sortedDimensions.first.key}'
      '${auffaelligsterArtikel != null ? ' und Artikel $auffaelligsterArtikel' : ''}.',
    );

    return QSAnalysisResult(buffer.toString());
  }

  // ================================================================

  // BA + DIMENSION

  // ================================================================

  QSAnalysisResult _baDimensionAnalyse(
    String baNr,
    String dimension,
    int? year,
  ) {
    final data = _filterByYear(year)
        .where((m) => _baNrMatches(m.baNr, baNr))
        .toList()
      ..sort((a, b) => a.datum.compareTo(b.datum));

    if (data.isEmpty) {
      return QSAnalysisResult(
        'Für BA-Nr $baNr wurden keine Messungen gefunden'
        '${year != null ? ' ($year)' : ''}.',
      );
    }

    final artikel = _mostCommonArticle(data);

    // ΔE* has no separate tolerance limits in the current data model.
    if (dimension == 'ΔE*') {
      final values = data.map((m) => m.deltaE).toList();
      final average =
          values.fold<double>(0.0, (sum, value) => sum + value) / values.length;
      final maximum = values.reduce(math.max);

      final buffer = StringBuffer();
      buffer.writeln('Analyse $dimension für BA-Nr **$baNr**');
      if (artikel.isNotEmpty) {
        buffer.writeln('Artikel: **$artikel**');
      }
      if (year != null) {
        buffer.writeln('Zeitraum: $year');
      }

      buffer.writeln();
      buffer.writeln('Ergebnis');
      buffer.writeln('• **${data.length} Messungen** ausgewertet.');
      buffer.writeln('• Ø ΔE*: **${_formatNumber(average)}**.');
      buffer.writeln('• Größtes ΔE*: **${_formatNumber(maximum)}**.');

      buffer.writeln();
      buffer.writeln('Einordnung');
      buffer.writeln(
        '• ΔE* beschreibt die gesamte Farbdifferenz zum Standard. '
        'Je größer der Wert, desto stärker ist die gesamte Farbabweichung.',
      );
      buffer.writeln(
        '• Im aktuellen Datenmodell ist für ΔE* keine eigene '
        'Toleranzgrenze hinterlegt. Deshalb kann hier die Stärke der '
        'Abweichung beschrieben, aber keine ΔE*-Toleranzüberschreitung '
        'berechnet werden.',
      );

      return QSAnalysisResult(buffer.toString());
    }

    int violations = 0;
    int tooHigh = 0;
    int tooLow = 0;

    double sumDeviation = 0.0;
    double maxDeviation = double.negativeInfinity;
    double minDeviation = double.infinity;

    double sumExceedance = 0.0;
    double maxExceedance = 0.0;

    final lowerLimits = <double>{};
    final upperLimits = <double>{};

    for (final m in data) {
      late final double deviation;
      late final double? lower;
      late final double? upper;

      if (dimension == 'L*') {
        deviation = m.deltaL;
        lower = m.lowerL;
        upper = m.upperL;
      } else if (dimension == 'a*') {
        deviation = m.deltaA;
        lower = m.lowerA;
        upper = m.upperA;
      } else {
        deviation = m.deltaB;
        lower = m.lowerB;
        upper = m.upperB;
      }

      sumDeviation += deviation;
      if (deviation > maxDeviation) maxDeviation = deviation;
      if (deviation < minDeviation) minDeviation = deviation;

      if (lower != null) lowerLimits.add(lower);
      if (upper != null) upperLimits.add(upper);

      double exceedance = 0.0;

      if (upper != null && deviation > upper) {
        violations++;
        tooHigh++;
        exceedance = deviation - upper;
      } else if (lower != null && deviation < -lower) {
        violations++;
        tooLow++;
        exceedance = (-lower) - deviation;
      }

      if (exceedance > 0) {
        sumExceedance += exceedance;
        if (exceedance > maxExceedance) {
          maxExceedance = exceedance;
        }
      }
    }

    final averageDeviation = sumDeviation / data.length;
    final violationRate = violations / data.length * 100;
    final averageExceedance =
        violations > 0 ? sumExceedance / violations : 0.0;

    String directionText(double value) {
      if (dimension == 'L*') {
        if (value > 0) return 'heller';
        if (value < 0) return 'dunkler';
        return 'ohne erkennbare Helligkeitsverschiebung';
      }
      if (dimension == 'a*') {
        if (value > 0) return 'in Richtung Rot (+a*)';
        if (value < 0) return 'in Richtung Grün (-a*)';
        return 'ohne erkennbare Verschiebung auf der a*-Achse';
      }
      if (value > 0) return 'in Richtung Gelb (+b*)';
      if (value < 0) return 'in Richtung Blau (-b*)';
      return 'ohne erkennbare Verschiebung auf der b*-Achse';
    }

    final buffer = StringBuffer();

    buffer.writeln('Analyse $dimension für BA-Nr **$baNr**');
    if (artikel.isNotEmpty) {
      buffer.writeln('Artikel: **$artikel**');
    }
    if (year != null) {
      buffer.writeln('Zeitraum: $year');
    } else {
      buffer.writeln(
        'Zeitraum: ${_formatDate(data.first.datum)} '
        'bis ${_formatDate(data.last.datum)}',
      );
    }

    buffer.writeln();
    buffer.writeln('Ergebnis');
    buffer.writeln('• **${data.length} Messungen** ausgewertet.');
    buffer.writeln(
      '• **$violations von ${data.length} Messungen** liegen außerhalb '
      'der $dimension-Toleranz (${violationRate.toStringAsFixed(1)} %).',
    );
    buffer.writeln(
      '• Ø Δ$dimension: **${_signed(averageDeviation)}**.',
    );

    buffer.writeln();
    buffer.writeln('Toleranz');

    if (lowerLimits.length == 1 && upperLimits.length == 1) {
      final lower = lowerLimits.first;
      final upper = upperLimits.first;
      buffer.writeln(
        '• Verwendete $dimension-Toleranz: '
        '**-${_formatNumber(lower)} bis +${_formatNumber(upper)}**.',
      );
    } else if (lowerLimits.isNotEmpty || upperLimits.isNotEmpty) {
      buffer.writeln(
        '• Innerhalb der ausgewerteten Messungen wurden unterschiedliche '
        '$dimension-Toleranzgrenzen verwendet. Die Überschreitung wird '
        'deshalb für jede Messung gegen ihre tatsächlich hinterlegte '
        'Colibri-Toleranz berechnet.',
      );
    } else {
      buffer.writeln(
        '• Für $dimension sind in diesen Messungen keine auswertbaren '
        'Toleranzgrenzen vorhanden.',
      );
    }

    if (violations > 0) {
      buffer.writeln(
        '• Die n.i.O.-Messungen überschreiten ihre jeweilige '
        'Toleranzgrenze im Mittel um '
        '**${_formatNumber(averageExceedance)}**.',
      );
      buffer.writeln(
        '• Die größte Toleranzüberschreitung beträgt '
        '**${_formatNumber(maxExceedance)}**.',
      );
    }

    buffer.writeln();
    buffer.writeln('Einordnung');

    if (violations == 0) {
      buffer.writeln(
        '• $dimension liegt bei allen ausgewerteten Messungen innerhalb '
        'der zulässigen Colibri-Toleranz.',
      );
      buffer.writeln(
        '• Der mittlere Wert von Δ$dimension '
        '(${_signed(averageDeviation)}) zeigt ${directionText(averageDeviation)}, '
        'ohne dass die zulässigen Grenzen überschritten werden.',
      );
    } else {
      if (tooHigh > tooLow) {
        buffer.writeln(
          '• Die Abweichung liegt überwiegend oberhalb der oberen '
          '$dimension-Grenze. Die Messwerte verschieben sich damit '
          '${directionText(1)}.',
        );
      } else if (tooLow > tooHigh) {
        buffer.writeln(
          '• Die Abweichung liegt überwiegend unterhalb der unteren '
          '$dimension-Grenze. Die Messwerte verschieben sich damit '
          '${directionText(-1)}.',
        );
      } else {
        buffer.writeln(
          '• Die Toleranzüberschreitungen verteilen sich auf beide '
          'Richtungen der $dimension-Achse.',
        );
      }

      if (violations == data.length) {
        buffer.writeln(
          '• Alle ausgewerteten Messungen liegen außerhalb der Toleranz. '
          'Damit handelt es sich in den Messdaten nicht nur um einzelne '
          'Ausreißer, sondern um ein durchgängiges Muster innerhalb dieser BA.',
        );
      } else if (violations >= data.length * 0.8) {
        buffer.writeln(
          '• Der überwiegende Teil der Messungen liegt außerhalb der '
          'Toleranz. Das spricht in den Messdaten eher für ein '
          'durchgängiges Muster als für einzelne Ausreißer.',
        );
      } else if (violations <= data.length * 0.2) {
        buffer.writeln(
          '• Nur ein kleiner Teil der Messungen überschreitet die '
          'Toleranz. Die Auffälligkeit ist damit auf einzelne bzw. wenige '
          'Messungen konzentriert.',
        );
      } else {
        buffer.writeln(
          '• Die Toleranzüberschreitungen betreffen einen relevanten Teil '
          'der Messungen, jedoch nicht die gesamte BA.',
        );
      }

      if (averageDeviation > 0 &&
          upperLimits.length == 1 &&
          averageDeviation > upperLimits.first) {
        final meanBeyond = averageDeviation - upperLimits.first;
        buffer.writeln(
          '• Auch der Mittelwert liegt bereits '
          '**${_formatNumber(meanBeyond)} über der oberen Toleranzgrenze**. '
          'Die n.i.O.-Bewertung wird daher nicht nur durch einzelne '
          'Extremwerte verursacht.',
        );
      } else if (averageDeviation < 0 &&
          lowerLimits.length == 1 &&
          averageDeviation < -lowerLimits.first) {
        final meanBeyond = (-lowerLimits.first) - averageDeviation;
        buffer.writeln(
          '• Auch der Mittelwert liegt bereits '
          '**${_formatNumber(meanBeyond)} unterhalb der unteren '
          'Toleranzgrenze**. Die n.i.O.-Bewertung wird daher nicht nur '
          'durch einzelne Extremwerte verursacht.',
        );
      }
    }

    buffer.writeln();
    buffer.writeln('Empfohlene Prüfung');

    if (violations == 0) {
      buffer.writeln(
        '• Aus $dimension ergibt sich für diese BA aktuell keine '
        'unmittelbare Toleranzauffälligkeit.',
      );
    } else {
      buffer.writeln(
        '• Prüfen, ob die $dimension-Verschiebung bereits bei der ersten '
        'Messung vorhanden war oder sich während der Produktion entwickelt hat.',
      );
      if (artikel.isNotEmpty) {
        buffer.writeln(
          '• Andere BAs desselben Artikels $artikel gegenüberstellen, '
          'um zu prüfen, ob das Muster nur bei BA $baNr oder auch bei '
          'anderen Produktionen auftritt.',
        );
      }
      buffer.writeln(
        '• Die Messdaten zeigen Richtung und Stärke der Abweichung sowie '
        'die Überschreitung der hinterlegten Colibri-Toleranzen. '
        'Die physische Prozessursache lässt sich daraus allein jedoch '
        'nicht bestimmen.',
      );
    }

    return QSAnalysisResult(buffer.toString());
  }

  // ================================================================

  // BA COMPARISON

  // ================================================================

  QSAnalysisResult _baVergleich(

    List<String> baNrs,

    String? dimension,

    int? year,

  ) {

    if (baNrs.length < 2) {

      return const QSAnalysisResult(

        'Für einen Vergleich werden mindestens zwei BA-Nummern benötigt.',

      );

    }

    final comparison = <String, List<Measurement>>{};

    for (final baNr in baNrs) {

      comparison[baNr] = _filterByYear(year)

          .where(

            (m) => _baNrMatches(m.baNr, baNr),

          )

          .toList();

    }

    final missing = baNrs

        .where(

          (baNr) => comparison[baNr]!.isEmpty,

        )

        .toList();

    if (missing.isNotEmpty) {

      return QSAnalysisResult(

        'Für ${missing.map((e) => 'BA-$e').join(' und ')} '

        'wurden keine Messungen gefunden'

        '${year != null ? ' ($year)' : ''}.',

      );

    }

    final buffer = StringBuffer();

    if (dimension == null) {

      buffer.writeln(

        'Vergleich der BA-Nummern',

      );

    } else {

      buffer.writeln(

        'Vergleich $dimension: ${baNrs.map((e) => 'BA-$e').join(' vs. ')}',

      );

    }

    if (year != null) {

      buffer.writeln('Zeitraum: $year');

    }

    buffer.writeln();

    final rates = <String, double>{};

    for (final baNr in baNrs) {

      final data = comparison[baNr]!;

      final errors = data

          .where(

            (m) => _isNok(m),

          )

          .length;

      final rate =

          errors / data.length * 100;

      rates[baNr] = rate;

      if (dimension == null) {

        buffer.writeln(

          'BA-$baNr: $errors von ${data.length} '

          'Messungen nicht erfüllt '

          '(${rate.toStringAsFixed(1)} %)',

        );

      } else {

        final metric = _dimensionMetrics(

          data,

          dimension,

        );

        buffer.writeln(

          'BA-$baNr: ${metric.summary}',

        );

      }

    }

    buffer.writeln();

    if (dimension == null) {

      final sorted = rates.entries.toList()

        ..sort(

          (a, b) => a.value.compareTo(b.value),

        );

      final best = sorted.first;

      final worst = sorted.last;

      final difference =

          worst.value - best.value;

      if ((worst.value - best.value).abs() < 0.0001) {
        buffer.write(
          'Die Fehlerquoten der verglichenen BAs sind identisch '
          '(${best.value.toStringAsFixed(1)} %).',
        );
      } else {

        buffer.writeln(

          'Auffälliger ist BA-${worst.key} mit '

          '${worst.value.toStringAsFixed(1)} % Fehlerquote.',

        );

        buffer.write(

          'BA-${best.key} liegt bei '

          '${best.value.toStringAsFixed(1)} %. '

          'Unterschied: '

          '${difference.toStringAsFixed(1)} Prozentpunkte.',

        );

      }

    } else {

      final metrics = <String, _DimensionMetric>{};

      for (final baNr in baNrs) {

        metrics[baNr] = _dimensionMetrics(

          comparison[baNr]!,

          dimension,

        );

      }

      final sorted = metrics.entries.toList()

        ..sort(

          (a, b) =>

              b.value.score.compareTo(a.value.score),

        );

      final most = sorted.first;

      buffer.write(

        'Bei $dimension ist BA-${most.key} '

        'auffälliger nach dem Vergleichswert '

        '(${most.value.score.toStringAsFixed(1)}).',

      );

    }

    if (dimension == null) {

      buffer.writeln();

      buffer.writeln();

      buffer.writeln('Entwicklung über die Zeit:');

      final months = <String>{};

      for (final baNr in baNrs) {

        for (final m in comparison[baNr]!) {

          months.add(

            '${m.datum.year}-'

            '${m.datum.month.toString().padLeft(2, '0')}',

          );

        }

      }

      final sortedMonths = months.toList()..sort();

      for (final month in sortedMonths) {

        final parts = <String>[];

        for (final baNr in baNrs) {

          final data = comparison[baNr]!

              .where(

                (m) =>

                    '${m.datum.year}-'

                    '${m.datum.month.toString().padLeft(2, '0')}' ==

                    month,

              )

              .toList();

          if (data.isEmpty) {

            parts.add('BA-$baNr: keine Daten');

            continue;

          }

          final errors = data

              .where(

                (m) => _isNok(m),

              )

              .length;

          final rate =

              errors / data.length * 100;

          parts.add(

            'BA-$baNr: ${rate.toStringAsFixed(1)} %',

          );

        }

        buffer.writeln(

          '${_formatMonth(month)} | ${parts.join(' | ')}',

        );

      }

    }

    return QSAnalysisResult(buffer.toString());

  }

  _DimensionMetric _dimensionMetrics(

    List<Measurement> data,

    String dimension,

  ) {

    int violations = 0;

    double sumAbs = 0;

    double maxAbs = 0;

    for (final m in data) {

      double value = 0;

      bool outside = false;

      if (dimension == 'L*') {

        value = m.deltaL;

        outside = _isOutsideLimits(value, m.lowerL, m.upperL);

      } else if (dimension == 'a*') {

        value = m.deltaA;

        outside = _isOutsideLimits(value, m.lowerA, m.upperA);

      } else if (dimension == 'b*') {

        value = m.deltaB;

        outside = _isOutsideLimits(value, m.lowerB, m.upperB);

      } else if (dimension == 'ΔE*') {

        value = m.deltaE;

        outside = false;

      }

      sumAbs += value.abs();

      if (value.abs() > maxAbs) {

        maxAbs = value.abs();

      }

      if (outside) {

        violations++;

      }

    }

    final average =

        data.isEmpty ? 0.0 : sumAbs / data.length;

    if (dimension == 'ΔE*') {

      return _DimensionMetric(

        score: average,

        summary:

            'Ø |ΔE*| ${_formatNumber(average)}, '

            'Maximum ${_formatNumber(maxAbs)}',

      );

    }

    final rate =

        data.isEmpty ? 0.0 : violations / data.length * 100;

    return _DimensionMetric(

      score: rate,

      summary:

          '$violations von ${data.length} außerhalb '

          '(${rate.toStringAsFixed(1)} %)',

    );

  }

  // ================================================================

  // BA DEVELOPMENT / TREND

  // ================================================================

  QSAnalysisResult _baEntwicklung(
    String baNr,
    String? dimension,
    int? year,
  ) {
    final data = _filterByYear(year)
        .where((m) => _baNrMatches(m.baNr, baNr))
        .toList()
      ..sort((a, b) => a.datum.compareTo(b.datum));

    if (data.isEmpty) {
      return QSAnalysisResult(
        'Für BA-Nr $baNr wurden keine Messungen gefunden'
        '${year != null ? ' ($year)' : ''}.',
      );
    }

    // Within a BA, the sequence of measurements is more meaningful
    // than grouping them by calendar month.
    if (dimension != null) {
      return _baDimensionEntwicklung(
        baNr,
        data,
        dimension,
        year,
      );
    }

    final artikel = _mostCommonArticle(data);
    final totalNok = data.where(_isNok).length;
    final totalRate = totalNok / data.length * 100;

    final buffer = StringBuffer();
    buffer.writeln('Entwicklung von BA-Nr **$baNr**');
    if (artikel.isNotEmpty) {
      buffer.writeln('Artikel: **$artikel**');
    }
    buffer.writeln(
      'Zeitraum: ${_formatDate(data.first.datum)} '
      'bis ${_formatDate(data.last.datum)}',
    );

    buffer.writeln();
    buffer.writeln('Ergebnis');
    buffer.writeln(
      '• **${data.length} Messungen** ausgewertet, '
      '**$totalNok n.i.O. (${totalRate.toStringAsFixed(1)} %)**.',
    );

    if (data.length < 3) {
      buffer.writeln();
      buffer.writeln('Einordnung');
      buffer.writeln(
        '• Für eine belastbare Entwicklung innerhalb der BA sind '
        'zu wenige Messungen vorhanden.',
      );
      buffer.writeln(
        '• Die vorhandenen Einzelmessungen können beschrieben werden, '
        'aber daraus sollte kein zeitlicher Trend abgeleitet werden.',
      );
      return QSAnalysisResult(buffer.toString());
    }

    // Comparison of the first and last third. This makes the trend
    // less dependent on a single first or last measurement.
    final windowSize = math.max(1, (data.length / 3).ceil());
    final firstWindow = data.take(windowSize).toList();
    final lastWindow = data.skip(data.length - windowSize).toList();

    double nokRate(List<Measurement> values) {
      return values.where(_isNok).length / values.length * 100;
    }

    final firstRate = nokRate(firstWindow);
    final lastRate = nokRate(lastWindow);
    final difference = lastRate - firstRate;

    buffer.writeln(
      '• Beginn der BA: **${firstRate.toStringAsFixed(1)} % n.i.O.** '
      '(${firstWindow.length} Messungen).',
    );
    buffer.writeln(
      '• Ende der BA: **${lastRate.toStringAsFixed(1)} % n.i.O.** '
      '(${lastWindow.length} Messungen).',
    );

    buffer.writeln();
    buffer.writeln('Einordnung');

    if (firstRate == 100.0 && lastRate == 100.0) {
      buffer.writeln(
        '• Die Messungen sind sowohl zu Beginn als auch am Ende '
        '**durchgehend n.i.O.**. Eine Verbesserung der Fehlerquote '
        'ist im Messverlauf nicht erkennbar.',
      );
    } else if (firstRate == 0.0 && lastRate == 0.0) {
      if (totalNok == 0) {
        buffer.writeln(
          '• Die BA bleibt im gesamten Messverlauf **durchgehend i.O.**.',
        );
      } else {
        buffer.writeln(
          '• Beginn und Ende der BA sind i.O.; die n.i.O.-Messungen '
          'treten **innerhalb des Produktionsverlaufs** auf.',
        );
      }
    } else if (difference <= -10.0) {
      buffer.writeln(
        '• Die Fehlerquote nimmt im Verlauf der BA ab. '
        'Die Messdaten zeigen damit **eine Verbesserung zum Ende hin**.',
      );
      if (lastRate > 0) {
        buffer.writeln(
          '• Trotz dieser Verbesserung sind am Ende weiterhin '
          'n.i.O.-Messungen vorhanden.',
        );
      }
    } else if (difference >= 10.0) {
      buffer.writeln(
        '• Die Fehlerquote nimmt im Verlauf der BA zu. '
        'Die Messdaten zeigen damit **eine Verschlechterung zum Ende hin**.',
      );
    } else {
      if (totalRate >= 80.0) {
        buffer.writeln(
          '• Die hohe n.i.O.-Quote bleibt über den Messverlauf '
          '**weitgehend durchgängig bestehen**.',
        );
      } else if (totalRate <= 20.0) {
        buffer.writeln(
          '• Die Fehlerquote verändert sich zwischen Beginn und Ende nur '
          'gering. Die wenigen n.i.O.-Messungen sind eher punktuell verteilt.',
        );
      } else {
        buffer.writeln(
          '• Zwischen Beginn und Ende ist keine deutliche Veränderung '
          'der Fehlerquote erkennbar.',
        );
      }
    }

    buffer.writeln(
      '• Für die Richtung der Farbverschiebung können L*, a* oder b* '
      'separat über den Messverlauf analysiert werden.',
    );

    return QSAnalysisResult(buffer.toString());
  }

  QSAnalysisResult _baDimensionEntwicklung(
    String baNr,
    List<Measurement> data,
    String dimension,
    int? year,
  ) {
    if (data.isEmpty) {
      return const QSAnalysisResult(
        'Keine Messdaten für die Analyse verfügbar.',
      );
    }

    final artikel = _mostCommonArticle(data);

    double valueOf(Measurement m) {
      if (dimension == 'L*') return m.deltaL;
      if (dimension == 'a*') return m.deltaA;
      if (dimension == 'b*') return m.deltaB;
      return m.deltaE;
    }

    double? lowerOf(Measurement m) {
      if (dimension == 'L*') return m.lowerL;
      if (dimension == 'a*') return m.lowerA;
      if (dimension == 'b*') return m.lowerB;
      return null;
    }

    double? upperOf(Measurement m) {
      if (dimension == 'L*') return m.upperL;
      if (dimension == 'a*') return m.upperA;
      if (dimension == 'b*') return m.upperB;
      return null;
    }

    double averageValue(List<Measurement> values) {
      return values
              .map(valueOf)
              .fold<double>(0.0, (sum, value) => sum + value) /
          values.length;
    }

    final buffer = StringBuffer();
    buffer.writeln('Entwicklung $dimension für BA-Nr **$baNr**');
    if (artikel.isNotEmpty) {
      buffer.writeln('Artikel: **$artikel**');
    }
    buffer.writeln(
      'Zeitraum: ${_formatDate(data.first.datum)} '
      'bis ${_formatDate(data.last.datum)}',
    );

    if (data.length < 3) {
      buffer.writeln();
      buffer.writeln('Einordnung');
      buffer.writeln(
        '• Für eine belastbare Entwicklung innerhalb der BA sind '
        'zu wenige Messungen vorhanden.',
      );
      return QSAnalysisResult(buffer.toString());
    }

    final windowSize = math.max(1, (data.length / 3).ceil());
    final firstWindow = data.take(windowSize).toList();
    final lastWindow = data.skip(data.length - windowSize).toList();

    final firstAverage = averageValue(firstWindow);
    final lastAverage = averageValue(lastWindow);
    final valueDifference = lastAverage - firstAverage;

    // ΔE* hat im aktuellen Datenmodell keine eigene Toleranz.
    if (dimension == 'ΔE*') {
      final allAverage = averageValue(data);

      buffer.writeln();
      buffer.writeln('Ergebnis');
      buffer.writeln('• **${data.length} Messungen** ausgewertet.');
      buffer.writeln(
        '• Beginn: Ø ΔE* **${_formatNumber(firstAverage)}**.',
      );
      buffer.writeln(
        '• Ende: Ø ΔE* **${_formatNumber(lastAverage)}**.',
      );
      buffer.writeln(
        '• Gesamtmittel: Ø ΔE* **${_formatNumber(allAverage)}**.',
      );

      buffer.writeln();
      buffer.writeln('Einordnung');

      if (valueDifference <= -0.10) {
        buffer.writeln(
          '• ΔE* nimmt im Verlauf der BA ab. Die gesamte '
          'Farbabweichung zum Standard wird damit **kleiner**.',
        );
      } else if (valueDifference >= 0.10) {
        buffer.writeln(
          '• ΔE* nimmt im Verlauf der BA zu. Die gesamte '
          'Farbabweichung zum Standard wird damit **größer**.',
        );
      } else {
        buffer.writeln(
          '• Zwischen Beginn und Ende ist bei ΔE* keine deutliche '
          'Veränderung erkennbar.',
        );
      }

      buffer.writeln(
        '• Für ΔE* ist im aktuellen Datenmodell keine eigene '
        'Toleranzgrenze hinterlegt. Deshalb wird hier die Entwicklung '
        'der Abweichungsstärke beschrieben, nicht i.O./n.i.O. nach ΔE*.',
      );

      return QSAnalysisResult(buffer.toString());
    }

    bool outside(Measurement m) {
      return _isOutsideLimits(
        valueOf(m),
        lowerOf(m),
        upperOf(m),
      );
    }

    double exceedance(Measurement m) {
      final value = valueOf(m);
      final lower = lowerOf(m);
      final upper = upperOf(m);

      if (upper != null && value > upper) {
        return value - upper;
      }
      if (lower != null && value < -lower) {
        return (-lower) - value;
      }
      return 0.0;
    }

    double violationRate(List<Measurement> values) {
      return values.where(outside).length / values.length * 100;
    }

    double averageExceedance(List<Measurement> values) {
      final outsideValues = values.where(outside).toList();
      if (outsideValues.isEmpty) return 0.0;
      return outsideValues
              .map(exceedance)
              .fold<double>(0.0, (sum, value) => sum + value) /
          outsideValues.length;
    }

    final totalViolations = data.where(outside).length;
    final totalRate = totalViolations / data.length * 100;

    final firstRate = violationRate(firstWindow);
    final lastRate = violationRate(lastWindow);
    final firstExceedance = averageExceedance(firstWindow);
    final lastExceedance = averageExceedance(lastWindow);

    buffer.writeln();
    buffer.writeln('Ergebnis');
    buffer.writeln(
      '• **$totalViolations von ${data.length} Messungen** liegen außerhalb '
      'der $dimension-Toleranz (**${totalRate.toStringAsFixed(1)} %**).',
    );
    buffer.writeln(
      '• Beginn: Ø Δ$dimension **${_signed(firstAverage)}**, '
      '**${firstRate.toStringAsFixed(1)} % außerhalb**.',
    );
    buffer.writeln(
      '• Ende: Ø Δ$dimension **${_signed(lastAverage)}**, '
      '**${lastRate.toStringAsFixed(1)} % außerhalb**.',
    );

    if (firstRate > 0) {
      buffer.writeln(
        '• Mittlere Toleranzüberschreitung zu Beginn: '
        '**${_formatNumber(firstExceedance)}**.',
      );
    }
    if (lastRate > 0) {
      buffer.writeln(
        '• Mittlere Toleranzüberschreitung am Ende: '
        '**${_formatNumber(lastExceedance)}**.',
      );
    }

    buffer.writeln();
    buffer.writeln('Einordnung');

    if (firstRate == 100.0 && lastRate == 100.0) {
      final exceedanceChange = lastExceedance - firstExceedance;

      if (exceedanceChange <= -0.05) {
        buffer.writeln(
          '• $dimension liegt zu Beginn und am Ende **durchgehend außerhalb '
          'der Toleranz**. Die Überschreitung wird jedoch kleiner: '
          'Die Werte bewegen sich **in Richtung Toleranzgrenze**, '
          'ohne sie bisher zu erreichen.',
        );
      } else if (exceedanceChange >= 0.05) {
        buffer.writeln(
          '• $dimension liegt zu Beginn und am Ende **durchgehend außerhalb '
          'der Toleranz**. Die Überschreitung wird größer: '
          'Die Abweichung **verstärkt sich im Messverlauf**.',
        );
      } else {
        buffer.writeln(
          '• $dimension liegt zu Beginn und am Ende **durchgehend außerhalb '
          'der Toleranz**. Auch die Stärke der Überschreitung verändert sich '
          'nur gering. Es ist **keine relevante Verbesserung** erkennbar.',
        );
      }
    } else if (firstRate > lastRate) {
      buffer.writeln(
        '• Der Anteil außerhalb der $dimension-Toleranz nimmt im Verlauf ab '
        '(**${firstRate.toStringAsFixed(1)} % → '
        '${lastRate.toStringAsFixed(1)} %**).',
      );
      if (lastRate == 0.0) {
        buffer.writeln(
          '• Das Ende der BA liegt in diesem Vergleichsfenster vollständig '
          'innerhalb der $dimension-Toleranz.',
        );
      } else {
        buffer.writeln(
          '• Es ist eine Verbesserung erkennbar, am Ende bestehen jedoch '
          'weiterhin Toleranzüberschreitungen.',
        );
      }
    } else if (firstRate < lastRate) {
      buffer.writeln(
        '• Der Anteil außerhalb der $dimension-Toleranz nimmt im Verlauf zu '
        '(**${firstRate.toStringAsFixed(1)} % → '
        '${lastRate.toStringAsFixed(1)} %**). '
        'Die Situation verschlechtert sich zum Ende hin.',
      );
    } else if (totalViolations == 0) {
      buffer.writeln(
        '• $dimension bleibt über den ausgewerteten Messverlauf '
        '**innerhalb der Toleranz**.',
      );
      if (valueDifference.abs() >= 0.10) {
        buffer.writeln(
          '• Der Mittelwert verschiebt sich von '
          '${_signed(firstAverage)} auf ${_signed(lastAverage)}, '
          'ohne die zulässigen Grenzen zu überschreiten.',
        );
      }
    } else {
      buffer.writeln(
        '• Der Anteil außerhalb der Toleranz verändert sich zwischen '
        'Beginn und Ende kaum.',
      );
      if ((lastExceedance - firstExceedance) <= -0.05) {
        buffer.writeln(
          '• Die Stärke der vorhandenen Überschreitungen nimmt jedoch ab.',
        );
      } else if ((lastExceedance - firstExceedance) >= 0.05) {
        buffer.writeln(
          '• Die Stärke der vorhandenen Überschreitungen nimmt jedoch zu.',
        );
      }
    }

    buffer.writeln(
      '• Bewertet werden das **erste und letzte Drittel der Messfolge**, '
      'damit der Trend nicht von einer einzelnen Messung bestimmt wird.',
    );

    return QSAnalysisResult(buffer.toString());
  }


  String _formatDate(DateTime date) {

    return '${date.day.toString().padLeft(2, '0')}.'

        '${date.month.toString().padLeft(2, '0')}.'

        '${date.year}';

  }

  // ================================================================

  // BA STATUS

  // ================================================================

  QSAnalysisResult _baWhyAnalyse(
  String baNr,
  int? year,
) {
  final data = _filterByYear(year)
      .where((m) => _baNrMatches(m.baNr, baNr))
      .toList()
    ..sort((a, b) => a.datum.compareTo(b.datum));

  if (data.isEmpty) {
    return QSAnalysisResult(
      'Für BA-Nr $baNr wurden keine Messungen gefunden'
      '${year != null ? ' ($year)' : ''}.',
    );
  }

  final profile = _buildBaProfile(data);
  final artikel = _mostCommonArticle(data);

  final dimensions = <_ViolationSummary>[
    _ViolationSummary(
      'L*',
      profile.lViolations,
      profile.total,
    ),
    _ViolationSummary(
      'a*',
      profile.aViolations,
      profile.total,
    ),
    _ViolationSummary(
      'b*',
      profile.bViolations,
      profile.total,
    ),
  ]..sort((a, b) => b.count.compareTo(a.count));

  final dominant = dimensions.first;

  final buffer = StringBuffer();

  buffer.writeln('Warum ist BA-Nr **$baNr** n.i.O.?');

  if (artikel.isNotEmpty) {
    buffer.writeln('Artikel: **$artikel**');
  }

  buffer.writeln(
    'Zeitraum: ${_formatDate(data.first.datum)} '
    'bis ${_formatDate(data.last.datum)}',
  );

  buffer.writeln();
  buffer.writeln('Ergebnis');

  if (profile.nok == 0) {
    buffer.writeln(
      '• Die vorhandenen Messdaten zeigen für diese BA '
      'keine n.i.O.-Messungen.',
    );

    buffer.writeln(
      '• ${profile.total} Messungen wurden ausgewertet, '
      '${profile.ok} davon sind i.O.',
    );

    return QSAnalysisResult(buffer.toString());
  }

  buffer.writeln(
    '• **${profile.nok} von ${profile.total} Messungen** sind n.i.O. '
    '→ Fehlerquote **${profile.errorRate.toStringAsFixed(1)} %**.',
  );

  buffer.writeln();
  buffer.writeln('Entscheidende Abweichung');

  if (dominant.count > 0) {
    buffer.writeln(
      '• **${dominant.name}** ist die häufigste Toleranzabweichung: '
      '**${dominant.count} von ${dominant.total} Messungen** '
      'liegen außerhalb der realen Colibri-Toleranz.',
    );
  } else {
    buffer.writeln(
      '• Die BA enthält n.i.O.-Messungen, aber anhand der '
      'verfügbaren L*-, a*- und b*-Grenzen lässt sich keine '
      'dominante Toleranzüberschreitung bestimmen.',
    );
  }

  if (profile.lViolations > 0) {
    if (profile.lTooHigh > profile.lTooLow) {
      buffer.writeln(
        '• L*: ${profile.lTooHigh} Messungen liegen oberhalb '
        'der oberen Grenze → überwiegende Verschiebung '
        'in Richtung heller.',
      );
    } else if (profile.lTooLow > profile.lTooHigh) {
      buffer.writeln(
        '• L*: ${profile.lTooLow} Messungen liegen unterhalb '
        'der unteren Grenze → überwiegende Verschiebung '
        'in Richtung dunkler.',
      );
    }
  }

  if (profile.aViolations > 0) {
    final direction = profile.aTooHigh >= profile.aTooLow
        ? 'Rot (+a*)'
        : 'Grün (-a*)';

    buffer.writeln(
      '• a*: ${profile.aViolations} Toleranzüberschreitungen, '
      'überwiegend in Richtung $direction.',
    );
  }

  if (profile.bViolations > 0) {
    final direction = profile.bTooHigh >= profile.bTooLow
        ? 'Gelb (+b*)'
        : 'Blau (-b*)';

    buffer.writeln(
      '• b*: ${profile.bViolations} Toleranzüberschreitungen, '
      'überwiegend in Richtung $direction.',
    );
  }

  buffer.writeln();
  buffer.writeln('Einordnung');

  buffer.writeln(
    '• Die n.i.O.-Einstufung lässt sich in den Messdaten '
    'vor allem auf ${dominant.name} zurückführen.',
  );

  if (dominant.count == profile.total) {
    buffer.writeln(
      '• Diese Abweichung betrifft alle ausgewerteten Messungen '
      'der BA und ist damit kein einzelner Ausreißer.',
    );
  } else if (dominant.count >= profile.total * 0.8) {
    buffer.writeln(
      '• Diese Abweichung betrifft den überwiegenden Teil '
      'der Messungen und spricht in den Messdaten eher für '
      'ein durchgängiges Muster als für einzelne Ausreißer.',
    );
  }

  buffer.writeln();
  buffer.writeln('Hinweis');

  buffer.writeln(
    '• Die Messdaten erklären, warum die BA als n.i.O. '
    'bewertet wird. Sie zeigen jedoch nicht automatisch, '
    'welche physische Prozessursache die Abweichung verursacht hat.',
  );

  return QSAnalysisResult(buffer.toString());
}

  QSAnalysisResult _baDeepAnalyse(
    String baNr,
    int? year,
  ) {
    final data = _filterByYear(year)
        .where((m) => _baNrMatches(m.baNr, baNr))
        .toList()
      ..sort((a, b) => a.datum.compareTo(b.datum));

    if (data.isEmpty) {
      return QSAnalysisResult(
        'Für BA-Nr $baNr wurden keine Messungen gefunden'
        '${year != null ? ' ($year)' : ''}.',
      );
    }

    final profile = _buildBaProfile(data);
    final artikel = _mostCommonArticle(data);
    final sameArticle = _filterByYear(year)
        .where((m) => m.artikelnummer.trim() == artikel && !_baNrMatches(m.baNr, baNr))
        .toList();

    final otherBaGroups = <String, List<Measurement>>{};
    for (final m in sameArticle) {
      final key = m.baNr.trim();
      if (key.isEmpty) continue;
      otherBaGroups.putIfAbsent(key, () => []).add(m);
    }

    final otherProfiles = otherBaGroups.entries
        .map((e) => _NamedBaProfile(e.key, _buildBaProfile(e.value)))
        .toList()
      ..sort((a, b) => a.profile.errorRate.compareTo(b.profile.errorRate));

    final buffer = StringBuffer();
    buffer.writeln('Analyse BA-Nr **$baNr**');
    if (artikel.isNotEmpty) buffer.writeln('Artikel: **$artikel**');
    buffer.writeln('Zeitraum: ${_formatDate(data.first.datum)} bis ${_formatDate(data.last.datum)}');
    buffer.writeln();
    buffer.writeln('Ergebnis');
    buffer.writeln('• **${profile.total} Messungen** ausgewertet.');
    buffer.writeln('• **${profile.nok} n.i.O. / ${profile.ok} i.O.** → Fehlerquote **${profile.errorRate.toStringAsFixed(1)} %**.');
    buffer.writeln('• Ø ΔL*: ${_signed(profile.avgDeltaL)}, Ø Δa*: ${_signed(profile.avgDeltaA)}, Ø Δb*: ${_signed(profile.avgDeltaB)}, Ø ΔE*: ${_formatNumber(profile.avgDeltaE)}.');

    buffer.writeln();
    buffer.writeln('Auffälligkeiten');
    if (profile.nok == 0) {
      buffer.writeln('• In dieser BA wurde keine n.i.O.-Messung erkannt.');
    } else {
      final dims = <_ViolationSummary>[
        _ViolationSummary('L*', profile.lViolations, profile.total),
        _ViolationSummary('a*', profile.aViolations, profile.total),
        _ViolationSummary('b*', profile.bViolations, profile.total),
      ]..sort((a, b) => b.count.compareTo(a.count));
      final dominant = dims.first;
      buffer.writeln('• Hauptauffälligkeit: **${dominant.name}** – **${dominant.count} von ${dominant.total} Messungen** außerhalb der realen Colibri-Toleranz.');
      if (profile.lViolations > 0) {
        if (profile.lTooHigh > profile.lTooLow) {
          buffer.writeln('• L* verschiebt sich überwiegend nach oben: Die Teile werden zu hell gemessen (${profile.lTooHigh} Messungen oberhalb der oberen L*-Grenze).');
        } else if (profile.lTooLow > profile.lTooHigh) {
          buffer.writeln('• L* verschiebt sich überwiegend nach unten: Die Teile werden zu dunkel gemessen (${profile.lTooLow} Messungen unterhalb der unteren L*-Grenze).');
        }
      }
      if (profile.aViolations > 0) {
        final direction = profile.aTooHigh >= profile.aTooLow ? 'Richtung Rot (+a*)' : 'Richtung Grün (-a*)';
        buffer.writeln('• a*: stärkere Abweichung in $direction.');
      }
      if (profile.bViolations > 0) {
        final direction = profile.bTooHigh >= profile.bTooLow ? 'Richtung Gelb (+b*)' : 'Richtung Blau (-b*)';
        buffer.writeln('• b*: stärkere Abweichung in $direction.');
      }

      final systematic = _systematicAssessment(profile);
      buffer.writeln('• Prozessbild: $systematic');
    }

    if (otherProfiles.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Vergleich mit anderen BAs desselben Artikels');
      final best = otherProfiles.first;
      final recent = otherProfiles.toList()
        ..sort((a, b) => b.profile.lastDate.compareTo(a.profile.lastDate));
      final latestOther = recent.first;
      buffer.writeln('• Es wurden ${otherProfiles.length} weitere BAs für Artikel $artikel gefunden.');
      buffer.writeln('• Vergleichs-BA mit niedrigster Fehlerquote: BA ${best.baNr} – ${best.profile.errorRate.toStringAsFixed(1)} % n.i.O., Ø ΔL* ${_signed(best.profile.avgDeltaL)}, Ø ΔE* ${_formatNumber(best.profile.avgDeltaE)}.');
      if (latestOther.baNr != best.baNr) {
        buffer.writeln('• Zeitlich nächste verfügbare Vergleichs-BA: BA ${latestOther.baNr} – ${latestOther.profile.errorRate.toStringAsFixed(1)} % n.i.O.');
      }
      final dlChange = profile.avgDeltaL - best.profile.avgDeltaL;
      final daChange = profile.avgDeltaA - best.profile.avgDeltaA;
      final dbChange = profile.avgDeltaB - best.profile.avgDeltaB;
      final changes = <MapEntry<String,double>>[
        MapEntry('ΔL*', dlChange.abs()), MapEntry('Δa*', daChange.abs()), MapEntry('Δb*', dbChange.abs())
      ]..sort((a,b)=>b.value.compareTo(a.value));
      buffer.writeln('• Größter mittlerer Unterschied zur Vergleichs-BA liegt bei ${changes.first.key} (${_formatNumber(changes.first.value)}).');
    }

    buffer.writeln();
    buffer.writeln('Empfohlene Prüfung');

    if (profile.nok == 0) {
      buffer.writeln(
        '• Keine unmittelbare Maßnahme aus den Farbmessdaten ableitbar. '
        'Verlauf bei weiteren Messungen beobachten.',
      );
    } else {
      final hasUnauffaelligeVergleichsBa = otherProfiles.any(
        (p) => p.profile.errorRate < 100.0,
      );

      if (hasUnauffaelligeVergleichsBa) {
        buffer.writeln(
          '• Zuerst die dominante Abweichung (${_dominantDimension(profile)}) '
          'prüfen und mit einer weniger auffälligen BA desselben Artikels vergleichen.',
        );
      } else if (otherProfiles.isNotEmpty) {
        buffer.writeln(
          '• Zuerst die dominante Abweichung (${_dominantDimension(profile)}) '
          'prüfen und mit den verfügbaren BAs desselben Artikels vergleichen. '
          'Dabei berücksichtigen, dass auch die Vergleichs-BAs eine Fehlerquote '
          'von 100.0 % aufweisen.',
        );
      } else {
        buffer.writeln(
          '• Zuerst die dominante Abweichung (${_dominantDimension(profile)}) '
          'innerhalb dieser BA genauer untersuchen.',
        );
      }

      if (otherProfiles.isNotEmpty) {
        buffer.writeln(
          '• Prozessbedingungen, Material/Charge und relevante Einstellungen '
          'zwischen BA $baNr und den Vergleichs-BAs gegenüberstellen.',
        );
      }

      buffer.writeln(
        '• Prüfen, ob die Abweichung bereits ab der ersten Messung vorhanden ist '
        'oder sich innerhalb der BA entwickelt.',
      );
      buffer.writeln(
        '• Die Colibri-Daten zeigen Richtung und Stärke der Farbabweichung, '
        'aber nicht automatisch deren physische Prozessursache. '
        'Prozessursachen sind daher als Prüfhypothesen zu behandeln.',
      );
    }

    return QSAnalysisResult(buffer.toString());
  }

  // ================================================================

  // GENERAL

  // ================================================================

  QSAnalysisResult _allgemeineStatistik(int? year) {

    final data = _filterByYear(year);

    if (data.isEmpty) {

      return QSAnalysisResult(

        'Es sind keine Messdaten verfügbar'

        '${year != null ? ' ($year)' : ''}.',

      );

    }

    final gesamt = data.length;

    final erfuellt = data

        .where(

          (m) => _isOk(m)

        )

        .length;

    final nichtErfuellt = data

        .where(

          (m) => _isNok(m),

        )

        .length;

    final erfuelltQuote =

        erfuellt / gesamt * 100;

    final fehlerquote =

        nichtErfuellt / gesamt * 100;

    final buffer = StringBuffer();

    buffer.writeln('QS-Messstatistik');

    if (year != null) {

      buffer.writeln('Zeitraum: $year');

    }

    buffer.writeln();

    buffer.writeln(

      'Gesamt: $gesamt Messungen',

    );

    buffer.writeln(

      'Erfüllt: $erfuellt '

      '(${erfuelltQuote.toStringAsFixed(1)} %)',

    );

    buffer.write(

      'Nicht erfüllt: $nichtErfuellt '

      '(${fehlerquote.toStringAsFixed(1)} %)',

    );

    return QSAnalysisResult(buffer.toString());

  }

  // ================================================================

  // TOLERANCE

  // ================================================================

  QSAnalysisResult _messungenAusserhalbToleranz(int? year) {

    final data = _filterByYear(year);

    if (data.isEmpty) {

      return const QSAnalysisResult(

        'Es sind keine Messdaten verfügbar.',

      );

    }

    final ausserhalb = data

        .where(

          (m) => _isNok(m),

        )

        .toList();

    if (ausserhalb.isEmpty) {

      return const QSAnalysisResult(

        'Es wurden keine Messungen außerhalb der Toleranz gefunden.',

      );

    }

    int l = 0;

    int a = 0;

    int b = 0;

    for (final m in ausserhalb) {

      if (_isOutsideLimits(m.deltaL, m.lowerL, m.upperL)) l++;

      if (_isOutsideLimits(m.deltaA, m.lowerA, m.upperA)) a++;

      if (_isOutsideLimits(m.deltaB, m.lowerB, m.upperB)) b++;

    }

    final values = <String, int>{

      'L*': l,

      'a*': a,

      'b*': b,

    };

    final sorted = values.entries.toList()

      ..sort(

        (x, y) => y.value.compareTo(x.value),

      );

    final buffer = StringBuffer();

    buffer.writeln(

      '${ausserhalb.length} Messungen sind nicht erfüllt.',

    );

    if (year != null) {

      buffer.writeln('Zeitraum: $year');

    }

    buffer.writeln();

    buffer.writeln('Überschrittene Toleranzen:');

    for (final entry in sorted) {

      buffer.writeln(

        '${entry.key}: ${entry.value}',

      );

    }

    buffer.writeln();

    buffer.write(

      '${sorted.first.key} ist dabei die häufigste '

      'Toleranzüberschreitung.',

    );

    return QSAnalysisResult(buffer.toString());

  }

  // ================================================================

  // MEASUREMENT PARAMETER WITHOUT A SPECIFIED DIMENSION

  // ================================================================

  QSAnalysisResult _messgroesseMitMeistenAbweichungen(

    int? year,

  ) {

    final data = _filterByYear(year);

    if (data.isEmpty) {

      return const QSAnalysisResult(

        'Es sind keine Messdaten verfügbar.',

      );

    }

    int l = 0;

    int a = 0;

    int b = 0;

    for (final m in data) {

      if (_isOutsideLimits(m.deltaL, m.lowerL, m.upperL)) l++;

      if (_isOutsideLimits(m.deltaA, m.lowerA, m.upperA)) a++;

      if (_isOutsideLimits(m.deltaB, m.lowerB, m.upperB)) b++;

    }

    final values = <String, int>{

      'L*': l,

      'a*': a,

      'b*': b,

    };

    final sorted = values.entries.toList()

      ..sort(

        (x, y) => y.value.compareTo(x.value),

      );

    final buffer = StringBuffer();

    buffer.writeln(

      'Welche Messgröße ist am auffälligsten?',

    );

    if (year != null) {

      buffer.writeln('Zeitraum: $year');

    }

    buffer.writeln();

    buffer.writeln(

      'Am häufigsten außerhalb der Toleranz: '

      '${sorted.first.key} '

      '(${sorted.first.value} Fälle).',

    );

    buffer.writeln();

    buffer.writeln('Aufschlüsselung:');

    for (final entry in sorted) {

      buffer.writeln(

        '${entry.key}: ${entry.value}',

      );

    }

    return QSAnalysisResult(buffer.toString());

  }

  // ================================================================

  // ARTICLE + DIMENSION

  // ================================================================

  QSAnalysisResult _artikelNachMessgroesse(

    String dimension,

    int? year,

  ) {

    final data = _filterByYear(year)
      .where((m) => m.artikelnummer.trim().isNotEmpty)
      .toList();

    if (data.isEmpty) {

      return const QSAnalysisResult(

        'Es sind keine Messdaten verfügbar.',

      );

    }

    final total = <String, int>{};

    final errors = <String, int>{};

    for (final m in data) {

      final artikel = m.artikelnummer;

      total[artikel] =

          (total[artikel] ?? 0) + 1;

      bool outside = false;

      if (dimension == 'L*') {

        outside = _isOutsideLimits(m.deltaL, m.lowerL, m.upperL);

      } else if (dimension == 'a*') {

        outside = _isOutsideLimits(m.deltaA, m.lowerA, m.upperA);

      } else if (dimension == 'b*') {

        outside = _isOutsideLimits(m.deltaB, m.lowerB, m.upperB);

      } else if (dimension == 'ΔE*') {

        // Es gibt aktuell keine eigene ΔE*-Toleranz.

        outside =

            _isNok(m);

      }

      if (outside) {

        errors[artikel] =

            (errors[artikel] ?? 0) + 1;

      }

    }

    final artikel = total.keys.toList()

      ..sort(

        (a, b) =>

            (errors[b] ?? 0).compareTo(

              errors[a] ?? 0,

            ),

      );

    final top = artikel.take(5).toList();

    final buffer = StringBuffer();

    buffer.writeln(

      'Artikel mit den meisten $dimension-Auffälligkeiten:',

    );

    if (year != null) {

      buffer.writeln('Zeitraum: $year');

    }

    buffer.writeln();

    for (var i = 0; i < top.length; i++) {

      final name = top[i];

      final error = errors[name] ?? 0;

      final count = total[name] ?? 0;

      final quote =

          count > 0 ? error / count * 100 : 0.0;

      buffer.writeln(

        '${i + 1}. $name: '

        '$error von $count Messungen '

        '(${quote.toStringAsFixed(1)} %)',

      );

    }

    return QSAnalysisResult(buffer.toString());

  }

  // ================================================================

  // ARTICLE WITH THE MOST DEVIATIONS

  // ================================================================

  QSAnalysisResult _artikelMitMeistenAbweichungen(

    int? year,

  ) {

    final data = _filterByYear(year)
        .where((m) => m.artikelnummer.trim().isNotEmpty)
        .toList();

    if (data.isEmpty) {

      return const QSAnalysisResult(

        'Es sind keine Messdaten verfügbar.',

      );

    }

    final total = <String, int>{};

    final errors = <String, int>{};

    for (final m in data) {

      final artikel = m.artikelnummer;

      total[artikel] =

          (total[artikel] ?? 0) + 1;

      if (_isNok(m)) {

        errors[artikel] =

            (errors[artikel] ?? 0) + 1;

      }

    }

    final artikel = total.keys.toList()

      ..sort(

        (a, b) =>

            (errors[b] ?? 0).compareTo(

              errors[a] ?? 0,

            ),

      );

    final top = artikel.take(5).toList();

    final buffer = StringBuffer();

    buffer.writeln(

      'Artikel mit den meisten Abweichungen:',

    );

    if (year != null) {

      buffer.writeln('Zeitraum: $year');

    }

    buffer.writeln();

    for (var i = 0; i < top.length; i++) {

      final name = top[i];

      final error = errors[name] ?? 0;

      final count = total[name] ?? 0;

      final quote =

          count > 0 ? error / count * 100 : 0.0;

      buffer.writeln(

        '${i + 1}. $name: '

        '$error von $count Messungen nicht erfüllt '

        '(${quote.toStringAsFixed(1)} %)',

      );

    }

    return QSAnalysisResult(buffer.toString());

  }

  // ================================================================

  // HIGHEST FAILURE RATE

  // ================================================================

  QSAnalysisResult _artikelMitHoechsterFehlerquote(

    int? year,

  ) {

    final data = _filterByYear(year)
        .where((m) => m.artikelnummer.trim().isNotEmpty)
        .toList();

    if (data.isEmpty) {

      return const QSAnalysisResult(

        'Es sind keine Messdaten verfügbar.',

      );

    }

    final total = <String, int>{};

    final errors = <String, int>{};

    for (final m in data) {

      final artikel = m.artikelnummer;

      total[artikel] =

          (total[artikel] ?? 0) + 1;

      if (_isNok(m)) {

        errors[artikel] =

            (errors[artikel] ?? 0) + 1;

      }

    }

    final artikel = total.keys
        .where((artikel) => (total[artikel] ?? 0) >= 10)
        .toList()

      ..sort(

        (a, b) {

          final qa =

              (errors[a] ?? 0) / (total[a] ?? 1);

          final qb =

              (errors[b] ?? 0) / (total[b] ?? 1);

          final byRate = qb.compareTo(qa);

          if (byRate != 0) {
            return byRate;
          }

        // Same failure rate:
        // the article with the most measurements comes first.
          return (total[b] ?? 0).compareTo(total[a] ?? 0);

        },

      );

    final top = artikel.take(5).toList();

    final buffer = StringBuffer();

    buffer.writeln(

      'Artikel mit der höchsten Fehlerquote:',

    );

    if (year != null) {

      buffer.writeln('Zeitraum: $year');

    }

    buffer.writeln();

    if (top.isEmpty) {

      buffer.writeln(

        'Es gibt keine Artikel mit mindestens 10 Messungen.',

      );

      return QSAnalysisResult(buffer.toString());

    }

    for (var i = 0; i < top.length; i++) {

      final name = top[i];

      final count = total[name] ?? 0;

      final error = errors[name] ?? 0;

      final quote =

          count > 0 ? error / count * 100 : 0.0;

      buffer.writeln(

        '${i + 1}. $name: '

        '${quote.toStringAsFixed(1)} % '

        '($error von $count Messungen nicht erfüllt)',

      );

    }

    return QSAnalysisResult(buffer.toString());

  }

  // ================================================================
  // DETAILED ANALYSIS OF A SPECIFIC ARTICLE
  // ================================================================

  QSAnalysisResult _artikelDetailAnalyse(String artikelnummer, int? year) {
    final key = _normalizeArticle(artikelnummer);
    final data = _filterByYear(year)
        .where((m) => _normalizeArticle(m.artikelnummer) == key)
        .toList()
      ..sort((a, b) => a.datum.compareTo(b.datum));

    if (data.isEmpty) {
      return QSAnalysisResult(
        'Für Artikel $artikelnummer wurden keine Messungen gefunden'
        '${year != null ? ' ($year)' : ''}.',
      );
    }

    final groups = <String, List<Measurement>>{};
    for (final m in data) {
      final ba = m.baNr.trim().isEmpty ? 'ohne BA' : m.baNr.trim();
      groups.putIfAbsent(ba, () => []).add(m);
    }

    final allProfiles = groups.entries
        .map((e) => _NamedBaProfile(e.key, _buildBaProfile(e.value)))
        .toList()
      ..sort((a, b) => a.profile.firstDate.compareTo(b.profile.firstDate));

    // For articles with many production runs, the detailed analysis remains readable:
    // A maximum of the 5 most recently measured BAs are considered.
    // The date of the latest measurement is what matters, not the BA number.
    final totalBaCount = allProfiles.length;
    final profilesByRecency = allProfiles.toList()
      ..sort((a, b) => b.profile.lastDate.compareTo(a.profile.lastDate));

    final profiles = profilesByRecency.take(5).toList()
      ..sort((a, b) => a.profile.firstDate.compareTo(b.profile.firstDate));

    // Detail sections should refer to the same BAs that are also
    // displayed in the BA comparison.
    final selectedBaNrs = profiles.map((p) => p.baNr).toSet();
    final analysisData = data
        .where((m) {
          final ba = m.baNr.trim().isEmpty ? 'ohne BA' : m.baNr.trim();
          return selectedBaNrs.contains(ba);
        })
        .toList()
      ..sort((a, b) => a.datum.compareTo(b.datum));

    final nok = analysisData.where(_isNok).length;
    final rate = analysisData.isEmpty ? 0.0 : nok / analysisData.length * 100;
    final buffer = StringBuffer();

    buffer.writeln('Analyse Artikel **$artikelnummer**');
    if (year != null) {
      buffer.writeln('Zeitraum: **$year**');
    }
    buffer.writeln();
    buffer.writeln(
      'Ausgewertet: **${analysisData.length} Messungen**, **$nok n.i.O.** '
      '→ Fehlerquote **${rate.toStringAsFixed(1)} %**.',
    );
    buffer.writeln('BAs im Datensatz: **$totalBaCount**.');

    if (totalBaCount > 5) {
      buffer.writeln(
        'Für diese Detailanalyse werden nur die **5 zuletzt gemessenen BAs** '
        'angezeigt und ausgewertet.',
      );
    }

    buffer.writeln();
    buffer.writeln('BA-Vergleich');

    for (final item in profiles) {
      final p = item.profile;
      buffer.writeln(
        '• **BA ${item.baNr}:** ${p.total} Messungen, '
        '${p.nok} n.i.O. (**${p.errorRate.toStringAsFixed(1)} %**), '
        'Ø ΔL* **${_signed(p.avgDeltaL)}**, '
        'Ø Δa* **${_signed(p.avgDeltaA)}**, '
        'Ø Δb* **${_signed(p.avgDeltaB)}**, '
        'Ø ΔE* **${_formatNumber(p.avgDeltaE)}**.',
      );
    }

    // ------------------------------------------------------------
    // NOK MEASUREMENTS IN DETAIL
    // ------------------------------------------------------------
    final nokMeasurements = analysisData.where(_isNok).toList();

    if (nokMeasurements.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Was ist bei den n.i.O.-Messungen auffällig?');

      // Bei wenigen Fehlern jede Messung einzeln erklären.
      if (nokMeasurements.length <= 5) {
        for (final m in nokMeasurements) {
          final ba = m.baNr.trim().isEmpty ? 'ohne BA' : m.baNr.trim();
          final issues = <String>[];

          void addIssue(
            String dimension,
            double value,
            double? lower,
            double? upper,
          ) {
            if (upper != null && value > upper) {
              final exceedance = value - upper;
              issues.add(
                '$dimension ${_signed(value)} '
                '(obere Grenze +${_formatNumber(upper)}, '
                'Überschreitung ${_formatNumber(exceedance)})',
              );
            } else if (lower != null && value < -lower) {
              final exceedance = (-lower) - value;
              issues.add(
                '$dimension ${_signed(value)} '
                '(untere Grenze -${_formatNumber(lower)}, '
                'Überschreitung ${_formatNumber(exceedance)})',
              );
            }
          }

          addIssue('ΔL*', m.deltaL, m.lowerL, m.upperL);
          addIssue('Δa*', m.deltaA, m.lowerA, m.upperA);
          addIssue('Δb*', m.deltaB, m.lowerB, m.upperB);

          buffer.writeln(
            '• **BA $ba, ${_formatDate(m.datum)}:** '
            '${issues.isEmpty ? 'n.i.O.-Status vorhanden, aber anhand der verfügbaren L*-, a*- und b*-Grenzen ist keine konkrete Toleranzüberschreitung erkennbar.' : issues.join('; ')}.',
          );
        }
      } else {
        int lViolations = 0;
        int aViolations = 0;
        int bViolations = 0;

        for (final m in nokMeasurements) {
          if (_isOutsideLimits(m.deltaL, m.lowerL, m.upperL)) lViolations++;
          if (_isOutsideLimits(m.deltaA, m.lowerA, m.upperA)) aViolations++;
          if (_isOutsideLimits(m.deltaB, m.lowerB, m.upperB)) bViolations++;
        }

        buffer.writeln(
          '• Es gibt **${nokMeasurements.length} n.i.O.-Messungen**. '
          'Davon zeigen $lViolations eine L*-Überschreitung, '
          '$aViolations eine a*-Überschreitung und '
          '$bViolations eine b*-Überschreitung.',
        );
        buffer.writeln(
          '• Bei dieser Anzahl werden die Fehler zusammengefasst, damit die '
          'Artikelanalyse übersichtlich bleibt. Eine einzelne BA kann für '
          'eine detaillierte Toleranzanalyse separat abgefragt werden.',
        );
      }
    }

    if (profiles.length >= 2) {
      final byRate = profiles.toList()
        ..sort((a, b) {
          final rateCompare =
              a.profile.errorRate.compareTo(b.profile.errorRate);
          if (rateCompare != 0) return rateCompare;
          // With the same failure rate, the larger data set
          // is more meaningful for comparison.
          return b.profile.total.compareTo(a.profile.total);
        });

      final low = byRate.first;
      final high = byRate.last;
      final sameRate =
          (high.profile.errorRate - low.profile.errorRate).abs() < 0.0001;

      buffer.writeln();
      buffer.writeln('Einordnung');

      if (sameRate) {
        buffer.writeln(
          '• Alle verglichenen BAs haben die gleiche Fehlerquote: '
          '**${low.profile.errorRate.toStringAsFixed(1)} %**.',
        );
        buffer.writeln(
          '• Eine eindeutige Einstufung als auffälliger oder unauffälliger '
          'ist allein anhand der Fehlerquote daher nicht möglich.',
        );

        final largestSample = profiles.toList()
          ..sort((a, b) => b.profile.total.compareTo(a.profile.total));

        buffer.writeln(
          '• Die größte Datenbasis liefert **BA ${largestSample.first.baNr} '
          'mit ${largestSample.first.profile.total} Messungen**. '
          'Für den weiteren Vergleich sollten trotzdem alle verfügbaren BAs '
          'und ihre Toleranzüberschreitungen berücksichtigt werden.',
        );
      } else {
        final highestRate = profiles
            .map((p) => p.profile.errorRate)
            .reduce(math.max);

        final auffaellige = profiles
            .where(
              (p) => (p.profile.errorRate - highestRate).abs() < 0.0001,
            )
            .toList()
          ..sort((a, b) => b.profile.total.compareTo(a.profile.total));

        final ioBas = profiles
            .where((p) => p.profile.nok == 0)
            .toList()
          ..sort((a, b) => b.profile.total.compareTo(a.profile.total));

        final referenceCandidates = profiles
            .where(
              (p) =>
                  (p.profile.errorRate - highestRate).abs() >= 0.0001,
            )
            .toList()
          ..sort((a, b) {
            final rateCompare =
                a.profile.errorRate.compareTo(b.profile.errorRate);
            if (rateCompare != 0) return rateCompare;
            return b.profile.total.compareTo(a.profile.total);
          });

        final highForComparison = auffaellige.first;

        buffer.writeln(
          '• Die höchste Fehlerquote zeigt **BA ${highForComparison.baNr}**: '
          '**${highForComparison.profile.nok} von '
          '${highForComparison.profile.total} Messungen n.i.O. '
          '(${highForComparison.profile.errorRate.toStringAsFixed(1)} %)**.',
        );

        if (ioBas.isNotEmpty) {
          final ioText = ioBas
              .map(
                (p) => 'BA ${p.baNr} (${p.profile.total} Messungen)',
              )
              .join(', ');

          buffer.writeln(
            '• Ohne n.i.O.-Messungen sind: **$ioText**.',
          );

          final bestReference = ioBas.first;
          buffer.writeln(
            '• Für einen direkten Vergleich bietet '
            '**BA ${bestReference.baNr} mit ${bestReference.profile.total} '
            'Messungen** die größere i.O.-Vergleichsbasis. '
            'Die übrigen BAs desselben Artikels bleiben als zusätzliche '
            'Vergleichspunkte relevant.',
          );

          buffer.writeln(
            '• Größter Unterschied der Mittelwerte zwischen '
            'BA ${highForComparison.baNr} und BA ${bestReference.baNr}: '
            '**${_largestMeanDifference(highForComparison.profile, bestReference.profile)}**.',
          );
        } else if (referenceCandidates.isNotEmpty) {
          final reference = referenceCandidates.first;

          buffer.writeln(
            '• Es gibt keine vollständig i.O. Vergleichs-BA. '
            'Als Vergleichsbasis bietet sich **BA ${reference.baNr}** '
            'mit ${reference.profile.errorRate.toStringAsFixed(1)} % n.i.O. '
            'und ${reference.profile.total} Messungen an.',
          );
          buffer.writeln(
            '• Größter Unterschied der Mittelwerte zwischen '
            'BA ${highForComparison.baNr} und BA ${reference.baNr}: '
            '**${_largestMeanDifference(highForComparison.profile, reference.profile)}**.',
          );
        }
      }

      buffer.writeln(
        '• Unterschiede der BA-Mittelwerte zeigen, wo sich Produktionen '
        'voneinander verschieben. Sie erklären aber nicht automatisch, '
        'welche Messgröße eine einzelne n.i.O.-Messung verursacht hat.',
      );
    }

    buffer.writeln();
    buffer.writeln('Empfohlene Prüfung');

    if (nok == 0) {
      buffer.writeln(
        '• Für diesen Artikel zeigen die vorhandenen Messdaten aktuell '
        'keine n.i.O.-Messungen.',
      );
      buffer.writeln(
        '• Die BAs können weiterhin anhand ihrer Mittelwerte und Streuung '
        'beobachtet werden, ohne aus kleinen Mittelwertunterschieden '
        'automatisch ein Qualitätsproblem abzuleiten.',
      );
    } else {
      buffer.writeln(
        '• Zuerst die konkret n.i.O. gemessenen Farbgrößen und ihre '
        'Toleranzüberschreitungen betrachten.',
      );
      buffer.writeln(
        '• Danach die betroffene BA mit den anderen BAs desselben Artikels '
        'vergleichen. Dabei sowohl Fehlerquote als auch Anzahl der '
        'vorhandenen Messungen berücksichtigen.',
      );
      buffer.writeln(
        '• Prozessbedingungen, Material/Charge, Einstellungen und '
        'Produktionszeitpunkt erst im nächsten Schritt gegenüberstellen. '
        'Die Farbmessdaten zeigen die Abweichung, aber nicht automatisch '
        'deren physische Prozessursache.',
      );
    }

    return QSAnalysisResult(buffer.toString());
  }

  // ================================================================
  // GLOBAL TREND OF A MEASUREMENT PARAMETER OVER TIME
  // ================================================================

  QSAnalysisResult _globaleDimensionEntwicklung(String dimension, int? year) {
    final data = _filterByYear(year).toList()..sort((a,b)=>a.datum.compareTo(b.datum));
    if (data.isEmpty) return const QSAnalysisResult('Es sind keine Messdaten verfügbar.');
    final monthly = <String, List<Measurement>>{};
    for (final m in data) {
      final key='${m.datum.year}-${m.datum.month.toString().padLeft(2,'0')}';
      monthly.putIfAbsent(key,()=>[]).add(m);
    }
    final months=monthly.keys.toList()..sort();
    final buffer=StringBuffer();
    buffer.writeln('Entwicklung $dimension über die Zeit');
    if (year != null) buffer.writeln('Zeitraum: $year');
    buffer.writeln();

    final tableRows = <String>[
      'Monat|Ø $dimension|Maximum|Messungen',
    ];

    for (final month in months) {
      final d=monthly[month]!;
      if (dimension=='ΔE*') {
        final avg=d.map((m)=>m.deltaE).reduce((a,b)=>a+b)/d.length;
        final max=d.map((m)=>m.deltaE).reduce(math.max);
        tableRows.add(
          '${_formatMonth(month)}|${_formatNumber(avg)}|${_formatNumber(max)}|${d.length}',
        );
      } else {
        double value(Measurement m) {
          if (dimension == 'L*') return m.deltaL;
          if (dimension == 'a*') return m.deltaA;
          return m.deltaB;
        }

        final values = d.map(value).toList();
        final avg = values.reduce((a,b)=>a+b) / values.length;
        final max = values.map((v)=>v.abs()).reduce(math.max);

        tableRows.add(
          '${_formatMonth(month)}|${_formatNumber(avg)}|${_formatNumber(max)}|${d.length}',
        );
      }
    }

    buffer.writeln('TABLE|${tableRows.join(';;')}');

    if (months.length>=2) {
      buffer.writeln();
      buffer.writeln(
        'Hinweis: Die Monatswerte enthalten Messungen verschiedener Artikel und BAs. '
        'Veränderungen des durchschnittlichen $dimension bedeuten daher nicht automatisch, '
        'dass sich der Produktionsprozess verbessert oder verschlechtert hat.',
      );
    }
    return QSAnalysisResult(buffer.toString());
  }

  // ================================================================
  // SHARED ANALYSIS CORE
  // ================================================================

  _BaProfile _buildBaProfile(List<Measurement> data) {
    final sorted=data.toList()..sort((a,b)=>a.datum.compareTo(b.datum));
    int nok=0,l=0,a=0,b=0,lHigh=0,lLow=0,aHigh=0,aLow=0,bHigh=0,bLow=0;
    double sumL=0,sumA=0,sumB=0,sumE=0;
    for (final m in sorted) {
      if (_isNok(m)) nok++;
      sumL+=m.deltaL; sumA+=m.deltaA; sumB+=m.deltaB; sumE+=m.deltaE;
      if (_isOutsideLimits(m.deltaL,m.lowerL,m.upperL)) l++;
      if (_isOutsideLimits(m.deltaA,m.lowerA,m.upperA)) a++;
      if (_isOutsideLimits(m.deltaB,m.lowerB,m.upperB)) b++;
      if (m.upperL!=null && m.deltaL>m.upperL!) lHigh++;
      if (m.lowerL!=null && m.deltaL < -m.lowerL!) lLow++;
      if (m.upperA!=null && m.deltaA>m.upperA!) aHigh++;
      if (m.lowerA!=null && m.deltaA < -m.lowerA!) aLow++;
      if (m.upperB!=null && m.deltaB>m.upperB!) bHigh++;
      if (m.lowerB!=null && m.deltaB < -m.lowerB!) bLow++;
    }
    final n=sorted.length;
    final avgL=sumL/n, avgA=sumA/n, avgB=sumB/n, avgE=sumE/n;
    double varianceL=0;
    for(final m in sorted){ varianceL += math.pow(m.deltaL-avgL,2).toDouble(); }
    final sdL=math.sqrt(varianceL/n);
    return _BaProfile(total:n,ok:n-nok,nok:nok,errorRate:nok/n*100,
      avgDeltaL:avgL,avgDeltaA:avgA,avgDeltaB:avgB,avgDeltaE:avgE,sdDeltaL:sdL,
      lViolations:l,aViolations:a,bViolations:b,lTooHigh:lHigh,lTooLow:lLow,
      aTooHigh:aHigh,aTooLow:aLow,bTooHigh:bHigh,bTooLow:bLow,
      firstDate:sorted.first.datum,lastDate:sorted.last.datum);
  }

  String _systematicAssessment(_BaProfile p) {
    final dominant=[p.lViolations,p.aViolations,p.bViolations].reduce(math.max);
    final ratio=dominant/p.total;
    if (ratio>=0.8) return 'Die dominante Abweichung betrifft mindestens 80 % der Messungen. Das spricht in den Messdaten eher für eine systematische Verschiebung als für einzelne Ausreißer.';
    if (ratio>=0.4) return 'Die Abweichung tritt wiederholt auf, aber nicht bei allen Messungen. Streuung und zeitlicher Verlauf innerhalb der BA sollten geprüft werden.';
    return 'Die Toleranzüberschreitungen betreffen nur einen kleineren Teil der Messungen. Einzelne Ausreißer oder instabile Streuung sollten geprüft werden.';
  }

  String _dominantDimension(_BaProfile p) {
    final dims={'L*':p.lViolations,'a*':p.aViolations,'b*':p.bViolations}.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    return dims.first.key;
  }

  String _largestMeanDifference(_BaProfile x,_BaProfile y) {
    final d=<MapEntry<String,double>>[
      MapEntry('ΔL*',(x.avgDeltaL-y.avgDeltaL).abs()),
      MapEntry('Δa*',(x.avgDeltaA-y.avgDeltaA).abs()),
      MapEntry('Δb*',(x.avgDeltaB-y.avgDeltaB).abs()),
      MapEntry('ΔE*',(x.avgDeltaE-y.avgDeltaE).abs()),
    ]..sort((a,b)=>b.value.compareTo(a.value));
    return '${d.first.key} (${_formatNumber(d.first.value)})';
  }

  String _mostCommonArticle(List<Measurement> data) {
    final counts=<String,int>{};
    for(final m in data){ final k=m.artikelnummer.trim(); if(k.isNotEmpty) counts[k]=(counts[k]??0)+1; }
    if(counts.isEmpty) return '';
    final entries=counts.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    return entries.first.key;
  }

  String _normalizeArticle(String value)=>value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'),'');
  String _signed(double value)=>'${value>=0?'+':''}${_formatNumber(value)}';

  // ================================================================

  // HELPERS

  // ================================================================

  List<Measurement> _filterByYear(int? year) {

    if (year == null) {

      return measurements;

    }

    return measurements

        .where(

          (m) => m.datum.year == year,

        )

        .toList();

  }

  bool _baNrMatches(

    String value,

    String requested,

  ) {

    final valueKey =

        value.replaceAll(RegExp(r'[^0-9]'), '');

    final requestedKey =

        requested.replaceAll(RegExp(r'[^0-9]'), '');

    return valueKey.isNotEmpty &&

        requestedKey.isNotEmpty &&

        valueKey == requestedKey;

  }

  String _formatMonth(String value) {

    final parts = value.split('-');

    if (parts.length != 2) {

      return value;

    }

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

    final month = int.tryParse(parts[1]);

    if (month == null ||

        month < 1 ||

        month > 12) {

      return value;

    }

    return '${months[month - 1]} ${parts[0]}';

  }

  String _formatNumber(double value) {

    return value

        .toStringAsFixed(2)

        .replaceAll('.', ',');

  }

}

class _BaProfile {
  final int total, ok, nok, lViolations, aViolations, bViolations;
  final int lTooHigh, lTooLow, aTooHigh, aTooLow, bTooHigh, bTooLow;
  final double errorRate, avgDeltaL, avgDeltaA, avgDeltaB, avgDeltaE, sdDeltaL;
  final DateTime firstDate, lastDate;
  const _BaProfile({required this.total,required this.ok,required this.nok,required this.errorRate,
    required this.avgDeltaL,required this.avgDeltaA,required this.avgDeltaB,required this.avgDeltaE,required this.sdDeltaL,
    required this.lViolations,required this.aViolations,required this.bViolations,required this.lTooHigh,required this.lTooLow,
    required this.aTooHigh,required this.aTooLow,required this.bTooHigh,required this.bTooLow,required this.firstDate,required this.lastDate});
}

class _NamedBaProfile {
  final String baNr;
  final _BaProfile profile;
  const _NamedBaProfile(this.baNr,this.profile);
}

class _ViolationSummary {
  final String name;
  final int count,total;
  const _ViolationSummary(this.name,this.count,this.total);
}

class _DimensionMetric {

  final double score;

  final String summary;

  const _DimensionMetric({

    required this.score,

    required this.summary,

  });

}