-- ============================================================================
-- SQL Server Source Database: EnterpriseSalesERP
-- Realistic Enterprise E-Commerce & Supply Chain Architecture (24 Tables)
-- Schemas: core, inventory, sales, audit
-- ============================================================================

IF DB_ID('EnterpriseSalesERP') IS NULL
BEGIN
    CREATE DATABASE EnterpriseSalesERP;
END
GO

USE EnterpriseSalesERP;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Create schemas
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'inventory')
    EXEC('CREATE SCHEMA inventory');
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'sales')
    EXEC('CREATE SCHEMA sales');
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit')
    EXEC('CREATE SCHEMA audit');
GO

-- ----------------------------------------------------------------------------
-- SCHEMA: core
-- ----------------------------------------------------------------------------

-- Table 1: core.Countries
CREATE TABLE core.Countries (
    CountryCode CHAR(2) NOT NULL,
    CountryName NVARCHAR(100) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Countries_IsActive DEFAULT 1,
    CONSTRAINT PK_Countries PRIMARY KEY CLUSTERED (CountryCode)
);
GO

-- Table 2: core.Customers
CREATE TABLE core.Customers (
    CustomerID INT IDENTITY(1001, 1) NOT NULL,
    CustomerGUID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Customers_GUID DEFAULT NEWID(),
    CustomerType VARCHAR(20) NOT NULL CONSTRAINT DF_Customers_Type DEFAULT 'INDIVIDUAL',
    CompanyName NVARCHAR(150) NULL,
    ContactName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    Phone VARCHAR(30) NULL,
    TaxNumber VARCHAR(50) NULL,
    CreditLimit DECIMAL(12, 2) NOT NULL CONSTRAINT DF_Customers_CreditLimit DEFAULT 5000.00,
    IsActive BIT NOT NULL CONSTRAINT DF_Customers_IsActive DEFAULT 1,
    MetadataJson NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerID),
    CONSTRAINT UQ_Customers_Email UNIQUE (Email),
    CONSTRAINT CK_Customers_CustomerType CHECK (CustomerType IN ('INDIVIDUAL', 'CORPORATE', 'GOVERNMENT'))
);
GO

-- Table 3: core.CustomerAddresses
CREATE TABLE core.CustomerAddresses (
    AddressID INT IDENTITY(1, 1) NOT NULL,
    CustomerID INT NOT NULL,
    AddressType VARCHAR(20) NOT NULL,
    Line1 NVARCHAR(150) NOT NULL,
    Line2 NVARCHAR(150) NULL,
    City NVARCHAR(100) NOT NULL,
    State NVARCHAR(50) NULL,
    PostalCode VARCHAR(20) NOT NULL,
    CountryCode CHAR(2) NOT NULL,
    IsDefault BIT NOT NULL CONSTRAINT DF_CustomerAddresses_IsDefault DEFAULT 0,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_CustomerAddresses_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CustomerAddresses PRIMARY KEY CLUSTERED (AddressID),
    CONSTRAINT FK_CustomerAddresses_Customer FOREIGN KEY (CustomerID) REFERENCES core.Customers(CustomerID) ON DELETE CASCADE,
    CONSTRAINT FK_CustomerAddresses_Country FOREIGN KEY (CountryCode) REFERENCES core.Countries(CountryCode),
    CONSTRAINT CK_CustomerAddresses_Type CHECK (AddressType IN ('Billing', 'Shipping', 'Office'))
);
GO

