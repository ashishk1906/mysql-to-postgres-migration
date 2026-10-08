#!/usr/bin/env python3
"""
Simple SQL Server to PostgreSQL Migration Script
Aligned with: sql_to_postgres_canonical_migration_guide.md

Steps:
  1. Connect to SQL Server & inspect tables/data
  2. Map schemas & data types to Canonical PostgreSQL model
  3. Create tables in PostgreSQL (snake_case, identities, constraints)
  4. Migrate data rows
  5. Validate row counts & verify
"""

import os
import re
from dotenv import load_dotenv
import pymssql
import psycopg2
from psycopg2.extras import execute_values
from tabulate import tabulate

# Load environment variables from .env file
load_dotenv()

# Load database configuration from .env / environment variables
def load_config():
    # Auto-detect if running inside Docker or on host machine
    is_docker = os.environ.get("RUNNING_IN_DOCKER") == "true" or os.path.exists("/.dockerenv")

    ms_host = os.environ.get("MSSQL_HOST", "sqlserver" if is_docker else "localhost")
    ms_port = int(os.environ.get("MSSQL_PORT", "1433"))

    pg_host = os.environ.get("PG_HOST", "postgres" if is_docker else "localhost")
    pg_port = int(os.environ.get("PG_PORT", "5432" if is_docker else "5434"))

    mssql_conf = {
        "server": ms_host,
        "port": ms_port,
        "user": os.environ.get("MSSQL_USER", ""),
        "password": os.environ.get("MSSQL_PASSWORD", ""),
        "database": os.environ.get("MSSQL_DB", "")
    }
    
    # Comma-separated schemas from .env
    raw_schemas = os.environ.get("MSSQL_SCHEMAS", "")
    schemas = [s.strip() for s in raw_schemas.split(",") if s.strip()]
    
    pg_conf = {
        "host": pg_host,
        "port": pg_port,
        "user": os.environ.get("PG_USER", ""),
        "password": os.environ.get("PG_PASSWORD", ""),
        "dbname": os.environ.get("PG_DB", "")
    }

    # Validate that all required configuration is provided in .env
    missing = []
    if not mssql_conf["user"]: missing.append("MSSQL_USER")
    if not mssql_conf["password"]: missing.append("MSSQL_PASSWORD")
    if not mssql_conf["database"]: missing.append("MSSQL_DB")
    if not schemas: missing.append("MSSQL_SCHEMAS")
    if not pg_conf["user"]: missing.append("PG_USER")
    if not pg_conf["password"]: missing.append("PG_PASSWORD")
    if not pg_conf["dbname"]: missing.append("PG_DB")

    if missing:
        raise ValueError(f"Missing required environment variables in .env: {', '.join(missing)}. Please check your .env file.")

    return mssql_conf, pg_conf, schemas

MSSQL_CONF, PG_CONF, SCHEMAS = load_config()

# Type Mapping Dictionary (SQL Server -> PostgreSQL Canonical)
TYPE_MAP = {
    "int": "INTEGER",
    "bigint": "BIGINT",
    "smallint": "SMALLINT",
    "tinyint": "SMALLINT",
    "bit": "BOOLEAN",
    "decimal": "NUMERIC",
    "numeric": "NUMERIC",
    "money": "NUMERIC(19,4)",
    "float": "DOUBLE PRECISION",
    "real": "REAL",
    "varchar": "VARCHAR",
    "nvarchar": "VARCHAR",
    "char": "CHAR",
    "nchar": "CHAR",
    "text": "TEXT",
    "ntext": "TEXT",
    "date": "DATE",
    "time": "TIME",
    "datetime": "TIMESTAMPTZ",
    "datetime2": "TIMESTAMPTZ",
    "uniqueidentifier": "UUID"
}

def to_snake(name: str) -> str:
    """Converts PascalCase to clean snake_case."""
    s1 = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1_\2', name.strip('[]"'))
    s2 = re.sub(r'([a-z\d])([A-Z])', r'\1_\2', s1)
    return re.sub(r'_+', '_', s2).lower()

