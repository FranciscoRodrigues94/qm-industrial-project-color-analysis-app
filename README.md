# QM Industrial Project – Color Analysis App

A Flutter-based industrial Quality Management application for color measurement analysis, reporting, and data-driven quality insights.

This project was developed to explore how measurement data from an industrial color management system can be transformed into a more accessible and useful Quality Management interface.

The application connects to a Microsoft SQL Server data source through ODBC, processes raw measurement data, evaluates color tolerances, and presents the results through interactive dashboards and analysis tools.

> **Note:** This repository contains a sanitized version of the project.  
> Production database configuration, infrastructure details, and the original database schema are intentionally excluded.

---

## Overview

Industrial color measurement systems can contain large amounts of useful quality data, but extracting trends and actionable information from individual measurements can be difficult.

This application provides a dedicated QM interface for:

- monitoring color measurement results
- identifying OK / NOK measurements
- analyzing deviations from reference standards
- filtering measurements by time period
- comparing production results
- identifying problematic production orders
- visualizing quality trends
- supporting data-driven quality analysis

The goal is to turn raw measurement data into information that can be used more effectively in day-to-day Quality Management.

---

## The Problem

Industrial color measurement systems are primarily designed to perform and store individual measurements. While they provide the technical data required for color evaluation, using that data for broader Quality Management analysis can require significant manual work.

In the original workflow, measurement results had to be inspected individually or exported before they could be analyzed from a wider quality perspective.

This makes questions such as the following harder to answer quickly:

- How is measurement quality developing over time?
- Which production orders have the highest proportion of NOK measurements?
- Which articles are measured most frequently?
- Are certain color deviations occurring repeatedly?
- Which measurements exceeded their individual tolerances?
- How many measurements were OK or NOK during a specific month?
- Which reference standard was used for a particular measurement?

The measurement data already existed — the main challenge was transforming it into structured, accessible Quality Management information.

## The Solution

This project creates a dedicated Quality Management layer on top of the existing measurement data.

Instead of replacing the industrial measurement system, the Flutter application retrieves the relevant raw measurement information from its SQL Server data source and transforms it into a separate analysis environment.

The application automatically:

1. Retrieves measurement records from SQL Server through ODBC.
2. Maps the database results into structured Dart measurement objects.
3. Associates each measurement with its reference standard and production information.
4. Calculates ΔL*, Δa*, Δb* and ΔE from the measured and reference values.
5. Evaluates the deviations against the tolerances applicable to that measurement.
6. Classifies the result as OK or NOK.
7. Aggregates the processed measurements for dashboard statistics and analysis.
8. Allows users to explore the results by time period, article and production order.
9. Provides predefined analytical workflows through the "Frag KI" interface.

The result is a tool focused not only on individual color measurements, but on understanding the quality information contained across the complete measurement dataset.

## Why This Project Matters

The value of the application is not simply displaying database records in a different interface.

It converts raw operational measurement data into information that can support Quality Management decisions.

For example, instead of manually reviewing individual measurements, a user can identify production orders with unusually high NOK rates, inspect the affected measurements, compare their deviations with the applicable tolerances, and investigate recurring patterns.

The application therefore acts as a bridge between:

```text
Measurement Data
       ↓
Structured Information
       ↓
Quality Analysis
       ↓
Actionable Insights

```
This separation also allows the existing measurement process to remain unchanged: measurements continue to be created in the original industrial system, while the QM application provides an additional analytical layer.

--- 

## Main Features

### Dashboard

The dashboard provides a quick overview of the current measurement data, including:

- total measurements
- OK / NOK distribution
- monthly filtering
- quality performance indicators
- ranking of production orders with high NOK rates
- frequently measured items

The displayed statistics react dynamically to the selected time period.

### Measurement Explorer

Measurement records can be inspected individually with information such as:

- article number
- production order
- sample name
- reference / standard
- measurement date
- user
- L\*, a\*, b\* values
- ΔL\*, Δa\*, Δb\*
- ΔE
- gloss
- applicable tolerances
- calculated OK / NOK status

### Analysis

The application processes measurement data to provide additional quality insights and comparisons instead of displaying only raw database records.

This makes it possible to identify recurring deviations and problematic measurement groups more quickly.

### "Frag KI" Analysis Interface

The project also includes an experimental analysis interface called **Frag KI** ("Ask AI").

It provides predefined analytical questions that can be applied to the loaded measurement dataset to investigate quality patterns and trends.

The current implementation performs the analysis locally using deterministic application logic.

The architecture can later be extended with an external AI/LLM service if required.

---

## Color Evaluation Logic

For every measurement, the application compares the measured CIELAB values with the associated reference standard.

The following deviations are calculated:

```text
ΔL* = L* measured - L* standard
Δa* = a* measured - a* standard
Δb* = b* measured - b* standard
```

ΔE is calculated as:

```text
ΔE = √(ΔL² + Δa² + Δb²)
```

The measurement is then evaluated against its applicable lower and upper tolerances.