-- Table 4: core.CustomerProfiles (1:1 with Customers)
CREATE TABLE core.CustomerProfiles (
    ProfileID INT IDENTITY(1, 1) NOT NULL,
    CustomerID INT NOT NULL,
    LoyaltyTier VARCHAR(20) NOT NULL CONSTRAINT DF_CustomerProfiles_Tier DEFAULT 'BRONZE',
    LoyaltyPoints INT NOT NULL CONSTRAINT DF_CustomerProfiles_Points DEFAULT 0,
    PreferredCurrency CHAR(3) NOT NULL CONSTRAINT DF_CustomerProfiles_Curr DEFAULT 'USD',
    MarketingOptIn BIT NOT NULL CONSTRAINT DF_CustomerProfiles_Marketing DEFAULT 0,
    Bio NVARCHAR(500) NULL,
    PreferencesXml NVARCHAR(MAX) NULL, -- XML stored as string for compatibility
    LastLoginAt DATETIME2(7) NULL,
    CONSTRAINT PK_CustomerProfiles PRIMARY KEY CLUSTERED (ProfileID),
    CONSTRAINT UQ_CustomerProfiles_CustomerID UNIQUE (CustomerID),
    CONSTRAINT FK_CustomerProfiles_Customer FOREIGN KEY (CustomerID) REFERENCES core.Customers(CustomerID) ON DELETE CASCADE,
    CONSTRAINT CK_CustomerProfiles_LoyaltyTier CHECK (LoyaltyTier IN ('BRONZE', 'SILVER', 'GOLD', 'PLATINUM'))
);
GO

-- Table 5: core.Departments
CREATE TABLE core.Departments (
    DepartmentID INT IDENTITY(10, 10) NOT NULL,
    DepartmentCode VARCHAR(20) NOT NULL,
    DepartmentName NVARCHAR(100) NOT NULL,
    Budget DECIMAL(14, 2) NOT NULL CONSTRAINT DF_Departments_Budget DEFAULT 0.00,
    IsActive BIT NOT NULL CONSTRAINT DF_Departments_IsActive DEFAULT 1,
    CONSTRAINT PK_Departments PRIMARY KEY CLUSTERED (DepartmentID),
    CONSTRAINT UQ_Departments_Code UNIQUE (DepartmentCode)
);
GO

-- Table 6: core.Employees (Hierarchical self-referential FK)
CREATE TABLE core.Employees (
    EmployeeID INT IDENTITY(501, 1) NOT NULL,
    DepartmentID INT NOT NULL,
    ManagerEmployeeID INT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    JobTitle NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    Phone VARCHAR(30) NULL,
    HireDate DATE NOT NULL,
    Salary DECIMAL(12, 2) NOT NULL,
    CommissionRate DECIMAL(5, 4) NOT NULL CONSTRAINT DF_Employees_CommissionRate DEFAULT 0.0000,
    IsActive BIT NOT NULL CONSTRAINT DF_Employees_IsActive DEFAULT 1,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Employees_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Employees PRIMARY KEY CLUSTERED (EmployeeID),
    CONSTRAINT UQ_Employees_Email UNIQUE (Email),
    CONSTRAINT FK_Employees_Department FOREIGN KEY (DepartmentID) REFERENCES core.Departments(DepartmentID),
    CONSTRAINT FK_Employees_Manager FOREIGN KEY (ManagerEmployeeID) REFERENCES core.Employees(EmployeeID)
);
GO

-- ----------------------------------------------------------------------------
-- SCHEMA: inventory
-- ----------------------------------------------------------------------------

-- Table 7: inventory.Suppliers
CREATE TABLE inventory.Suppliers (
    SupplierID INT IDENTITY(1, 1) NOT NULL,
    SupplierName NVARCHAR(150) NOT NULL,
    ContactName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    Phone VARCHAR(30) NULL,
    Rating TINYINT NOT NULL CONSTRAINT DF_Suppliers_Rating DEFAULT 3,
    IsPreferred BIT NOT NULL CONSTRAINT DF_Suppliers_IsPreferred DEFAULT 0,
    PaymentTermsDays SMALLINT NOT NULL CONSTRAINT DF_Suppliers_Terms DEFAULT 30,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Suppliers_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Suppliers PRIMARY KEY CLUSTERED (SupplierID),
    CONSTRAINT CK_Suppliers_Rating CHECK (Rating BETWEEN 1 AND 5)
);
GO

