/// Example SQL query configuration.
///
/// This file contains a sanitized example of the query structure used by
/// the application. Table names, column names, joins, and property identifiers
/// shown here are illustrative and do not represent the production database
/// schema.
///
/// For a real deployment, create:
///
///   lib/config/colibri_query.dart
///
/// and implement [ColibriQuery.measurements] using the schema available in
/// your environment.
///
/// The real file is intentionally excluded from version control.

class ColibriQuery {
  static String measurements({
    required String startSql,
    required String endSql,
  }) {
    return '''
SELECT TOP 20000

    CAST(r.id AS VARCHAR(100))
        AS Result_OID,

    CAST(r.physical_sample_id AS VARCHAR(100))
        AS Physical_Sample_OID,

    CAST(r.standard_sample_id AS VARCHAR(100))
        AS Standard_Sample_OID,

    CAST(r.measured_by AS VARCHAR(500))
        AS ColibriUser,

    CAST(s.id AS VARCHAR(100))
        AS Sample_OID,

    CAST(s.sample_name AS VARCHAR(500))
        AS Sample_Name,

    CONVERT(
        VARCHAR(23),
        s.created_at,
        121
    ) AS Sample_CreationDate,

    CAST(s.l_value AS VARCHAR(100))
        AS L,

    CAST(s.a_value AS VARCHAR(100))
        AS a,

    CAST(s.b_value AS VARCHAR(100))
        AS b,

    CAST(std.standard_name AS VARCHAR(500))
        AS Standard_Name,

    CONVERT(
        VARCHAR(23),
        std.created_at,
        121
    ) AS Standard_CreationDate,

    CAST(std.l_value AS VARCHAR(100))
        AS Standard_L,

    CAST(std.a_value AS VARCHAR(100))
        AS Standard_a,

    CAST(std.b_value AS VARCHAR(100))
        AS Standard_b,

    CAST(meta.article_number AS VARCHAR(500))
        AS Artikelnummer,

    CAST(meta.production_order AS VARCHAR(500))
        AS BA_Nr,

    CAST(g.gloss_value AS VARCHAR(100))
        AS Gloss,

    CAST(t.lower_l AS VARCHAR(100))
        AS lL,

    CAST(t.upper_l AS VARCHAR(100))
        AS uL,

    CAST(t.lower_a AS VARCHAR(100))
        AS la,

    CAST(t.upper_a AS VARCHAR(100))
        AS ua,

    CAST(t.lower_b AS VARCHAR(100))
        AS lb,

    CAST(t.upper_b AS VARCHAR(100))
        AS ub,

    CAST(t.lower_gloss AS VARCHAR(100))
        AS lGloss,

    CAST(t.upper_gloss AS VARCHAR(100))
        AS uGloss

FROM measurement_results r

INNER JOIN measurement_samples s
    ON s.id = r.physical_sample_id

LEFT JOIN color_standards std
    ON std.id = r.standard_sample_id

LEFT JOIN production_metadata meta
    ON meta.sample_id = s.id

LEFT JOIN gloss_measurements g
    ON g.sample_id = s.id

LEFT JOIN measurement_tolerances t
    ON t.standard_id = r.standard_sample_id

WHERE s.created_at >= '$startSql'
  AND s.created_at < '$endSql'

ORDER BY
    s.created_at DESC,
    r.id DESC;
''';
  }
}