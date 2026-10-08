-- ============================================================================
-- SQL Server Seed Data: EnterpriseSalesERP
-- Populates realistic business records across core, inventory, sales, audit
-- ============================================================================

USE EnterpriseSalesERP;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

-- ----------------------------------------------------------------------------
-- 1. core.Countries
-- ----------------------------------------------------------------------------
INSERT INTO core.Countries (CountryCode, CountryName, CurrencyCode, IsActive) VALUES
('US', 'United States', 'USD', 1),
('CA', 'Canada', 'CAD', 1),
('GB', 'United Kingdom', 'GBP', 1),
('DE', 'Germany', 'EUR', 1),
('FR', 'France', 'EUR', 1),
('JP', 'Japan', 'JPY', 1),
('AU', 'Australia', 'AUD', 1),
('SG', 'Singapore', 'SGD', 1);
GO

-- ----------------------------------------------------------------------------
-- 2. core.Departments
-- ----------------------------------------------------------------------------
INSERT INTO core.Departments (DepartmentCode, DepartmentName, Budget, IsActive) VALUES
('EXEC', 'Executive Leadership', 750000.00, 1),
('ENG', 'Engineering & Technology', 1250000.00, 1),
('SALES', 'Global Sales & Distribution', 950000.00, 1),
('OPS', 'Supply Chain Operations', 680000.00, 1),
('FIN', 'Finance & Accounting', 420000.00, 1),
('HR', 'Human Resources', 260000.00, 1);
GO

-- ----------------------------------------------------------------------------
-- 3. core.Employees (Including hierarchy)
-- ----------------------------------------------------------------------------
-- Leaders first (ManagerEmployeeID = NULL)
INSERT INTO core.Employees (DepartmentID, ManagerEmployeeID, FirstName, LastName, JobTitle, Email, Phone, HireDate, Salary, CommissionRate, IsActive) VALUES
(10, NULL, 'Eleanor', 'Vance', 'Chief Executive Officer', 'eleanor.vance@enterprise.io', '+1-555-0100', '2019-01-15', 210000.00, 0.0500, 1),
(20, NULL, 'Marcus', 'Sterling', 'VP of Engineering', 'marcus.sterling@enterprise.io', '+1-555-0101', '2019-03-01', 175000.00, 0.0000, 1),
(30, NULL, 'Diana', 'Prince', 'VP of Global Sales', 'diana.prince@enterprise.io', '+1-555-0102', '2019-04-10', 165000.00, 0.0800, 1),
(40, NULL, 'Robert', 'Langdon', 'Director of Supply Chain', 'robert.langdon@enterprise.io', '+1-555-0103', '2020-02-15', 140000.00, 0.0200, 1);

-- Middle managers & staff (pointing to leaders above)
-- IDs will start at 501, 502, 503, 504
INSERT INTO core.Employees (DepartmentID, ManagerEmployeeID, FirstName, LastName, JobTitle, Email, Phone, HireDate, Salary, CommissionRate, IsActive) VALUES
(30, 503, 'Arthur', 'Pendelton', 'Senior Account Executive', 'arthur.p@enterprise.io', '+1-555-0104', '2021-06-01', 95000.00, 0.0500, 1),
(30, 503, 'Sonia', 'Gupta', 'Regional Sales Manager', 'sonia.gupta@enterprise.io', '+1-555-0105', '2021-08-15', 105000.00, 0.0600, 1),
(20, 502, 'David', 'Kim', 'Lead Cloud Architect', 'david.kim@enterprise.io', '+1-555-0106', '2020-11-01', 145000.00, 0.0000, 1),
(40, 504, 'Elena', 'Rostova', 'Logistics Coordinator', 'elena.rostova@enterprise.io', '+1-555-0107', '2022-03-20', 78000.00, 0.0000, 1);
GO