-- Table 8: inventory.Categories (Hierarchical tree)
CREATE TABLE inventory.Categories (
    CategoryID INT IDENTITY(1, 1) NOT NULL,
    ParentCategoryID INT NULL,
    CategoryCode VARCHAR(50) NOT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Categories_IsActive DEFAULT 1,
    CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (CategoryID),
    CONSTRAINT UQ_Categories_Code UNIQUE (CategoryCode),
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentCategoryID) REFERENCES inventory.Categories(CategoryID)
);
GO

-- Table 9: inventory.ProductBrands
CREATE TABLE inventory.ProductBrands (
    BrandID INT IDENTITY(1, 1) NOT NULL,
    BrandCode VARCHAR(50) NOT NULL,
    BrandName NVARCHAR(100) NOT NULL,
    WebsiteUrl VARCHAR(255) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_ProductBrands_IsActive DEFAULT 1,
    CONSTRAINT PK_ProductBrands PRIMARY KEY CLUSTERED (BrandID),
    CONSTRAINT UQ_ProductBrands_Code UNIQUE (BrandCode)
);
GO

-- Table 10: inventory.Warehouses
CREATE TABLE inventory.Warehouses (
    WarehouseID INT IDENTITY(1, 1) NOT NULL,
    WarehouseCode VARCHAR(20) NOT NULL,
    WarehouseName NVARCHAR(100) NOT NULL,
    CountryCode CHAR(2) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    CapacitySqFt INT NOT NULL CONSTRAINT DF_Warehouses_Capacity DEFAULT 10000,
    IsBonded BIT NOT NULL CONSTRAINT DF_Warehouses_Bonded DEFAULT 0,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Warehouses_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Warehouses PRIMARY KEY CLUSTERED (WarehouseID),
    CONSTRAINT UQ_Warehouses_Code UNIQUE (WarehouseCode),
    CONSTRAINT FK_Warehouses_Country FOREIGN KEY (CountryCode) REFERENCES core.Countries(CountryCode)
);
GO

-- Table 11: inventory.Products
CREATE TABLE inventory.Products (
    ProductID INT IDENTITY(10001, 1) NOT NULL,
    SKU VARCHAR(50) NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    BrandID INT NOT NULL,
    CategoryID INT NOT NULL,
    PrimarySupplierID INT NOT NULL,
    UnitCost DECIMAL(12, 4) NOT NULL,
    ListPrice DECIMAL(12, 2) NOT NULL,
    WeightKg DECIMAL(8, 3) NULL,
    DimensionsCm VARCHAR(50) NULL,
    Barcode VARCHAR(100) NULL,
    IsDiscontinued BIT NOT NULL CONSTRAINT DF_Products_IsDiscontinued DEFAULT 0,
    Description NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_Products PRIMARY KEY CLUSTERED (ProductID),
    CONSTRAINT UQ_Products_SKU UNIQUE (SKU),
    CONSTRAINT FK_Products_Brand FOREIGN KEY (BrandID) REFERENCES inventory.ProductBrands(BrandID),
    CONSTRAINT FK_Products_Category FOREIGN KEY (CategoryID) REFERENCES inventory.Categories(CategoryID),
    CONSTRAINT FK_Products_Supplier FOREIGN KEY (PrimarySupplierID) REFERENCES inventory.Suppliers(SupplierID),
    CONSTRAINT CK_Products_Price CHECK (ListPrice >= UnitCost)
);
GO

-- Table 12: inventory.ProductVariants
CREATE TABLE inventory.ProductVariants (
    VariantID INT IDENTITY(1, 1) NOT NULL,
    ProductID INT NOT NULL,
    VariantSKU VARCHAR(50) NOT NULL,
    Color NVARCHAR(50) NULL,
    Size NVARCHAR(20) NULL,
    Material NVARCHAR(50) NULL,
    PriceDelta DECIMAL(8, 2) NOT NULL CONSTRAINT DF_Variants_PriceDelta DEFAULT 0.00,
    Barcode VARCHAR(100) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Variants_IsActive DEFAULT 1,
    CONSTRAINT PK_ProductVariants PRIMARY KEY CLUSTERED (VariantID),
    CONSTRAINT UQ_ProductVariants_SKU UNIQUE (VariantSKU),
    CONSTRAINT FK_ProductVariants_Product FOREIGN KEY (ProductID) REFERENCES inventory.Products(ProductID) ON DELETE CASCADE
);
GO