If all required color deviations remain within their respective limits, the measurement is classified as:

```text
OK
```

Otherwise:

```text
NOK
```

Tolerance values are evaluated per measurement rather than using fixed global limits.

---

## Architecture

The application follows a lightweight direct-data architecture:

```text
Industrial Measurement System
            │
            ▼
    Microsoft SQL Server
            │
            ▼
      ODBC Driver 18
            │
            ▼
        Dart / Flutter
            │
            ▼
     Data Processing Layer
            │
            ├── Measurement mapping
            ├── Color difference calculations
            ├── Tolerance evaluation
            └── Quality analysis
            │
            ▼
        Flutter UI
            │
            ├── Dashboard
            ├── Measurements
            ├── Analysis
            └── Frag KI
```

The application currently connects directly to SQL Server through ODBC.

For a larger production deployment, the architecture could be extended with a dedicated backend/API layer between the client application and the database.

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Application framework |
| Dart | Application logic |
| Microsoft SQL Server | Measurement data source |
| ODBC Driver 18 | Database connectivity |
| `odbc_fast` | Dart ODBC integration |
| Windows | Primary desktop deployment target |
| Git / GitHub | Version control and project documentation |

---

## Project Structure

```text
lib/
├── config/
│   ├── database_config.example.dart
│   └── colibri_query.example.dart
│
├── models/
│   ├── measurement.dart
│   └── project_structure.dart
│
├── pages/
│   ├── dashboard_page.dart
│   ├── messungen_page.dart
│   ├── messungsdetails_page.dart
│   ├── analyse_page.dart
│   └── frag_ai_page.dart
│
├── services/
│   ├── colibri_service.dart
│   ├── measurement_data_service.dart
│   └── ai_analyzer.dart
│
├── widgets/
│   └── sidebar.dart
│
└── main.dart
```

---

## Database Integration

Database access is implemented using Microsoft ODBC.

The application:

1. initializes the ODBC service
2. establishes a SQL Server connection
3. requests measurement data for the selected date range
4. maps SQL results into Dart `Measurement` objects
5. calculates color differences
6. evaluates measurement tolerances
7. provides the processed dataset to the UI and analysis layer

Sensitive connection information is not stored in the repository.

The local application uses:

```text
lib/config/database_config.dart
```

This file is excluded through `.gitignore`.

A sanitized template is provided instead:

```text
lib/config/database_config.example.dart
```

---

## SQL Schema Protection

The production SQL query and database schema are also intentionally excluded from version control.

The local application uses:

```text
lib/config/colibri_query.dart
```

The repository only contains:

```text
lib/config/colibri_query.example.dart
```

The example demonstrates the expected query interface and result aliases without exposing production table names, relationships, infrastructure, or database-specific implementation details.

---

## Local Configuration

To configure the application for another environment, create local versions of the example configuration files:

```text
database_config.example.dart
        ↓
database_config.dart
```

and:

```text
colibri_query.example.dart
        ↓
colibri_query.dart
```

Then adapt the connection string and SQL query to the target environment.

Both local configuration files are excluded from version control.

---

## Demo Data

The repository also contains a fictional measurement dataset for development and demonstration purposes.

```text
assets/QS_FakeDaten_mit_Bezug.csv
```

The dataset does not contain production measurement data.

It can be used to develop or demonstrate application functionality without requiring access to the original industrial database.

---

## Security & Repository Sanitization

The public-facing project structure is designed to avoid exposing internal infrastructure.

The repository intentionally excludes:

- production server addresses
- database connection details
- credentials
- production SQL queries
- internal database schema
- company-specific infrastructure paths
- real production measurement datasets

Sanitized `.example.dart` configuration files document the expected interfaces without exposing the production environment.

---

## Running the Project

Install Flutter and verify the environment:

```bash
flutter doctor
```

Install the project dependencies:

```bash
flutter pub get
```

For database-connected operation, create and configure the local files described in the **Local Configuration** section.

Then run the Windows application:

```bash
flutter run -d windows
```

A compatible Microsoft SQL Server ODBC driver is required for database connectivity.

---

## Development Status

The project is under active development.

Current areas of development include:

- dashboard improvements
- quality trend analysis
- production-order analysis
- measurement filtering
- database integration
- reporting
- analytical question workflows
- improved deployment architecture

Potential future improvements include:

- dedicated backend/API layer
- role-based access
- automated reporting
- configurable analysis rules
- extended trend detection
- optional LLM-assisted analysis
- improved deployment and configuration management

---

## Project Background

This project was developed as a practical industrial Quality Management and software-development project.

It combines domain knowledge from quality assurance with software engineering, database integration, data processing, and visualization.

The project demonstrates practical experience with:

- Flutter application development
- Dart
- SQL-based data integration
- ODBC connectivity
- relational data mapping
- industrial measurement data
- data transformation
- quality evaluation logic
- UI/dashboard development
- Git-based version control
- separation of application code from environment-specific configuration

---

## Author

**Francisco de Castro Rodrigues**

QA / Developer of the QM Color Analysis Application