-- ----------------------------------------------------------------------------
-- 4. core.Customers
-- ----------------------------------------------------------------------------
INSERT INTO core.Customers (CustomerType, CompanyName, ContactName, Email, Phone, TaxNumber, CreditLimit, IsActive, MetadataJson) VALUES
('CORPORATE', 'Acme Global Industrial', 'Johnathan Davis', 'jdavis@acmeglobal.com', '+1-555-0201', 'TAX-US-99128', 50000.00, 1, '{"tier":"enterprise","industry":"manufacturing","net_terms":30}'),
('CORPORATE', 'BlueSky Logistics Corp', 'Sarah Jenkins', 'sjenkins@blueskylog.com', '+1-555-0202', 'TAX-US-77812', 35000.00, 1, '{"tier":"midmarket","industry":"transport","net_terms":15}'),
('INDIVIDUAL', NULL, 'Emily Watson', 'emily.watson@gmail.com', '+1-555-0203', NULL, 5000.00, 1, '{"channel":"direct_web","preferences":{"sms_opt_in":true}}'),
('INDIVIDUAL', NULL, 'Carlos Mendoza', 'cmendoza@outlook.com', '+1-555-0204', NULL, 7500.00, 1, '{"channel":"mobile_app","preferences":{"sms_opt_in":false}}'),
('CORPORATE', 'Apex Quantum Systems', 'Dr. Aris Thorne', 'athorne@apexquantum.io', '+1-555-0205', 'TAX-US-44319', 100000.00, 1, '{"tier":"vip","industry":"aerospace","discount_tier":"gold"}'),
('GOVERNMENT', 'Metro Transit Authority', 'Frank Castle', 'fcastle@metrotransit.gov', '+1-555-0206', 'TAX-GOV-0012', 200000.00, 1, '{"tier":"gov","procurement_code":"MTA-88"}'),
('INDIVIDUAL', NULL, 'Aisha Al-Mansoor', 'aisha.m@protonmail.com', '+1-555-0207', NULL, 12000.00, 1, '{"channel":"direct_web","locale":"en_US"}'),
('INDIVIDUAL', NULL, 'Kenji Sato', 'kenji.sato@yahoo.co.jp', '+81-90-555-0208', NULL, 6000.00, 1, '{"channel":"partner_referral"}');
GO

-- ----------------------------------------------------------------------------
-- 5. core.CustomerAddresses
-- ----------------------------------------------------------------------------
INSERT INTO core.CustomerAddresses (CustomerID, AddressType, Line1, Line2, City, State, PostalCode, CountryCode, IsDefault) VALUES
(1001, 'Office', '1000 Industrial Parkway', 'Suite 400', 'Chicago', 'IL', '60601', 'US', 1),
(1001, 'Billing', 'PO Box 4892', NULL, 'Chicago', 'IL', '60602', 'US', 0),
(1002, 'Office', '742 Evergreen Terrace', 'Floor 2', 'Seattle', 'WA', '98101', 'US', 1),
(1003, 'Shipping', '42 Highfield Road', NULL, 'London', NULL, 'NW1 4NP', 'GB', 1),
(1003, 'Billing', '42 Highfield Road', NULL, 'London', NULL, 'NW1 4NP', 'GB', 0),
(1004, 'Shipping', 'Avenida Paulista 1578', 'Apto 101', 'San Francisco', 'CA', '94105', 'US', 1),
(1005, 'Office', '500 Tech Boulevard', 'Building C', 'Austin', 'TX', '78701', 'US', 1),
(1006, 'Office', '1 Civic Center Plaza', 'Room 305', 'New York', 'NY', '10007', 'US', 1);
GO

-- ----------------------------------------------------------------------------
-- 6. core.CustomerProfiles
-- ----------------------------------------------------------------------------
INSERT INTO core.CustomerProfiles (CustomerID, LoyaltyTier, LoyaltyPoints, PreferredCurrency, MarketingOptIn, Bio, PreferencesXml, LastLoginAt) VALUES
(1001, 'PLATINUM', 45200, 'USD', 1, 'Leading manufacturing enterprise account.', '<prefs><theme>dark</theme><notifications>weekly</notifications></prefs>', '2026-03-01 10:25:00'),
(1002, 'GOLD', 18400, 'USD', 1, 'Midwest distribution partner.', '<prefs><theme>light</theme><notifications>daily</notifications></prefs>', '2026-02-28 14:15:30'),
(1003, 'SILVER', 5200, 'GBP', 0, 'Retail consumer from UK.', '<prefs><theme>system</theme></prefs>', '2026-03-02 09:00:00'),
(1004, 'BRONZE', 1250, 'USD', 1, 'Independent tech contractor.', '<prefs><theme>dark</theme></prefs>', '2026-02-25 18:40:12'),
(1005, 'PLATINUM', 98000, 'USD', 1, 'Key account for quantum hardware.', '<prefs><theme>dark</theme><expedited_shipping>true</expedited_shipping></prefs>', '2026-03-03 16:50:00'),
(1006, 'GOLD', 21500, 'USD', 0, 'Public transportation agency.', '<prefs><theme>light</theme></prefs>', '2026-01-20 11:10:00');
GO

