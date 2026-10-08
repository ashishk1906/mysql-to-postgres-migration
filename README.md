# SQL Server to PostgreSQL Canonical Migration (Docker-First)

An enterprise-ready, simple, and 100% Docker-based solution for migrating a complex relational SQL database to PostgreSQL using a **Canonical Data Model (CDM)**.

No local Python installation, ODBC drivers, or database installations are needed on your machine. Everything runs via **Docker Compose**.

---

## 1. Project Overview

- **Source Database**: Complex SQL Server database (**26 tables** across `core`, `inventory`, `sales`, and `audit` schemas) with primary keys, foreign keys, identity columns, recursive self-referential trees, composite keys, check constraints, filtered indexes, and realistic seed data.
- **Canonical Data Model (CDM)**: Decouples legacy source technical debt by enforcing enterprise naming conventions (`snake_case`), universal data types (`TIMESTAMPTZ`, `BOOLEAN`, `UUID`, `BIGINT IDENTITY`), and domain-driven design.
- **Docker-First Automation**: Complete migration pipeline containerized into simple `docker compose` commands that run anywhere (Windows, macOS, Linux).

---

## 2. Quickstart (Only 3 Docker Commands)

### Step 1: Start Databases & Auto-Seed
```bash
docker compose up -d
```
* **What happens**: Starts SQL Server 2022 (port `1433`), PostgreSQL 16 (port `5434`), and automatically seeds the 26-table sample database.

---

### Step 2: Check Source Database & Data
```bash
docker compose run --rm check
```
* **What happens**: Runs the database inspector inside Docker and prints:
  - All 26 SQL Server tables and their current **row counts**.
  - Sample customer records (`core.Customers`) and order records (`sales.Orders`).
  - Target PostgreSQL table counts and local MySQL status.

---