-- Table 13: inventory.ProductInventory (Composite PK)
CREATE TABLE inventory.ProductInventory (
    ProductID INT NOT NULL,
    WarehouseID INT NOT NULL,
    QuantityOnHand INT NOT NULL CONSTRAINT DF_Inventory_OnHand DEFAULT 0,
    QuantityReserved INT NOT NULL CONSTRAINT DF_Inventory_Reserved DEFAULT 0,
    ReorderPoint INT NOT NULL CONSTRAINT DF_Inventory_Reorder DEFAULT 10,
    SafetyStock INT NOT NULL CONSTRAINT DF_Inventory_Safety DEFAULT 5,
    LastRestockedAt DATETIME2(7) NULL,
    CONSTRAINT PK_ProductInventory PRIMARY KEY CLUSTERED (ProductID, WarehouseID),
    CONSTRAINT FK_ProductInventory_Product FOREIGN KEY (ProductID) REFERENCES inventory.Products(ProductID),
    CONSTRAINT FK_ProductInventory_Warehouse FOREIGN KEY (WarehouseID) REFERENCES inventory.Warehouses(WarehouseID),
    CONSTRAINT CK_ProductInventory_OnHand CHECK (QuantityOnHand >= 0),
    CONSTRAINT CK_ProductInventory_Reserved CHECK (QuantityReserved >= 0)
);
GO

-- Table 14: inventory.InventoryTransactions
CREATE TABLE inventory.InventoryTransactions (
    TransactionID BIGINT IDENTITY(1, 1) NOT NULL,
    ProductID INT NOT NULL,
    WarehouseID INT NOT NULL,
    TransactionType VARCHAR(30) NOT NULL,
    QuantityDelta INT NOT NULL,
    ReferenceDocument VARCHAR(100) NULL,
    Notes NVARCHAR(500) NULL,
    TransactionDate DATETIME2(7) NOT NULL CONSTRAINT DF_InvTx_Date DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_InventoryTransactions PRIMARY KEY CLUSTERED (TransactionID),
    CONSTRAINT FK_InvTx_Product FOREIGN KEY (ProductID) REFERENCES inventory.Products(ProductID),
    CONSTRAINT FK_InvTx_Warehouse FOREIGN KEY (WarehouseID) REFERENCES inventory.Warehouses(WarehouseID),
    CONSTRAINT CK_InvTx_Type CHECK (TransactionType IN ('PURCHASE_RECEIPT', 'SALE_SHIPMENT', 'STOCK_TRANSFER', 'ADJUSTMENT_LOSS', 'ADJUSTMENT_FOUND'))
);
GO

-- ----------------------------------------------------------------------------
-- SCHEMA: sales
-- ----------------------------------------------------------------------------

-- Table 15: sales.PriceLists
CREATE TABLE sales.PriceLists (
    PriceListID INT IDENTITY(1, 1) NOT NULL,
    PriceListName NVARCHAR(100) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL CONSTRAINT DF_PriceLists_Curr DEFAULT 'USD',
    ValidFrom DATE NOT NULL,
    ValidTo DATE NOT NULL,
    IsDefault BIT NOT NULL CONSTRAINT DF_PriceLists_IsDefault DEFAULT 0,
    CONSTRAINT PK_PriceLists PRIMARY KEY CLUSTERED (PriceListID),
    CONSTRAINT CK_PriceLists_Dates CHECK (ValidTo >= ValidFrom)
);
GO

