# Migration Reconciliation Audit Report

**Overall Status**: PASSED (100% Match)

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