### Step 3: Run the Migration
```bash
docker compose run --rm migrate
```
* **What happens**: Runs the migration script inside Docker:
  1. Extracts schema metadata (tables, columns, types, primary keys) from SQL Server.
  2. Applies the Canonical Data Model (converts names to `snake_case`, maps types to PostgreSQL equivalents).
  3. Creates target schemas (`core`, `inventory`, `sales`, `audit`) and tables in PostgreSQL.
  4. Migrates all data rows.
  5. Synchronizes PostgreSQL identity sequence generators.
  6. Validates source and target row counts, printing a **100% Match** reconciliation table.
  7. Saves output files to your local `./output` folder:
     - [`output/postgres_schema.sql`](file:///c:/Users/aks89/Desktop/mysql-to-postgres/output/postgres_schema.sql) (Generated PostgreSQL DDL)
     - [`output/validation_report.md`](file:///c:/Users/aks89/Desktop/mysql-to-postgres/output/validation_report.md) (Reconciliation audit report)

---

## 3. Project Structure

```
c:\Users\aks89\Desktop\mysql-to-postgres/
├── docker-compose.yml           # Complete Docker setup (sqlserver, postgres, seed, check, migrate)
├── Dockerfile                   # Python container image for check and migrate runners
├── .env.example                 # Template environment variables (committed to git, keys only)
├── .env                         # Actual database credentials (gitignored, secure)
├── check_databases.py           # Database inspection script (used by 'docker compose run --rm check')
├── migrate.py                   # Self-contained migration script (used by 'docker compose run --rm migrate')
│
├── sql_server/                  # Complex sample database (26 tables across 4 schemas)
│   ├── 01_init_schema.sql       # Source DDL (keys, identities, checks, indexes)
│   ├── 02_seed_data.sql         # Realistic enterprise seed data
│   └── 03_views_procedures.sql  # Views & stored procedures
│
├── docs/
│   ├── CANONICAL_DATA_MODEL.md  # Detailed CDM design & domain entity dictionary
│   └── MAPPING_DOCUMENT.md      # Full 3-layer mapping table: SQL Server -> Canonical -> PostgreSQL
│
├── output/
│   ├── postgres_schema.sql      # Auto-generated PostgreSQL Canonical DDL
│   └── validation_report.md     # 100% row reconciliation audit report
│
├── requirements.txt             # Python dependencies
├── GUIDE.md                     # Step-by-step walkthrough guide
└── README.md                    # Project overview & quickstart
```

---

## 4. Verification Results

Running `docker compose run --rm migrate` produces the reconciliation audit:

```
=================================================================
 MIGRATION RECONCILIATION RESULT
=================================================================
| SQL Server Table                | PostgreSQL Table                 |   Source Rows |   Target Rows | Status   |
|---------------------------------|----------------------------------|---------------|---------------|----------|
| audit.AuditLogs                 | audit.audit_logs                 |             3 |             3 | MATCH    |
| audit.SystemConfigurations      | audit.system_configurations      |             5 |             5 | MATCH    |
| core.Countries                  | core.countries                   |             8 |             8 | MATCH    |
| core.CustomerAddresses          | core.customer_addresses          |             8 |             8 | MATCH    |
| core.CustomerProfiles           | core.customer_profiles           |             6 |             6 | MATCH    |
| core.Customers                  | core.customers                   |             8 |             8 | MATCH    |
| core.Departments                | core.departments                 |             6 |             6 | MATCH    |
| core.Employees                  | core.employees                   |             8 |             8 | MATCH    |
| inventory.Categories            | inventory.categories             |             7 |             7 | MATCH    |
| inventory.InventoryTransactions | inventory.inventory_transactions |             6 |             6 | MATCH    |
| inventory.ProductBrands         | inventory.product_brands         |             4 |             4 | MATCH    |
| inventory.ProductInventory      | inventory.product_inventory      |             9 |             9 | MATCH    |
| inventory.Products              | inventory.products               |             6 |             6 | MATCH    |
| inventory.ProductVariants       | inventory.product_variants       |             6 |             6 | MATCH    |
| inventory.Suppliers             | inventory.suppliers              |             4 |             4 | MATCH    |
| inventory.Warehouses            | inventory.warehouses             |             4 |             4 | MATCH    |
| sales.CustomerReviews           | sales.customer_reviews           |             4 |             4 | MATCH    |
| sales.Invoices                  | sales.invoices                   |             5 |             5 | MATCH    |
| sales.OrderDiscounts            | sales.order_discounts            |             3 |             3 | MATCH    |
| sales.OrderFulfillments         | sales.order_fulfillments         |             3 |             3 | MATCH    |
| sales.OrderItems                | sales.order_items                |             9 |             9 | MATCH    |
| sales.OrderNotes                | sales.order_notes                |             3 |             3 | MATCH    |
| sales.Orders                    | sales.orders                     |             5 |             5 | MATCH    |
| sales.Payments                  | sales.payments                   |             3 |             3 | MATCH    |
| sales.PriceLists                | sales.price_lists                |             3 |             3 | MATCH    |
| sales.Promotions                | sales.promotions                 |             3 |             3 | MATCH    |

OVERALL RESULT: SUCCESS (100% Match)
```

---

## 5. Adapting for the Real Client Database

All database connection parameters and credentials are externalized to environment variables and loaded via `.env` (never hardcoded in code or committed to Git).

When the client provides their database credentials:
1. Copy `.env.example` to `.env` (if not already done):
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and fill in the client's SQL Server and PostgreSQL connection details:
   - `MSSQL_HOST`, `MSSQL_PORT`, `MSSQL_USER`, `MSSQL_PASSWORD`, `MSSQL_DB`, `MSSQL_SCHEMAS`
   - `PG_HOST`, `PG_PORT`, `PG_USER`, `PG_PASSWORD`, `PG_DB`
3. Run the migration:
   ```bash
   docker compose run --rm migrate
   ```
*(Or if running via local Python, `python migrate.py` also works).*