-- Table 16: sales.Promotions
CREATE TABLE sales.Promotions (
    PromotionID INT IDENTITY(1, 1) NOT NULL,
    PromoCode VARCHAR(50) NOT NULL,
    PromoName NVARCHAR(100) NOT NULL,
    DiscountPercent DECIMAL(5, 2) NOT NULL,
    MinOrderAmount DECIMAL(10, 2) NOT NULL CONSTRAINT DF_Promotions_Min DEFAULT 0.00,
    StartDate DATETIME2(7) NOT NULL,
    EndDate DATETIME2(7) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Promotions_IsActive DEFAULT 1,
    CONSTRAINT PK_Promotions PRIMARY KEY CLUSTERED (PromotionID),
    CONSTRAINT UQ_Promotions_Code UNIQUE (PromoCode),
    CONSTRAINT CK_Promotions_Discount CHECK (DiscountPercent >= 0 AND DiscountPercent <= 100),
    CONSTRAINT CK_Promotions_Dates CHECK (EndDate >= StartDate)
);
GO

-- Table 17: sales.Orders
CREATE TABLE sales.Orders (
    OrderID BIGINT IDENTITY(500001, 1) NOT NULL,
    OrderNumber VARCHAR(50) NOT NULL,
    CustomerID INT NOT NULL,
    SalesRepEmployeeID INT NULL,
    ShippingAddressID INT NULL,
    OrderStatus TINYINT NOT NULL CONSTRAINT DF_Orders_Status DEFAULT 1,
    OrderDate DATETIME2(7) NOT NULL CONSTRAINT DF_Orders_OrderDate DEFAULT SYSUTCDATETIME(),
    RequiredDate DATETIME2(7) NULL,
    ShippedDate DATETIME2(7) NULL,
    SubTotal DECIMAL(14, 2) NOT NULL CONSTRAINT DF_Orders_SubTotal DEFAULT 0.00,
    TaxAmount DECIMAL(14, 2) NOT NULL CONSTRAINT DF_Orders_Tax DEFAULT 0.00,
    ShippingCost DECIMAL(10, 2) NOT NULL CONSTRAINT DF_Orders_Shipping DEFAULT 0.00,
    DiscountTotal DECIMAL(14, 2) NOT NULL CONSTRAINT DF_Orders_Discount DEFAULT 0.00,
    TotalAmount DECIMAL(14, 2) NOT NULL CONSTRAINT DF_Orders_Total DEFAULT 0.00,
    PaymentStatus VARCHAR(20) NOT NULL CONSTRAINT DF_Orders_PaymentStatus DEFAULT 'PENDING',
    SpecialInstructions NVARCHAR(1000) NULL,
    CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED (OrderID),
    CONSTRAINT UQ_Orders_OrderNumber UNIQUE (OrderNumber),
    CONSTRAINT FK_Orders_Customer FOREIGN KEY (CustomerID) REFERENCES core.Customers(CustomerID),
    CONSTRAINT FK_Orders_SalesRep FOREIGN KEY (SalesRepEmployeeID) REFERENCES core.Employees(EmployeeID),
    CONSTRAINT FK_Orders_ShippingAddress FOREIGN KEY (ShippingAddressID) REFERENCES core.CustomerAddresses(AddressID),
    CONSTRAINT CK_Orders_Status CHECK (OrderStatus BETWEEN 1 AND 6),
    CONSTRAINT CK_Orders_Total CHECK (TotalAmount >= 0)
);
GO

