class DatabaseConfig {
  static const String connectionString = '''
DRIVER={ODBC Driver 18 for SQL Server};
SERVER=YOUR_SQL_SERVER;
DATABASE=YOUR_DATABASE;
Trusted_Connection=Yes;
TrustServerCertificate=Yes;
''';
}