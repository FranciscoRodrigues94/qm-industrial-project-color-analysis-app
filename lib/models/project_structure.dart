import 'measurement.dart';

// ============================================================
// REREFENCE GROUP
// ============================================================

class BezugGroup {
  final String name;
  final String standardSampleOid;
  final List<Measurement> measurements;

  const BezugGroup({
    required this.name,
    required this.standardSampleOid,
    required this.measurements,
  });
}

// ============================================================
// PROJECT GROUP
// ============================================================

class ProjectGroup {
  final String name;
  final List<BezugGroup> bezuege;

  const ProjectGroup({
    required this.name,
    required this.bezuege,
  });
}