-- ----------------------------------------------------------------------------
-- 7. inventory.Suppliers
-- ----------------------------------------------------------------------------
INSERT INTO inventory.Suppliers (SupplierName, ContactName, Email, Phone, Rating, IsPreferred, PaymentTermsDays) VALUES
('Titan Industrial Components', 'Viktor Hansen', 'vhansen@titan-ind.de', '+49-89-555-0301', 5, 1, 30),
('Nova Electronics Pte', 'Mei Ling Tan', 'tan.ml@novaelectronics.sg', '+65-6789-0302', 4, 1, 45),
('Pacific Raw Materials Ltd', 'Bruce Campbell', 'bcampbell@pacificraw.com.au', '+61-2-9555-0303', 4, 0, 30),
('Global Precision Plastics', 'Genevieve DuPont', 'gdupont@globalpp.fr', '+33-1-555-0304', 3, 0, 60);
GO

-- ----------------------------------------------------------------------------
-- 8. inventory.Categories (Hierarchy: Root and Child)
-- ----------------------------------------------------------------------------
INSERT INTO inventory.Categories (ParentCategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(NULL, 'CAT_HARDWARE', 'Industrial Hardware', 'Heavy mechanical and industrial components', 1),
(NULL, 'CAT_ELECTRONICS', 'Electronics & Sensors', 'High precision sensors and embedded circuits', 1),
(NULL, 'CAT_PACKAGING', 'Packaging Supplies', 'Industrial shipping containers and protective materials', 1);

-- Child categories (CategoryID 1, 2, 3)
INSERT INTO inventory.Categories (ParentCategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(1, 'CAT_FASTENERS', 'Fasteners & Bolts', 'High-tensile bolts, nuts, and anchoring systems', 1),
(1, 'CAT_VALVES', 'Pneumatic Valves', 'Hydraulic and pneumatic flow control valves', 1),
(2, 'CAT_SENSORS_TEMP', 'Thermal Sensors', 'Thermocouples and IR temperature sensing modules', 1),
(2, 'CAT_IOT_NODES', 'IoT Telemetry Nodes', 'Wireless industrial IoT modules', 1);
GO

-- ----------------------------------------------------------------------------
-- 9. inventory.ProductBrands
-- ----------------------------------------------------------------------------
INSERT INTO inventory.ProductBrands (BrandCode, BrandName, WebsiteUrl, IsActive) VALUES
('BRAND_TITAN', 'Titan HeavyWorks', 'https://titan-heavyworks.com', 1),
('BRAND_NOVASENSE', 'NovaSense Labs', 'https://novasenselabs.io', 1),
('BRAND_AEROVECT', 'AeroVect Precision', 'https://aerovect.com', 1),
('BRAND_ECOPACK', 'EcoPack Solutions', 'https://ecopack-global.com', 1);
GO

-- ----------------------------------------------------------------------------
-- 10. inventory.Warehouses
-- ----------------------------------------------------------------------------
INSERT INTO inventory.Warehouses (WarehouseCode, WarehouseName, CountryCode, City, CapacitySqFt, IsBonded) VALUES
('WH-US-EAST', 'East Coast Distribution Center', 'US', 'Newark', 150000, 1),
('WH-US-WEST', 'West Coast Logistics Hub', 'US', 'Reno', 220000, 0),
('WH-EU-CENTRAL', 'European Central Fulfillment', 'DE', 'Frankfurt', 180000, 1),
('WH-APAC-SING', 'APAC Singapore Regional Hub', 'SG', 'Singapore', 95000, 0);
GO

-- ----------------------------------------------------------------------------
-- 11. inventory.Products
-- ----------------------------------------------------------------------------
INSERT INTO inventory.Products (SKU, ProductName, BrandID, CategoryID, PrimarySupplierID, UnitCost, ListPrice, WeightKg, DimensionsCm, Barcode, IsDiscontinued, Description) VALUES
('PRD-BOLT-M12-SS', 'M12 Stainless Steel Hex Bolt 50mm', 1, 4, 1, 0.4500, 1.25, 0.085, '5x1.2x1.2', '793573190012', 0, 'Marine-grade 316 stainless steel hex head bolt.'),
('PRD-VALVE-PN16', 'Pneumatic Solenoid Valve 24V DC', 1, 5, 1, 24.5000, 58.00, 0.650, '12x8x6', '793573190029', 0, 'Direct-acting 5/2-way high response solenoid valve.'),
('PRD-TEMP-IR-100', 'Industrial Non-Contact Infrared Sensor', 2, 6, 2, 68.0000, 149.00, 0.220, '9x4x4', '793573190036', 0, 'Precision pyrometer with 4-20mA output interface.'),
('PRD-IOT-WIFI-GW', 'Ruggedized IoT Gateway Node IP67', 2, 7, 2, 115.0000, 249.00, 0.850, '18x12x5', '793573190043', 0, 'Industrial wireless sensor bridge with dual SIM failover.'),
('PRD-BOX-HD-PALLET', 'Heavy-Duty Corrugated Pallet Box', 4, 3, 4, 6.2000, 14.50, 2.400, '120x80x90', '793573190050', 0, 'Reinforced double-wall export carton.'),
('PRD-FLANGE-ANSI150', '2-Inch Carbon Steel ANSI Flange', 3, 1, 3, 38.0000, 89.00, 3.800, '15x15x4', '793573190067', 0, 'Class 150 weld neck flange.');
GO

-- ----------------------------------------------------------------------------
-- 12. inventory.ProductVariants
-- ----------------------------------------------------------------------------
INSERT INTO inventory.ProductVariants (ProductID, VariantSKU, Color, Size, Material, PriceDelta, Barcode, IsActive) VALUES
(10001, 'VAR-BOLT-M12-50', 'Silver', '50mm', 'SS-316', 0.00, '793573190012-50', 1),
(10001, 'VAR-BOLT-M12-75', 'Silver', '75mm', 'SS-316', 0.35, '793573190012-75', 1),
(10002, 'VAR-VALVE-24V', 'Black', 'Standard', 'Brass/PTFE', 0.00, '793573190029-24', 1),
(10002, 'VAR-VALVE-110V', 'Black', 'Standard', 'Brass/PTFE', 5.00, '793573190029-11', 1),
(10003, 'VAR-TEMP-WIDE', 'Metallic Grey', 'Wide-Angle', 'Anodized AL', 15.00, '793573190036-W', 1),
(10004, 'VAR-IOT-LTE-M', 'Industrial Blue', 'Standard', 'Polycarbonate', 25.00, '793573190043-L', 1);
GO

-- ----------------------------------------------------------------------------
-- 13. inventory.ProductInventory (Composite PK)
-- ----------------------------------------------------------------------------
INSERT INTO inventory.ProductInventory (ProductID, WarehouseID, QuantityOnHand, QuantityReserved, ReorderPoint, SafetyStock, LastRestockedAt) VALUES
(10001, 1, 5000, 250, 1000, 200, '2026-02-15 08:30:00'),
(10001, 2, 3500, 120, 800, 150, '2026-02-18 11:20:00'),
(10002, 1, 320, 45, 50, 15, '2026-02-20 14:00:00'),
(10002, 3, 210, 10, 40, 10, '2026-02-22 09:15:00'),
(10003, 1, 180, 25, 30, 10, '2026-02-25 10:45:00'),
(10003, 4, 95, 5, 20, 5, '2026-02-27 16:30:00'),
(10004, 2, 140, 18, 25, 5, '2026-03-01 13:00:00'),
(10005, 1, 1200, 150, 300, 50, '2026-02-10 07:00:00'),
(10006, 3, 85, 8, 20, 5, '2026-02-12 15:20:00');
GO

-- ----------------------------------------------------------------------------
-- 14. inventory.InventoryTransactions
-- ----------------------------------------------------------------------------
INSERT INTO inventory.InventoryTransactions (ProductID, WarehouseID, TransactionType, QuantityDelta, ReferenceDocument, Notes, TransactionDate) VALUES
(10001, 1, 'PURCHASE_RECEIPT', 5000, 'PO-2026-0012', 'Initial batch receipt from Titan', '2026-02-15 08:30:00'),
(10002, 1, 'PURCHASE_RECEIPT', 350, 'PO-2026-0014', 'Direct container shipment', '2026-02-20 14:00:00'),
(10002, 1, 'STOCK_TRANSFER', -50, 'TR-2026-0089', 'Transfer to EU Central', '2026-02-21 10:00:00'),
(10002, 3, 'STOCK_TRANSFER', 50, 'TR-2026-0089', 'Received from US East', '2026-02-22 09:15:00'),
(10003, 1, 'PURCHASE_RECEIPT', 200, 'PO-2026-0019', 'Air cargo delivery from Singapore', '2026-02-25 10:45:00'),
(10001, 1, 'SALE_SHIPMENT', -250, 'ORD-2026-00101', 'Order shipment fulfillment', '2026-03-01 14:10:00');
GO

-- ----------------------------------------------------------------------------
-- 15. sales.PriceLists
-- ----------------------------------------------------------------------------
INSERT INTO sales.PriceLists (PriceListName, CurrencyCode, ValidFrom, ValidTo, IsDefault) VALUES
('Standard USD Wholesale', 'USD', '2026-01-01', '2026-12-31', 1),
('European Enterprise EUR', 'EUR', '2026-01-01', '2026-12-31', 0),
('APAC Regional SGD', 'SGD', '2026-01-01', '2026-12-31', 0);
GO

-- ----------------------------------------------------------------------------
-- 16. sales.Promotions
-- ----------------------------------------------------------------------------
INSERT INTO sales.Promotions (PromoCode, PromoName, DiscountPercent, MinOrderAmount, StartDate, EndDate, IsActive) VALUES
('Q1-LAUNCH10', 'Q1 Hardware Launch Event', 10.00, 1000.00, '2026-01-01 00:00:00', '2026-03-31 23:59:59', 1),
('VIP-EXP-15', 'Enterprise Tier Partnership', 15.00, 5000.00, '2026-01-01 00:00:00', '2026-12-31 23:59:59', 1),
('SPRING-CLEAN5', 'Spring Surplus Inventory Clearance', 5.00, 500.00, '2026-03-01 00:00:00', '2026-04-30 23:59:59', 1);
GO

-- ----------------------------------------------------------------------------
-- 17. sales.Orders
-- ----------------------------------------------------------------------------
INSERT INTO sales.Orders (OrderNumber, CustomerID, SalesRepEmployeeID, ShippingAddressID, OrderStatus, OrderDate, RequiredDate, ShippedDate, SubTotal, TaxAmount, ShippingCost, DiscountTotal, TotalAmount, PaymentStatus, SpecialInstructions) VALUES
('ORD-2026-00101', 1001, 505, 1, 4, '2026-02-26 11:30:00', '2026-03-05 17:00:00', '2026-02-28 15:45:00', 8700.00, 696.00, 120.00, 870.00, 8646.00, 'PAID', 'Deliver to Bay 4 loading dock.'),
('ORD-2026-00102', 1002, 505, 3, 3, '2026-02-27 14:10:00', '2026-03-06 17:00:00', NULL, 3576.00, 286.08, 65.00, 0.00, 3927.08, 'PAID', 'Contact warehouse manager upon arrival.'),
('ORD-2026-00103', 1005, 506, 7, 2, '2026-03-01 09:20:00', '2026-03-10 17:00:00', NULL, 14940.00, 1195.20, 250.00, 2241.00, 14144.20, 'AUTHORIZED', 'Requires cleanroom-grade outer packaging.'),
('ORD-2026-00104', 1003, NULL, 4, 1, '2026-03-02 16:45:00', '2026-03-09 17:00:00', NULL, 298.00, 23.84, 15.00, 0.00, 336.84, 'PENDING', 'Leave by side porch if unattended.'),
('ORD-2026-00105', 1006, 506, 8, 4, '2026-02-15 10:00:00', '2026-02-25 17:00:00', '2026-02-20 12:30:00', 12450.00, 0.00, 350.00, 1245.00, 11555.00, 'PAID', 'Municipal tax exempt certificate on file.');
GO

-- ----------------------------------------------------------------------------
-- 18. sales.OrderItems
-- ----------------------------------------------------------------------------
-- For Order 500001
INSERT INTO sales.OrderItems (OrderID, LineNumber, ProductID, VariantID, Quantity, UnitPrice, DiscountAmount, TotalLinePrice, Notes) VALUES
(500001, 1, 10001, 1, 2000, 1.25, 250.00, 2250.00, 'Bulk box packaging'),
(500001, 2, 10002, 3, 50, 58.00, 290.00, 2610.00, '24V solenoid standard'),
(500001, 3, 10003, 5, 25, 154.00, 330.00, 3520.00, 'Thermal sensors wide angle');

-- For Order 500002
INSERT INTO sales.OrderItems (OrderID, LineNumber, ProductID, VariantID, Quantity, UnitPrice, DiscountAmount, TotalLinePrice, Notes) VALUES
(500002, 1, 10002, 3, 30, 58.00, 0.00, 1740.00, 'Standard supply'),
(500002, 2, 10004, 6, 6, 274.00, 0.00, 1644.00, 'IoT bridge nodes'),
(500002, 3, 10005, NULL, 10, 14.50, 0.00, 145.00, 'Pallet containers');

-- For Order 500003
INSERT INTO sales.OrderItems (OrderID, LineNumber, ProductID, VariantID, Quantity, UnitPrice, DiscountAmount, TotalLinePrice, Notes) VALUES
(500003, 1, 10004, 6, 60, 249.00, 2241.00, 12699.00, 'Enterprise batch');

-- For Order 500004
INSERT INTO sales.OrderItems (OrderID, LineNumber, ProductID, VariantID, Quantity, UnitPrice, DiscountAmount, TotalLinePrice, Notes) VALUES
(500004, 1, 10003, 5, 2, 149.00, 0.00, 298.00, 'Direct retail consumer');

-- For Order 500005
INSERT INTO sales.OrderItems (OrderID, LineNumber, ProductID, VariantID, Quantity, UnitPrice, DiscountAmount, TotalLinePrice, Notes) VALUES
(500005, 1, 10004, 6, 50, 249.00, 1245.00, 11205.00, 'MTA project phase 1');
GO

-- ----------------------------------------------------------------------------
-- 19. sales.OrderDiscounts (Composite PK)
-- ----------------------------------------------------------------------------
INSERT INTO sales.OrderDiscounts (OrderID, PromotionID, DiscountApplied) VALUES
(500001, 1, 870.00),
(500003, 2, 2241.00),
(500005, 1, 1245.00);
GO

-- ----------------------------------------------------------------------------
-- 20. sales.OrderFulfillments
-- ----------------------------------------------------------------------------
INSERT INTO sales.OrderFulfillments (OrderID, WarehouseID, Carrier, TrackingNumber, Status, ShippedAt, DeliveredAt) VALUES
(500001, 1, 'FedEx Freight', 'FXF-992182741', 'DELIVERED', '2026-02-28 15:45:00', '2026-03-02 11:15:00'),
(500002, 2, 'UPS Ground', '1Z9999999999999999', 'PACKED', NULL, NULL),
(500005, 1, 'R+L Carriers', 'RL-441098273', 'DELIVERED', '2026-02-20 12:30:00', '2026-02-22 14:00:00');
GO

-- ----------------------------------------------------------------------------
-- 21. sales.Invoices (1:1 with Orders)
-- ----------------------------------------------------------------------------
INSERT INTO sales.Invoices (InvoiceNumber, OrderID, InvoiceDate, DueDate, SubTotal, TaxAmount, TotalAmount, AmountPaid, BalanceDue, Status) VALUES
('INV-2026-0001', 500001, '2026-02-26', '2026-03-28', 8700.00, 696.00, 8646.00, 8646.00, 0.00, 'PAID'),
('INV-2026-0002', 500002, '2026-02-27', '2026-03-29', 3576.00, 286.08, 3927.08, 3927.08, 0.00, 'PAID'),
('INV-2026-0003', 500003, '2026-03-01', '2026-03-31', 14940.00, 1195.20, 14144.20, 0.00, 14144.20, 'ISSUED'),
('INV-2026-0004', 500004, '2026-03-02', '2026-03-12', 298.00, 23.84, 336.84, 0.00, 336.84, 'ISSUED'),
('INV-2026-0005', 500005, '2026-02-15', '2026-03-17', 12450.00, 0.00, 11555.00, 11555.00, 0.00, 'PAID');
GO

-- ----------------------------------------------------------------------------
-- 22. sales.Payments
-- ----------------------------------------------------------------------------
INSERT INTO sales.Payments (InvoiceID, CustomerID, PaymentMethod, Amount, CurrencyCode, TransactionReference, Status, ProcessedAt, GatewayResponse) VALUES
(1, 1001, 'BANK_TRANSFER', 8646.00, 'USD', 'TXN-ACH-2026-00192', 'COMPLETED', '2026-02-27 10:14:00', '{"processor":"Stripe","code":"succeeded","charge_id":"ch_12948"}'),
(2, 1002, 'CREDIT_CARD', 3927.08, 'USD', 'TXN-CC-2026-00381', 'COMPLETED', '2026-02-27 14:12:30', '{"processor":"Adyen","auth_code":"882194","last4":"4242"}'),
(5, 1006, 'BANK_TRANSFER', 11555.00, 'USD', 'TXN-WIRE-2026-00088', 'COMPLETED', '2026-02-18 09:30:00', '{"processor":"FedWire","ref":"FW-992104"}');
GO

-- ----------------------------------------------------------------------------
-- 23. sales.OrderNotes
-- ----------------------------------------------------------------------------
INSERT INTO sales.OrderNotes (OrderID, AuthorEmployeeID, NoteText, IsInternalOnly) VALUES
(500001, 505, 'Customer requested priority morning dock delivery. Notified logistics coordinator.', 1),
(500003, 506, 'Approved customized discount tier per CEO waiver agreement.', 1),
(500005, 506, 'MTA project phase 1 delivery confirmed and inspected.', 0);
GO

-- ----------------------------------------------------------------------------
-- 24. sales.CustomerReviews
-- ----------------------------------------------------------------------------
INSERT INTO sales.CustomerReviews (CustomerID, ProductID, Rating, ReviewTitle, ReviewBody, IsVerifiedPurchase, IsApproved) VALUES
(1001, 10001, 5, 'Exceptional quality bolts', 'Flawless machining and threading. Used on marine pump assemblies with zero corrosion.', 1, 1),
(1001, 10002, 4, 'Reliable valve, slightly loud', 'Solid pneumatic response times. Solenoid click is perceptible in quiet rooms.', 1, 1),
(1003, 10003, 5, 'Dead accurate infrared readout', 'Tested against calibrated reference thermometer. Spot on within 0.1 deg C.', 1, 1),
(1004, 10004, 4, 'Great telemetry connectivity', 'Simple setup on AWS IoT Core. Solid enclosure build.', 1, 1);
GO

-- ----------------------------------------------------------------------------
-- 25. audit.AuditLogs
-- ----------------------------------------------------------------------------
INSERT INTO audit.AuditLogs (SchemaName, TableName, RecordKey, ActionType, ChangedBy, ChangedAt, OldValuesJson, NewValuesJson) VALUES
('sales', 'Orders', '500001', 'INSERT', 'system_seed', '2026-02-26 11:30:00', NULL, '{"OrderNumber":"ORD-2026-00101","TotalAmount":8646.00}'),
('sales', 'Orders', '500001', 'UPDATE', 'arthur.p', '2026-02-28 15:45:00', '{"OrderStatus":1}', '{"OrderStatus":4,"ShippedDate":"2026-02-28"}'),
('sales', 'Invoices', '1', 'UPDATE', 'payment_gateway', '2026-02-27 10:14:00', '{"Status":"ISSUED","BalanceDue":8646.00}', '{"Status":"PAID","BalanceDue":0.00}');
GO

-- ----------------------------------------------------------------------------
-- 26. audit.SystemConfigurations
-- ----------------------------------------------------------------------------
INSERT INTO audit.SystemConfigurations (ConfigKey, ConfigValue, DataType, Description, IsEncrypted, UpdatedAt) VALUES
('APP_ENV', 'Production', 'STRING', 'Operating environment deployment tier', 0, '2026-01-01 00:00:00'),
('MAX_BATCH_SIZE', '5000', 'INTEGER', 'Maximum records for ETL chunking pipeline', 0, '2026-01-01 00:00:00'),
('DEFAULT_CURRENCY', 'USD', 'STRING', 'Base functional currency for ledger', 0, '2026-01-01 00:00:00'),
('ENABLE_AUDIT_LOGGING', 'true', 'BOOLEAN', 'Flag to trigger row-level audit event stream', 0, '2026-01-01 00:00:00'),
('PAYMENT_GATEWAY_ENDPOINT', 'https://api.stripe.com/v1', 'STRING', 'Payment integration base URL', 0, '2026-01-01 00:00:00');
GO