def run_migration():
    print("=" * 65)
    print(" SQL Server -> PostgreSQL Canonical Migration")
    print("=" * 65)

    # 1. Connect
    print("\n[Step 1] Connecting to databases...")
    ms_conn = pymssql.connect(**MSSQL_CONF, as_dict=True)
    pg_conn = psycopg2.connect(**PG_CONF)
    pg_conn.autocommit = True
    print(" -> SQL Server connected.")
    print(" -> PostgreSQL connected.")

    ms_cur = ms_conn.cursor()
    pg_cur = pg_conn.cursor()

    schema_filter = "', '".join(SCHEMAS)

    # 2. Discover tables from SQL Server
    print("\n[Step 2] Reading SQL Server source schema...")
    ms_cur.execute(f"""
        SELECT s.name AS [schema], t.name AS [table], t.object_id
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name IN ('{schema_filter}')
        ORDER BY s.name, t.name;
    """)
    tables = ms_cur.fetchall()
    print(f" -> Found {len(tables)} tables across {len(SCHEMAS)} schemas.")

    # 3. Read Columns & Keys
    ms_cur.execute(f"""
        SELECT 
            s.name AS [schema], t.name AS [table], c.name AS [col],
            tp.name AS [type], c.max_length, c.precision, c.scale,
            c.is_nullable, c.is_identity
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.types tp ON c.user_type_id = tp.user_type_id
        WHERE s.name IN ('{schema_filter}')
        ORDER BY s.name, t.name, c.column_id;
    """)
    all_cols = ms_cur.fetchall()

    ms_cur.execute(f"""
        SELECT s.name AS [schema], t.name AS [table], c.name AS [pk_col]
        FROM sys.key_constraints kc
        JOIN sys.tables t ON kc.parent_object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE kc.type = 'PK' AND s.name IN ('{schema_filter}');
    """)
    pks = ms_cur.fetchall()
    pk_map = {}
    for p in pks:
        key = f"{p['schema']}.{p['table']}"
        pk_map.setdefault(key, []).append(to_snake(p['pk_col']))

    table_cols = {}
    for c in all_cols:
        key = f"{c['schema']}.{c['table']}"
        table_cols.setdefault(key, []).append(c)

    # 4. Generate & Deploy PostgreSQL Schemas and Tables
    print("\n[Step 3] Creating PostgreSQL Canonical Schemas and Tables...")
    for s in SCHEMAS:
        pg_cur.execute(f'CREATE SCHEMA IF NOT EXISTS "{to_snake(s)}";')

    for t in tables:
        src_schema = t['schema']
        src_table = t['table']
        tgt_schema = to_snake(src_schema)
        tgt_table = to_snake(src_table)
        tbl_key = f"{src_schema}.{src_table}"

        col_defs = []
        for col in table_cols.get(tbl_key, []):
            col_name = to_snake(col['col'])
            c_type = col['type'].lower()
            pg_type = TYPE_MAP.get(c_type, "TEXT")

            # Format length/precision
            if c_type in ('varchar', 'nvarchar', 'char', 'nchar'):
                max_l = col['max_length']
                actual_l = max_l // 2 if c_type.startswith('n') else max_l
                if actual_l > 0 and actual_l <= 8000:
                    pg_type = f"{'VARCHAR' if 'var' in c_type else 'CHAR'}({actual_l})"
                else:
                    pg_type = "TEXT"
            elif c_type in ('decimal', 'numeric') and col['precision']:
                pg_type = f"NUMERIC({col['precision']},{col['scale']})"

            # Identity
            if col['is_identity']:
                col_defs.append(f'"{col_name}" {pg_type} GENERATED BY DEFAULT AS IDENTITY')
            else:
                null_str = "" if col['is_nullable'] else " NOT NULL"
                col_defs.append(f'"{col_name}" {pg_type}{null_str}')

        # Add PK
        if tbl_key in pk_map:
            pk_cols_str = ', '.join([f'"{c}"' for c in pk_map[tbl_key]])
            col_defs.append(f'CONSTRAINT "pk_{tgt_table}" PRIMARY KEY ({pk_cols_str})')

        pg_cur.execute(f'DROP TABLE IF EXISTS "{tgt_schema}"."{tgt_table}" CASCADE;')
        create_sql = f'CREATE TABLE "{tgt_schema}"."{tgt_table}" (\n  ' + ',\n  '.join(col_defs) + '\n);'
        pg_cur.execute(create_sql)

    print(" -> All target tables created successfully.")

    # 5. Migrate Data
    print("\n[Step 4] Migrating data...")
    pg_cur.execute("SET session_replication_role = 'replica';") # Temporarily bypass FK order conflicts

    migrated_summary = []
    for t in tables:
        src_schema = t['schema']
        src_table = t['table']
        tgt_schema = to_snake(src_schema)
        tgt_table = to_snake(src_table)
        tbl_key = f"{src_schema}.{src_table}"
        cols = table_cols.get(tbl_key, [])

        src_col_list = ', '.join([f"[{c['col']}]" for c in cols])
        tgt_col_list = ', '.join([f'"{to_snake(c["col"])}"' for c in cols])

        # Fetch from SQL Server
        ms_cur.execute(f"SELECT {src_col_list} FROM {src_schema}.{src_table};")
        rows = ms_cur.fetchall()

        # Coerce types
        coerced_rows = []
        for r in rows:
            row_vals = []
            for c in cols:
                v = r[c['col']]
                if v is not None and c['type'].lower() == 'bit':
                    v = bool(v)
                elif v is not None and c['type'].lower() == 'uniqueidentifier':
                    v = str(v)
                row_vals.append(v)
            coerced_rows.append(tuple(row_vals))

        if coerced_rows:
            insert_sql = f'INSERT INTO "{tgt_schema}"."{tgt_table}" ({tgt_col_list}) VALUES %s;'
            execute_values(pg_cur, insert_sql, coerced_rows)

        # Check target count
        pg_cur.execute(f'SELECT COUNT(*) FROM "{tgt_schema}"."{tgt_table}";')
        pg_cnt = pg_cur.fetchone()[0]
        migrated_summary.append([f"{src_schema}.{src_table}", f"{tgt_schema}.{tgt_table}", len(rows), pg_cnt])

    pg_cur.execute("SET session_replication_role = 'origin';") # Re-enable constraints

    # Sync sequences
    for t in tables:
        tgt_schema = to_snake(t['schema'])
        tgt_table = to_snake(t['table'])
        tbl_key = f"{t['schema']}.{t['table']}"
        for col in table_cols.get(tbl_key, []):
            if col['is_identity']:
                col_name = to_snake(col['col'])
                sync_sql = f"""
                    DO $$
                    DECLARE seq text; max_id bigint;
                    BEGIN
                        seq := pg_get_serial_sequence('{tgt_schema}.{tgt_table}', '{col_name}');
                        IF seq IS NOT NULL THEN
                            EXECUTE 'SELECT COALESCE(MAX("{col_name}"), 1) FROM "{tgt_schema}"."{tgt_table}"' INTO max_id;
                            PERFORM setval(seq, max_id, true);
                        END IF;
                    END $$;
                """
                pg_cur.execute(sync_sql)

    # Save generated DDL to output/postgres_schema.sql
    import os
    os.makedirs("output", exist_ok=True)
    with open("output/postgres_schema.sql", "w", encoding="utf-8") as f:
        f.write("-- Generated PostgreSQL Canonical DDL\n\n")
        for s in SCHEMAS:
            f.write(f'CREATE SCHEMA IF NOT EXISTS "{to_snake(s)}";\n')
        f.write("\n")
        for t in tables:
            src_schema = t['schema']
            src_table = t['table']
            tgt_schema = to_snake(src_schema)
            tgt_table = to_snake(src_table)
            tbl_key = f"{src_schema}.{src_table}"
            col_defs = []
            for col in table_cols.get(tbl_key, []):
                col_name = to_snake(col['col'])
                c_type = col['type'].lower()
                pg_type = TYPE_MAP.get(c_type, "TEXT")
                if c_type in ('varchar', 'nvarchar', 'char', 'nchar'):
                    max_l = col['max_length']
                    actual_l = max_l // 2 if c_type.startswith('n') else max_l
                    if actual_l > 0 and actual_l <= 8000:
                        pg_type = f"{'VARCHAR' if 'var' in c_type else 'CHAR'}({actual_l})"
                    else:
                        pg_type = "TEXT"
                elif c_type in ('decimal', 'numeric') and col['precision']:
                    pg_type = f"NUMERIC({col['precision']},{col['scale']})"
                if col['is_identity']:
                    col_defs.append(f'    "{col_name}" {pg_type} GENERATED BY DEFAULT AS IDENTITY')
                else:
                    null_str = "" if col['is_nullable'] else " NOT NULL"
                    col_defs.append(f'    "{col_name}" {pg_type}{null_str}')
            if tbl_key in pk_map:
                pk_cols_str = ', '.join([f'"{c}"' for c in pk_map[tbl_key]])
                col_defs.append(f'    CONSTRAINT "pk_{tgt_table}" PRIMARY KEY ({pk_cols_str})')
            f.write(f'CREATE TABLE IF NOT EXISTS "{tgt_schema}"."{tgt_table}" (\n' + ',\n'.join(col_defs) + '\n);\n\n')

    # 6. Verification Summary
    print("\n" + "=" * 65)
    print(" MIGRATION RECONCILIATION RESULT")
    print("=" * 65)
    res_table = []
    all_match = True
    for s_tbl, t_tbl, s_cnt, t_cnt in migrated_summary:
        match = "MATCH" if s_cnt == t_cnt else "MISMATCH"
        if s_cnt != t_cnt:
            all_match = False
        res_table.append([s_tbl, t_tbl, s_cnt, t_cnt, match])

    table_output = tabulate(res_table, headers=["SQL Server Table", "PostgreSQL Table", "Source Rows", "Target Rows", "Status"], tablefmt="github")
    print(table_output)
    print(f"\nOVERALL RESULT: {'SUCCESS (100% Match)' if all_match else 'FAILED'}")

    # Save to output/validation_report.md
    with open("output/validation_report.md", "w", encoding="utf-8") as f:
        f.write("# Migration Reconciliation Audit Report\n\n")
        f.write(f"**Overall Status**: {'PASSED (100% Match)' if all_match else 'FAILED'}\n\n")
        f.write(table_output + "\n")

    print("\n[+] Generated files saved:")
    print("    - output/postgres_schema.sql")
    print("    - output/validation_report.md")

    ms_conn.close()
    pg_conn.close()

if __name__ == "__main__":
    run_migration()