-- Table 18: sales.OrderItems
CREATE TABLE sales.OrderItems (
    OrderItemID BIGINT IDENTITY(1, 1) NOT NULL,
    OrderID BIGINT NOT NULL,
    LineNumber SMALLINT NOT NULL,
    ProductID INT NOT NULL,
    VariantID INT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(12, 2) NOT NULL,
    DiscountAmount DECIMAL(10, 2) NOT NULL CONSTRAINT DF_OrderItems_Discount DEFAULT 0.00,
    TotalLinePrice DECIMAL(14, 2) NOT NULL,
    Notes NVARCHAR(255) NULL,
    CONSTRAINT PK_OrderItems PRIMARY KEY CLUSTERED (OrderItemID),
    CONSTRAINT FK_OrderItems_Order FOREIGN KEY (OrderID) REFERENCES sales.Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Product FOREIGN KEY (ProductID) REFERENCES inventory.Products(ProductID),
    CONSTRAINT FK_OrderItems_Variant FOREIGN KEY (VariantID) REFERENCES inventory.ProductVariants(VariantID),
    CONSTRAINT CK_OrderItems_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_OrderItems_Price CHECK (UnitPrice >= 0)
);
GO

-- Table 19: sales.OrderDiscounts (Composite PK)
CREATE TABLE sales.OrderDiscounts (
    OrderID BIGINT NOT NULL,
    PromotionID INT NOT NULL,
    DiscountApplied DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_OrderDiscounts PRIMARY KEY CLUSTERED (OrderID, PromotionID),
    CONSTRAINT FK_OrderDiscounts_Order FOREIGN KEY (OrderID) REFERENCES sales.Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDiscounts_Promotion FOREIGN KEY (PromotionID) REFERENCES sales.Promotions(PromotionID),
    CONSTRAINT CK_OrderDiscounts_Discount CHECK (DiscountApplied >= 0)
);
GO

-- Table 20: sales.OrderFulfillments
CREATE TABLE sales.OrderFulfillments (
    FulfillmentID BIGINT IDENTITY(1, 1) NOT NULL,
    OrderID BIGINT NOT NULL,
    WarehouseID INT NOT NULL,
    Carrier VARCHAR(50) NOT NULL,
    TrackingNumber VARCHAR(100) NULL,
    Status VARCHAR(30) NOT NULL CONSTRAINT DF_OrderFulfillments_Status DEFAULT 'PROCESSING',
    ShippedAt DATETIME2(7) NULL,
    DeliveredAt DATETIME2(7) NULL,
    CONSTRAINT PK_OrderFulfillments PRIMARY KEY CLUSTERED (FulfillmentID),
    CONSTRAINT FK_OrderFulfillments_Order FOREIGN KEY (OrderID) REFERENCES sales.Orders(OrderID),
    CONSTRAINT FK_OrderFulfillments_Warehouse FOREIGN KEY (WarehouseID) REFERENCES inventory.Warehouses(WarehouseID),
    CONSTRAINT CK_OrderFulfillments_Status CHECK (Status IN ('PROCESSING', 'PICKED', 'PACKED', 'SHIPPED', 'DELIVERED', 'RETURNED'))
);
GO

-- Table 21: sales.Invoices (1:1 with Orders)
CREATE TABLE sales.Invoices (
    InvoiceID BIGINT IDENTITY(1, 1) NOT NULL,
    InvoiceNumber VARCHAR(50) NOT NULL,
    OrderID BIGINT NOT NULL,
    InvoiceDate DATE NOT NULL CONSTRAINT DF_Invoices_Date DEFAULT CAST(GETDATE() AS DATE),
    DueDate DATE NOT NULL,
    SubTotal DECIMAL(14, 2) NOT NULL,
    TaxAmount DECIMAL(14, 2) NOT NULL,
    TotalAmount DECIMAL(14, 2) NOT NULL,
    AmountPaid DECIMAL(14, 2) NOT NULL CONSTRAINT DF_Invoices_Paid DEFAULT 0.00,
    BalanceDue DECIMAL(14, 2) NOT NULL,
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Invoices_Status DEFAULT 'ISSUED',
    CONSTRAINT PK_Invoices PRIMARY KEY CLUSTERED (InvoiceID),
    CONSTRAINT UQ_Invoices_InvoiceNumber UNIQUE (InvoiceNumber),
    CONSTRAINT UQ_Invoices_OrderID UNIQUE (OrderID),
    CONSTRAINT FK_Invoices_Order FOREIGN KEY (OrderID) REFERENCES sales.Orders(OrderID),
    CONSTRAINT CK_Invoices_Status CHECK (Status IN ('DRAFT', 'ISSUED', 'PARTIALLY_PAID', 'PAID', 'CANCELLED', 'OVERDUE'))
);
GO

