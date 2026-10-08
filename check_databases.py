#!/usr/bin/env python3
"""
Simple Database Inspector Script
Quickly checks and displays:
1. Source SQL Server (EnterpriseSalesERP) tables, row counts, and sample records.
2. Target PostgreSQL (enterprisedb) tables, row counts, and sample records.
3. (Optional) Local MySQL status check.
"""

import os
import sys
import yaml
from tabulate import tabulate

IS_DOCKER = os.environ.get("RUNNING_IN_DOCKER") == "true" or os.path.exists("/.dockerenv")

def check_sql_server(cfg):
    print("\n" + "="*70)
    print(" 1. SOURCE DATABASE CHECK: SQL SERVER (EnterpriseSalesERP)")
    print("="*70)
    try:
        import pymssql
        src = cfg.get("source", {})
        server = os.environ.get("MSSQL_HOST", "sqlserver" if IS_DOCKER else src.get("host", "localhost"))
        port = int(os.environ.get("MSSQL_PORT", src.get("port", 1433)))
        conn = pymssql.connect(
            server=server,
            port=port,
            user=src.get("user", "sa"),
            password=src.get("password", "StrongP@ssw0rd!2026"),
            database=src.get("database", "EnterpriseSalesERP"),
            charset="UTF-8",
            as_dict=True
        )
        cur = conn.cursor()
        
        # 1. Total Tables
        cur.execute("""
            SELECT s.name AS [Schema], t.name AS [Table], p.rows AS [RowCount]
            FROM sys.tables t
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
            ORDER BY s.name, t.name;
        """)
        tables = cur.fetchall()
        table_rows = [[r["Schema"], r["Table"], r["RowCount"]] for r in tables]
        print(f"\n[+] Connected successfully to SQL Server! Found {len(tables)} tables:\n")
        print(tabulate(table_rows, headers=["Schema", "Table Name", "Row Count"], tablefmt="github"))
        
        # 2. Sample Data from Customers
        print("\n[+] Sample Data from 'core.Customers' (Top 3 records):")
        cur.execute("SELECT TOP 3 CustomerID, CompanyName, ContactName, Email, CreditLimit FROM core.Customers;")
        customers = cur.fetchall()
        cust_rows = [[c["CustomerID"], c["CompanyName"] or "N/A", c["ContactName"], c["Email"], f"${float(c['CreditLimit']):,.2f}"] for c in customers]
        print(tabulate(cust_rows, headers=["CustomerID", "Company", "Contact", "Email", "Credit Limit"], tablefmt="github"))

        # 3. Sample Data from Orders
        print("\n[+] Sample Data from 'sales.Orders' (Top 3 records):")
        cur.execute("SELECT TOP 3 OrderID, OrderNumber, CustomerID, TotalAmount, OrderDate, PaymentStatus FROM sales.Orders;")
        orders = cur.fetchall()
        ord_rows = [[o["OrderID"], o["OrderNumber"], o["CustomerID"], f"${float(o['TotalAmount']):,.2f}", str(o["OrderDate"])[:19], o["PaymentStatus"]] for o in orders]
        print(tabulate(ord_rows, headers=["OrderID", "Order #", "Cust ID", "Total Amount", "Order Date", "Status"], tablefmt="github"))

        conn.close()
    except Exception as e:
        print(f"[-] Could not connect to SQL Server: {e}")
        print("    Make sure docker container is running: docker compose -f docker/docker-compose.yml up -d")

def check_postgres(cfg):
    print("\n" + "="*70)
    print(" 2. TARGET DATABASE CHECK: POSTGRESQL (enterprisedb)")
    print("="*70)
    try:
        import psycopg2
        tgt = cfg.get("target", {})
        host = os.environ.get("PG_HOST", "postgres" if IS_DOCKER else tgt.get("host", "localhost"))
        port = int(os.environ.get("PG_PORT", 5432 if IS_DOCKER else tgt.get("port", 5434)))
        conn = psycopg2.connect(
            host=host,
            port=port,
            user=tgt.get("user", "postgres"),
            password=tgt.get("password", "postgres_password"),
            dbname=tgt.get("database", "enterprisedb")
        )
        cur = conn.cursor()
        
        # 1. Total Tables
        cur.execute("""
            SELECT table_schema, table_name
            FROM information_schema.tables
            WHERE table_schema IN ('core', 'inventory', 'sales', 'audit')
            ORDER BY table_schema, table_name;
        """)
        tables = cur.fetchall()
        
        if not tables:
            print("\n[-] Target PostgreSQL currently has 0 migrated tables.")
            print("    Run 'python run_migration.py run-all' to deploy schema and migrate data.")
            conn.close()
            return
            
        table_rows = []
        for schema, tbl in tables:
            cur.execute(f'SELECT COUNT(*) FROM "{schema}"."{tbl}";')
            cnt = cur.fetchone()[0]
            table_rows.append([schema, tbl, cnt])
            
        print(f"\n[+] Connected successfully to PostgreSQL! Found {len(tables)} tables:\n")
        print(tabulate(table_rows, headers=["Schema", "Table Name", "Row Count"], tablefmt="github"))
        
        # 2. Sample Data from Customers
        print("\n[+] Sample Data from 'core.customers' (Top 3 records):")
        cur.execute("SELECT customer_id, company_name, contact_name, email, credit_limit FROM core.customers LIMIT 3;")
        customers = cur.fetchall()
        cust_rows = [[c[0], c[1] or "N/A", c[2], c[3], f"${float(c[4]):,.2f}"] for c in customers]
        print(tabulate(cust_rows, headers=["customer_id", "company_name", "contact_name", "email", "credit_limit"], tablefmt="github"))

        conn.close()
    except Exception as e:
        print(f"[-] Could not connect to PostgreSQL: {e}")

def check_mysql():
    print("\n" + "="*70)
    print(" 3. OPTIONAL LOCAL MYSQL CHECK (Port 3306)")
    print("="*70)
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        res = s.connect_ex(('localhost', 3306))
        s.close()
        if res == 0:
            print("[+] MySQL Service is actively listening on localhost:3306.")
            print("    (Note: This POC is configured for SQL Server -> PostgreSQL migration.")
            print("     If your client uses MySQL as source, the architecture also supports MySQL via PyMySQL).")
        else:
            print("[-] MySQL port 3306 is not listening.")
    except Exception as e:
        print(f"[-] MySQL check note: {e}")

if __name__ == "__main__":
    with open("config/config.yaml", "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    
    check_sql_server(cfg)
    check_postgres(cfg)
    check_mysql()
    print("\n" + "="*70)
    print(" CHECK COMPLETE")
    print("="*70 + "\n")