-- Table 22: sales.Payments
CREATE TABLE sales.Payments (
    PaymentID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Payments_ID DEFAULT NEWID(),
    InvoiceID BIGINT NOT NULL,
    CustomerID INT NOT NULL,
    PaymentMethod VARCHAR(30) NOT NULL,
    Amount DECIMAL(14, 2) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL CONSTRAINT DF_Payments_Currency DEFAULT 'USD',
    TransactionReference VARCHAR(100) NOT NULL,
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Payments_Status DEFAULT 'COMPLETED',
    ProcessedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Payments_ProcessedAt DEFAULT SYSUTCDATETIME(),
    GatewayResponse NVARCHAR(MAX) NULL,
    CONSTRAINT PK_Payments PRIMARY KEY CLUSTERED (PaymentID),
    CONSTRAINT UQ_Payments_Ref UNIQUE (TransactionReference),
    CONSTRAINT FK_Payments_Invoice FOREIGN KEY (InvoiceID) REFERENCES sales.Invoices(InvoiceID),
    CONSTRAINT FK_Payments_Customer FOREIGN KEY (CustomerID) REFERENCES core.Customers(CustomerID),
    CONSTRAINT CK_Payments_Method CHECK (PaymentMethod IN ('CREDIT_CARD', 'BANK_TRANSFER', 'PAYPAL', 'CHECK', 'CRYPTO')),
    CONSTRAINT CK_Payments_Amount CHECK (Amount > 0)
);
GO

-- Table 23: sales.OrderNotes
CREATE TABLE sales.OrderNotes (
    NoteID BIGINT IDENTITY(1, 1) NOT NULL,
    OrderID BIGINT NOT NULL,
    AuthorEmployeeID INT NOT NULL,
    NoteText NVARCHAR(MAX) NOT NULL,
    IsInternalOnly BIT NOT NULL CONSTRAINT DF_OrderNotes_Internal DEFAULT 1,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_OrderNotes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_OrderNotes PRIMARY KEY CLUSTERED (NoteID),
    CONSTRAINT FK_OrderNotes_Order FOREIGN KEY (OrderID) REFERENCES sales.Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderNotes_Author FOREIGN KEY (AuthorEmployeeID) REFERENCES core.Employees(EmployeeID)
);
GO

-- Table 24: sales.CustomerReviews
CREATE TABLE sales.CustomerReviews (
    ReviewID BIGINT IDENTITY(1, 1) NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Rating TINYINT NOT NULL,
    ReviewTitle NVARCHAR(150) NOT NULL,
    ReviewBody NVARCHAR(MAX) NULL,
    IsVerifiedPurchase BIT NOT NULL CONSTRAINT DF_Reviews_Verified DEFAULT 1,
    IsApproved BIT NOT NULL CONSTRAINT DF_Reviews_Approved DEFAULT 0,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Reviews_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CustomerReviews PRIMARY KEY CLUSTERED (ReviewID),
    CONSTRAINT FK_CustomerReviews_Customer FOREIGN KEY (CustomerID) REFERENCES core.Customers(CustomerID),
    CONSTRAINT FK_CustomerReviews_Product FOREIGN KEY (ProductID) REFERENCES inventory.Products(ProductID),
    CONSTRAINT CK_CustomerReviews_Rating CHECK (Rating BETWEEN 1 AND 5)
);
GO

-- ----------------------------------------------------------------------------
-- SCHEMA: audit
-- ----------------------------------------------------------------------------

-- Table 25: audit.AuditLogs
CREATE TABLE audit.AuditLogs (
    LogID BIGINT IDENTITY(1, 1) NOT NULL,
    SchemaName VARCHAR(50) NOT NULL,
    TableName VARCHAR(100) NOT NULL,
    RecordKey VARCHAR(100) NOT NULL,
    ActionType VARCHAR(10) NOT NULL,
    ChangedBy VARCHAR(100) NOT NULL CONSTRAINT DF_AuditLogs_User DEFAULT SYSTEM_USER,
    ChangedAt DATETIME2(7) NOT NULL CONSTRAINT DF_AuditLogs_Date DEFAULT SYSUTCDATETIME(),
    OldValuesJson NVARCHAR(MAX) NULL,
    NewValuesJson NVARCHAR(MAX) NULL,
    CONSTRAINT PK_AuditLogs PRIMARY KEY CLUSTERED (LogID),
    CONSTRAINT CK_AuditLogs_Action CHECK (ActionType IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO

-- Table 26: audit.SystemConfigurations
CREATE TABLE audit.SystemConfigurations (
    ConfigKey VARCHAR(100) NOT NULL,
    ConfigValue NVARCHAR(MAX) NOT NULL,
    DataType VARCHAR(20) NOT NULL CONSTRAINT DF_SysConfig_Type DEFAULT 'STRING',
    Description NVARCHAR(255) NULL,
    IsEncrypted BIT NOT NULL CONSTRAINT DF_SysConfig_Encrypted DEFAULT 0,
    UpdatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_SysConfig_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_SystemConfigurations PRIMARY KEY CLUSTERED (ConfigKey)
);
GO

-- ----------------------------------------------------------------------------
-- INDEXES (Clustered, Non-Clustered, Composite, Filtered)
-- ----------------------------------------------------------------------------

CREATE NONCLUSTERED INDEX IX_CustomerAddresses_CustomerID ON core.CustomerAddresses (CustomerID);
CREATE NONCLUSTERED INDEX IX_Employees_DepartmentID ON core.Employees (DepartmentID);
CREATE NONCLUSTERED INDEX IX_Employees_ManagerID ON core.Employees (ManagerEmployeeID);

CREATE NONCLUSTERED INDEX IX_Products_Brand_Category ON inventory.Products (BrandID, CategoryID);
CREATE NONCLUSTERED INDEX IX_Products_Supplier ON inventory.Products (PrimarySupplierID);
CREATE NONCLUSTERED INDEX IX_ProductVariants_ProductID ON inventory.ProductVariants (ProductID);
CREATE NONCLUSTERED INDEX IX_ProductInventory_WarehouseID ON inventory.ProductInventory (WarehouseID);
CREATE NONCLUSTERED INDEX IX_InventoryTransactions_Product_Warehouse ON inventory.InventoryTransactions (ProductID, WarehouseID);

CREATE NONCLUSTERED INDEX IX_Orders_CustomerID ON sales.Orders (CustomerID);
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON sales.Orders (OrderDate);
-- Filtered Index: active/pending orders only
CREATE NONCLUSTERED INDEX IX_Orders_ActiveOrders ON sales.Orders (CustomerID, OrderStatus) WHERE OrderStatus IN (1, 2, 3);

CREATE NONCLUSTERED INDEX IX_OrderItems_OrderID ON sales.OrderItems (OrderID);
CREATE NONCLUSTERED INDEX IX_OrderItems_ProductID ON sales.OrderItems (ProductID);
CREATE NONCLUSTERED INDEX IX_Invoices_Status ON sales.Invoices (Status);
CREATE NONCLUSTERED INDEX IX_Payments_InvoiceID ON sales.Payments (InvoiceID);
CREATE NONCLUSTERED INDEX IX_CustomerReviews_Product_Rating ON sales.CustomerReviews (ProductID, Rating);
CREATE NONCLUSTERED INDEX IX_AuditLogs_Table_Date ON audit.AuditLogs (SchemaName, TableName, ChangedAt);
GO
